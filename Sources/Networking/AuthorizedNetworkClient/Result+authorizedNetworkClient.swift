import Combine
import ErrorReporting
import Foundation
import RequestBuilder

private extension Result where Success == URLRequest, Failure == URLRequestError {
  var authorizedNetworkPublisher: AnyPublisher<URLRequest, AuthorizedNetworkError> {
    networkPublisher
      .mapErrorReporting(to: .networkError)
      .eraseToAnyPublisher()
  }
}

// MARK: - Syntax sugar methods working with NetworkError

public extension Result where Success == URLRequest, Failure == URLRequestError {
  func executeAuthorized(
    using authorizedNetworkClient: AuthorizedNetworkClientType
  ) -> AnyPublisher<(headers: [HTTPHeader], body: Data), AuthorizedNetworkError> {
    self.authorizedNetworkPublisher
      .flatMap(authorizedNetworkClient.authorizedRequest)
      .eraseToAnyPublisher()
  }

  func executeAuthorized<T: Decodable>(
    using authorizedNetworkClient: AuthorizedNetworkClientType,
    jsonDecoder: JSONDecoder = JSONDecoder()
  ) -> AnyPublisher<(headers: [HTTPHeader], object: T), AuthorizedNetworkError> {
    self.authorizedNetworkPublisher
      .flatMap { authorizedNetworkClient.authorizedRequest($0, jsonDecoder: jsonDecoder) }
      .eraseToAnyPublisher()
  }

  func executeAuthorized<T: Decodable>(
    using authorizedNetworkClient: AuthorizedNetworkClientType,
    jsonDecoder: JSONDecoder = JSONDecoder()
  ) -> AnyPublisher<T, AuthorizedNetworkError> {
    self.authorizedNetworkPublisher
      .flatMap { authorizedNetworkClient.authorizedRequest($0, jsonDecoder: jsonDecoder) }
      .eraseToAnyPublisher()
  }
}

// MARK: - Syntax sugar methods working with custom Error

public extension Result where Success == URLRequest, Failure == URLRequestError {
  func executeAuthorized<ResultError: ErrorReporting & NetworkErrorCapable>(
    using authorizedNetworkClient: AuthorizedNetworkClientType,
    mapAuthorizedNetworkError: ((AuthorizedNetworkError) -> ResultError)? = nil
  ) -> AnyPublisher<(headers: [HTTPHeader], body: Data), ResultError> {
    execute(
      fetcher: authorizedNetworkClient.authorizedRequest,
      mapNetworkError: mapAuthorizedNetworkError
    )
  }

  func executeAuthorized<
    T: Decodable,
    ResultError: ErrorReporting & NetworkErrorCapable
  >(
    using authorizedNetworkClient: AuthorizedNetworkClientType,
    jsonDecoder: JSONDecoder = JSONDecoder(),
    mapAuthorizedNetworkError: ((AuthorizedNetworkError) -> ResultError)? = nil
  ) -> AnyPublisher<(headers: [HTTPHeader], object: T), ResultError> {
    execute(
      fetcher: { authorizedNetworkClient.authorizedRequest($0, jsonDecoder: jsonDecoder) },
      mapNetworkError: mapAuthorizedNetworkError
    )
  }

  func executeAuthorized<
    T: Decodable,
    ResultError: ErrorReporting & NetworkErrorCapable
  >(
    using authorizedNetworkClient: AuthorizedNetworkClientType,
    jsonDecoder: JSONDecoder = JSONDecoder(),
    mapAuthorizedNetworkError: ((AuthorizedNetworkError) -> ResultError)? = nil
  ) -> AnyPublisher<T, ResultError> {
    execute(
      fetcher: { authorizedNetworkClient.authorizedRequest($0, jsonDecoder: jsonDecoder) },
      mapNetworkError: mapAuthorizedNetworkError
    )
  }
}

// MARK: - Async await methods

public extension Result where Success == URLRequest, Failure == URLRequestError {
  func executeAuthorized(
    using authorizedNetworkClient: AuthorizedNetworkClientType
  ) async throws -> (headers: [HTTPHeader], body: Data) {
    try await executeAuthorized(using: authorizedNetworkClient)
      .async()
  }

  func executeAuthorized<T: Decodable>(
    using authorizedNetworkClient: AuthorizedNetworkClientType,
    jsonDecoder: JSONDecoder = JSONDecoder()
  ) async throws -> (headers: [HTTPHeader], object: T) {
    try await executeAuthorized(using: authorizedNetworkClient, jsonDecoder: jsonDecoder)
      .async()
  }

  func executeAuthorized<T: Decodable>(
    using authorizedNetworkClient: AuthorizedNetworkClientType,
    jsonDecoder: JSONDecoder = JSONDecoder()
  ) async throws -> T {
    try await execute(using: authorizedNetworkClient, jsonDecoder: jsonDecoder)
      .async()
  }
}
