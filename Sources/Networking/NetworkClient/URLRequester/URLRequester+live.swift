import Foundation

extension URLRequester {
  static let live: Self = .init { urlSessionConfiguration in { urlRequest in
      URLSession(configuration: urlSessionConfiguration)
        .dataTaskPublisher(for: urlRequest)
        .eraseToAnyPublisher()
    }
  }
}
