import Combine
import ErrorReporting
import Foundation
import RequestBuilder

// MARK: - Syntax sugar methods working with NetworkError

public extension Request {
  func executeAuthorized(
    using authorizedNetworkClient: AuthorizedNetworkClientType
  ) -> AnyPublisher<(headers: [HTTPHeader], body: Data), AuthorizedNetworkError> {
    self.urlRequest
      .executeAuthorized(using: authorizedNetworkClient)
  }

  func executeAuthorized<T: Decodable>(
    using authorizedNetworkClient: AuthorizedNetworkClientType,
    jsonDecoder: JSONDecoder = JSONDecoder()
  ) -> AnyPublisher<(headers: [HTTPHeader], object: T), AuthorizedNetworkError> {
    self.urlRequest
      .executeAuthorized(using: authorizedNetworkClient, jsonDecoder: jsonDecoder)
  }

  func executeAuthorized<T: Decodable>(
    using authorizedNetworkClient: AuthorizedNetworkClientType,
    jsonDecoder: JSONDecoder = JSONDecoder()
  ) -> AnyPublisher<T, AuthorizedNetworkError> {
    self.urlRequest
      .executeAuthorized(using: authorizedNetworkClient, jsonDecoder: jsonDecoder)
  }
}

// MARK: - Syntax sugar methods working with custom Error

public extension Request {
  func executeAuthorized<ResultError: ErrorReporting & NetworkErrorCapable>(
    using authorizedNetworkClient: AuthorizedNetworkClientType,
    mapAuthorizedNetworkError: ((AuthorizedNetworkError) -> ResultError)? = nil
  ) -> AnyPublisher<(headers: [HTTPHeader], body: Data), ResultError> {
    self.urlRequest
      .executeAuthorized(using: authorizedNetworkClient, mapAuthorizedNetworkError: mapAuthorizedNetworkError)
  }

  func executeAuthorized<
    T: Decodable,
    ResultError: ErrorReporting & NetworkErrorCapable
  >(
    using authorizedNetworkClient: AuthorizedNetworkClientType,
    jsonDecoder: JSONDecoder = JSONDecoder(),
    mapAuthorizedNetworkError: ((AuthorizedNetworkError) -> ResultError)? = nil
  ) -> AnyPublisher<(headers: [HTTPHeader], object: T), ResultError> {
    self.urlRequest
      .executeAuthorized(using: authorizedNetworkClient, jsonDecoder: jsonDecoder, mapAuthorizedNetworkError: mapAuthorizedNetworkError)
  }

  func executeAuthorized<
    T: Decodable,
    ResultError: ErrorReporting & NetworkErrorCapable
  >(
    using authorizedNetworkClient: AuthorizedNetworkClientType,
    jsonDecoder: JSONDecoder = JSONDecoder(),
    mapAuthorizedNetworkError: ((AuthorizedNetworkError) -> ResultError)? = nil
  ) -> AnyPublisher<T, ResultError> {
    self.urlRequest
      .executeAuthorized(using: authorizedNetworkClient, jsonDecoder: jsonDecoder, mapAuthorizedNetworkError: mapAuthorizedNetworkError)
  }
}

// MARK: - Async await methods

public extension Request {
  func execute(
    using authorizedNetworkClient: AuthorizedNetworkClientType
  ) async throws -> (headers: [HTTPHeader], body: Data) {
    try await executeAuthorized(using: authorizedNetworkClient)
      .async()
  }

  func execute<T: Decodable>(
    using authorizedNetworkClient: AuthorizedNetworkClientType,
    jsonDecoder: JSONDecoder = JSONDecoder()
  ) async throws -> (headers: [HTTPHeader], object: T) {
    try await executeAuthorized(using: authorizedNetworkClient, jsonDecoder: jsonDecoder)
      .async()
  }

  func execute<T: Decodable>(
    using authorizedNetworkClient: AuthorizedNetworkClientType,
    jsonDecoder: JSONDecoder = JSONDecoder()
  ) async throws -> T {
    try await executeAuthorized(using: authorizedNetworkClient, jsonDecoder: jsonDecoder)
      .async()
  }
}
