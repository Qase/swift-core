import Combine
import ErrorReporting
import Foundation
import RequestBuilder

// MARK: - Syntax sugar methods working with NetworkError

public extension Request {
  func execute(
    using networkClient: NetworkClientType
  ) -> AnyPublisher<(headers: [HTTPHeader], body: Data), NetworkError> {
    self.urlRequest
      .execute(using: networkClient)
  }

  func execute<T: Decodable>(
    using networkClient: NetworkClientType,
    jsonDecoder: JSONDecoder = JSONDecoder()
  ) -> AnyPublisher<(headers: [HTTPHeader], object: T), NetworkError> {
    self.urlRequest
      .execute(using: networkClient, jsonDecoder: jsonDecoder)
  }

  func execute<T: Decodable>(
    using networkClient: NetworkClientType,
    jsonDecoder: JSONDecoder = JSONDecoder()
  ) -> AnyPublisher<T, NetworkError> {
    self.urlRequest
      .execute(using: networkClient, jsonDecoder: jsonDecoder)
  }
}

// MARK: - Syntax sugar methods working with custom Error

public extension Request {
  func execute<ResultError: ErrorReporting & URLRequestBuilderErrorCapable & NetworkErrorCapable>(
    using networkClient: NetworkClientType,
    mapNetworkError: ((NetworkError) -> ResultError)? = nil
  ) -> AnyPublisher<(headers: [HTTPHeader], body: Data), ResultError> {
    self.urlRequest
      .execute(using: networkClient, mapNetworkError: mapNetworkError)
  }

  func execute<
    T: Decodable,
    ResultError: ErrorReporting & URLRequestBuilderErrorCapable & NetworkErrorCapable
  >(
    using networkClient: NetworkClientType,
    jsonDecoder: JSONDecoder = JSONDecoder(),
    mapNetworkError: ((NetworkError) -> ResultError)? = nil
  ) -> AnyPublisher<(headers: [HTTPHeader], object: T), ResultError> {
    self.urlRequest
      .execute(using: networkClient, jsonDecoder: jsonDecoder, mapNetworkError: mapNetworkError)
  }

  func execute<
    T: Decodable,
    ResultError: ErrorReporting & URLRequestBuilderErrorCapable & NetworkErrorCapable
  >(
    using networkClient: NetworkClientType,
    jsonDecoder: JSONDecoder = JSONDecoder(),
    mapNetworkError: ((NetworkError) -> ResultError)? = nil
  ) -> AnyPublisher<T, ResultError> {
    self.urlRequest
      .execute(using: networkClient, jsonDecoder: jsonDecoder, mapNetworkError: mapNetworkError)
  }
}

// MARK: - Async await methods

public extension Request {
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
