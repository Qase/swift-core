import Combine
import Foundation
import RequestBuilder

extension Request {
  var networkPublisher: AnyPublisher<URLRequest, NetworkError> {
    Result.Publisher(self.urlRequest)
      .mapErrorReporting(to: .urlRequestError)
      .eraseToAnyPublisher()
  }
}

public extension Request {
  func execute(
    using networkClient: NetworkClientType
  ) -> AnyPublisher<(headers: [HTTPHeader], body: Data), NetworkError> {
    networkPublisher
      .flatMap(networkClient.request)
      .eraseToAnyPublisher()
  }
  
  func execute<T: Decodable>(
    using networkClient: NetworkClientType,
    jsonDecoder: JSONDecoder = JSONDecoder()
  ) -> AnyPublisher<(headers: [HTTPHeader], object: T), NetworkError> {
    networkPublisher
      .flatMap { networkClient.request($0, jsonDecoder: jsonDecoder) }
      .eraseToAnyPublisher()
  }
  
  func execute<T: Decodable>(
    using networkClient: NetworkClientType,
    jsonDecoder: JSONDecoder = JSONDecoder()
  ) -> AnyPublisher<T, NetworkError> {
    networkPublisher
      .flatMap { networkClient.request($0, jsonDecoder: jsonDecoder) }
      .eraseToAnyPublisher()
  }
}

// MARK: - Async await functions

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
