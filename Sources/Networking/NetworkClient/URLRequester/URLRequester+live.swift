import Foundation

public extension URLRequester {
  static func live(urlSessionConfiguration: URLSessionConfiguration) -> URLRequester {
    let urlSession = URLSession(configuration: urlSessionConfiguration)

    return .init(
      request: { urlRequest in
        urlSession
          .dataTaskPublisher(for: urlRequest)
          .eraseToAnyPublisher()
      }
    )
  }
}
