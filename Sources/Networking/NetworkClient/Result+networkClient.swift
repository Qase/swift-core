import Combine
import ErrorReporting
import Foundation
import ModelConvertible
import RequestBuilder

extension Result where Success == URLRequest, Failure == URLRequestError {
  var networkPublisher: AnyPublisher<URLRequest, NetworkError> {
    self.publisher
      .mapErrorReporting(to: .urlRequestBuilderError)
      .eraseToAnyPublisher()
  }

  func execute<
    DataModel,
    FetcherError: ErrorReporting,
    ResultError: ErrorReporting & NetworkErrorCapable
  >(
    fetcher: @escaping (URLRequest) -> AnyPublisher<DataModel, FetcherError>,
    mapNetworkError: ((FetcherError) -> ResultError)? = nil
  ) -> AnyPublisher<DataModel, ResultError> {
    networkPublisher
      .mapErrorReporting(to: ResultError.networkError)
      .flatMap { urlRequest in
        fetcher(urlRequest)
          .catch { error -> AnyPublisher<DataModel, ResultError> in
            if let mapNetworkError = mapNetworkError {
              return Fail<DataModel, ResultError>(error: mapNetworkError(error))
                .eraseToAnyPublisher()
            }

            return Fail(error: error)
              .mapErrorReporting(to: ResultError.networkError)
              .eraseToAnyPublisher()
          }
      }
      .eraseToAnyPublisher()
  }
}

// MARK: - Syntax sugar methods working with NetworkError

extension Result where Success == URLRequest, Failure == URLRequestError {
  func execute(
    using networkClient: NetworkClientType
  ) -> AnyPublisher<(headers: [HTTPHeader], body: Data), NetworkError> {
    self.networkPublisher
      .flatMap(networkClient.request)
      .eraseToAnyPublisher()
  }

  func execute<T: Decodable>(
    using networkClient: NetworkClientType,
    jsonDecoder: JSONDecoder = JSONDecoder()
  ) -> AnyPublisher<(headers: [HTTPHeader], object: T), NetworkError> {
    self.networkPublisher
      .flatMap { networkClient.request($0, jsonDecoder: jsonDecoder) }
      .eraseToAnyPublisher()
  }

  func execute<T: Decodable>(
    using networkClient: NetworkClientType,
    jsonDecoder: JSONDecoder = JSONDecoder()
  ) -> AnyPublisher<T, NetworkError> {
    self.networkPublisher
      .flatMap { networkClient.request($0, jsonDecoder: jsonDecoder) }
      .eraseToAnyPublisher()
  }
}

// MARK: - Syntax sugar methods working with custom Error

public extension Result where Success == URLRequest, Failure == URLRequestError {
  func execute<ResultError: ErrorReporting & NetworkErrorCapable>(
    using networkClient: NetworkClientType,
    mapNetworkError: ((NetworkError) -> ResultError)? = nil
  ) -> AnyPublisher<(headers: [HTTPHeader], body: Data), ResultError> {
    execute(
      fetcher: networkClient.request,
      mapNetworkError: mapNetworkError
    )
  }

  func execute<
    T: Decodable,
    ResultError: ErrorReporting & NetworkErrorCapable
  >(
    using networkClient: NetworkClientType,
    jsonDecoder: JSONDecoder = JSONDecoder(),
    mapNetworkError: ((NetworkError) -> ResultError)? = nil
  ) -> AnyPublisher<(headers: [HTTPHeader], object: T), ResultError> {
    execute(
      fetcher: { networkClient.request($0, jsonDecoder: jsonDecoder) },
      mapNetworkError: mapNetworkError
    )
  }

  func execute<
    T: Decodable,
    ResultError: ErrorReporting & NetworkErrorCapable
  >(
    using networkClient: NetworkClientType,
    jsonDecoder: JSONDecoder = JSONDecoder(),
    mapNetworkError: ((NetworkError) -> ResultError)? = nil
  ) -> AnyPublisher<T, ResultError> {
    execute(
      fetcher: { networkClient.request($0, jsonDecoder: jsonDecoder) },
      mapNetworkError: mapNetworkError
    )
  }
}

// MARK: - Async await methods

public extension Result where Success == URLRequest, Failure == URLRequestError {
  func execute(
    using networkClient: NetworkClientType
  ) async throws -> (headers: [HTTPHeader], body: Data) {
    try await execute(using: networkClient)
      .async()
  }

  func execute<T: Decodable>(
    using networkClient: NetworkClientType,
    jsonDecoder: JSONDecoder = JSONDecoder()
  ) async throws -> (headers: [HTTPHeader], object: T) {
    try await execute(using: networkClient, jsonDecoder: jsonDecoder)
      .async()
  }

  func execute<T: Decodable>(
    using networkClient: NetworkClientType,
    jsonDecoder: JSONDecoder = JSONDecoder()
  ) async throws -> T {
    try await execute(using: networkClient, jsonDecoder: jsonDecoder)
      .async()
  }
}
