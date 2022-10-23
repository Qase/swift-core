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
