import Combine
import Foundation
import RequestBuilder

public protocol NetworkClientType {
  func request(_ urlRequest: URLRequest) -> AnyPublisher<(headers: [HTTPHeader], body: Data), NetworkError>
}

// MARK: - Synthetized functions

public extension NetworkClientType {
  func request<T: Decodable>(
    _ urlRequest: URLRequest,
    jsonDecoder: JSONDecoder = JSONDecoder()
  ) -> AnyPublisher<(headers: [HTTPHeader], object: T), NetworkError> {
    request(urlRequest)
      .decode(type: T.self, decoder: jsonDecoder, mapError: NetworkError.jsonDecodingError)
  }

  func request<T: Decodable>(
    _ urlRequest: URLRequest,
    jsonDecoder: JSONDecoder = JSONDecoder(),
    ofResponseType: T.Type
  ) -> AnyPublisher<(headers: [HTTPHeader], object: T), NetworkError> {
    request(urlRequest, jsonDecoder: jsonDecoder)
  }

  func request<T: Decodable>(
    _ urlRequest: URLRequest,
    jsonDecoder: JSONDecoder = JSONDecoder()
  ) -> AnyPublisher<T, NetworkError> {
    request(urlRequest, jsonDecoder: jsonDecoder)
      .map(\.object)
      .eraseToAnyPublisher()
  }

  func request<T: Decodable>(
    _ urlRequest: URLRequest,
    jsonDecoder: JSONDecoder = JSONDecoder(),
    ofResponseType: T.Type
  ) -> AnyPublisher<T, NetworkError> {
    request(urlRequest, jsonDecoder: jsonDecoder)
  }

  func request(_ urlRequest: URLRequest) -> AnyPublisher<Void, NetworkError> {
    request(urlRequest)
      .map { _, _ in () }
      .eraseToAnyPublisher()
  }
}
