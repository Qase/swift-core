import Combine
import CombineExtensions
import Foundation
import Network
import NetworkMonitoring

public struct NetworkClient: NetworkClientType {
  public typealias Response = (headers: [HTTPHeader], body: Data)

  private let urlSessionConfiguration: URLSessionConfiguration
  private let urlRequester: URLRequester
  private let networkMonitorClient: NetworkMonitorClient
  private let logUUID: () -> UUID
  private let loggerClient: NetworkLoggerClient?
  private let transformRequest: (URLRequest) -> URLRequest

  public init(
    urlSessionConfiguration: URLSessionConfiguration,
    urlRequester: URLRequester,
    networkMonitorClient: NetworkMonitorClient,
    logUUID: @escaping () -> UUID = { .init() },
    loggerClient: NetworkLoggerClient? = nil,
    transformRequest: @escaping (URLRequest) -> URLRequest = { $0 }
  ) {
    self.urlSessionConfiguration = urlSessionConfiguration
    self.urlRequester = urlRequester
    self.networkMonitorClient = networkMonitorClient
    self.logUUID = logUUID
    self.loggerClient = loggerClient
    self.transformRequest = transformRequest
  }

  private var processedStatusCode: (Int) -> Result<Void, NetworkError> = { statusCode in
    switch statusCode {
    case 401:
      return .failure(.unauthorized)
    case 408:
      return .failure(.timeoutError)
    case 400, 402..<500:
      return .failure(.clientError(statusCode: statusCode))
    case 500..<600:
      return .failure(.serverError(statusCode: statusCode))
    default:
      return .success(())
    }
  }

  private func performRequest(_ urlRequest: URLRequest) -> AnyPublisher<Response, NetworkError> {
    let isNetworkAvailable = networkMonitorClient.isNetworkAvailable
      .prefix(1)
      .setFailureType(to: NetworkError.self)
      .flatMapResult { isNetworkAvailable -> Result<Void, NetworkError> in
        isNetworkAvailable ? .success(()) : .failure(.noConnection)
      }

    let requestUUID = logUUID()

    let request: AnyPublisher<Response, NetworkError> = Just<URLRequest>(urlRequest)
      .map(transformRequest)
      .setFailureType(to: URLError.self)
      .handleEvents(receiveOutput: { loggerClient?.logRequest(requestUUID, $0) })
      .flatMap(urlRequester.request(urlSessionConfiguration))
      .mapError { urlError -> NetworkError in
        guard case .timedOut = urlError.code else {
          return .urlError(urlError)
        }

        return .timeoutError
      }
      .flatMap { data, response -> AnyPublisher<Response, NetworkError> in
        guard let httpResponse = response as? HTTPURLResponse else {
          loggerClient?.logURLResponse(requestUUID, response, data)

          return Fail<Response, NetworkError>(error: .invalidResponse)
            .eraseToAnyPublisher()
        }

        loggerClient?.logHTTPURLResponse(requestUUID, httpResponse, data)

        let response = (headers: httpResponse.allHeaderFields.httpHeaders, body: data)

        return Result<Void, NetworkError>.Publisher(processedStatusCode(httpResponse.statusCode))
          .mapError {
            var networkError = $0
            networkError.requestID = response.headers[.requestID]

            return networkError
          }
          .map { response }
          .eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()

    return isNetworkAvailable
      .flatMap { _ in request }
      .eraseToAnyPublisher()
  }
}

// MARK: - NetworkClientType implementation

public extension NetworkClient {
  func request(_ urlRequest: URLRequest) -> AnyPublisher<Response, NetworkError> {
    performRequest(urlRequest)
  }
}
