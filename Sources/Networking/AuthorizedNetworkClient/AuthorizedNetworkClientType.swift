import Combine
import Foundation

public protocol AuthorizedNetworkClientType: NetworkClientType {
  var jsonDecoder: JSONDecoder { get }

  func authorizedRequest(
    _ urlRequest: URLRequest
  ) -> AnyPublisher<(headers: [HTTPHeader], body: Data), AuthorizedNetworkError>
}

// MARK: - Synthetized functions

public extension AuthorizedNetworkClientType {
  func authorizedRequest<T: Decodable>(
    _ urlRequest: URLRequest,
    jsonDecoder: JSONDecoder? = nil
  ) -> AnyPublisher<(headers: [HTTPHeader], object: T), AuthorizedNetworkError> {
    authorizedRequest(urlRequest)
      .decode(
        type: T.self,
        decoder: jsonDecoder ?? self.jsonDecoder,
        mapError: { decodingError in
          let networkError = NetworkError.jsonDecodingError(decodingError)
          var authorizedNetworkError = AuthorizedNetworkError.networkError
          authorizedNetworkError.setProperties(from: networkError)
          return authorizedNetworkError
        }
      )
  }

  func authorizedRequest<T: Decodable>(
    _ urlRequest: URLRequest,
    jsonDecoder: JSONDecoder? = nil,
    ofResponseType: T.Type
  ) -> AnyPublisher<(headers: [HTTPHeader], object: T), AuthorizedNetworkError> {
    authorizedRequest(urlRequest)
  }

  func authorizedRequest<T: Decodable>(
    _ urlRequest: URLRequest,
    jsonDecoder: JSONDecoder? = nil
  ) -> AnyPublisher<T, AuthorizedNetworkError> {
    authorizedRequest(urlRequest, jsonDecoder: jsonDecoder)
      .map(\.object)
      .eraseToAnyPublisher()
  }

  func authorizedRequest<T: Decodable>(
    _ urlRequest: URLRequest,
    jsonDecoder: JSONDecoder? = nil,
    ofResponseType: T.Type
  ) -> AnyPublisher<T, AuthorizedNetworkError> {
    authorizedRequest(urlRequest, jsonDecoder: jsonDecoder)
  }
}
