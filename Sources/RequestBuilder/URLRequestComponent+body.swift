import Foundation

private extension URLRequestComponent {
  static func data(_ data: Data) -> Self {
    .init { .success($0.withBody(data)) }
  }

  static func body<T: Encodable>(_ value: T, jsonEncoder: JSONEncoder = JSONEncoder()) -> Self {
    .init { urlRequest in
      Result<URLRequest, URLRequestError>.execute(
        { try jsonEncoder.encode(value) },
        onThrows: URLRequestError.bodyEncodingError
      )
        .map(urlRequest.withBody(_:))
    }
  }
}

private extension URLRequest {
  func withBody(_ data: Data) -> Self {
    var newURLRequest = self
    newURLRequest.httpBody = data
    return newURLRequest
  }
}

// MARK: - Syntax sugar

public typealias Body = URLRequestComponent

public extension Body {
  init<T: Encodable>(encodable: T, jsonEncoder: JSONEncoder = JSONEncoder()) {
    self = URLRequestComponent.body(encodable, jsonEncoder: jsonEncoder)
  }

  init(data: Data) {
    self = URLRequestComponent.data(data)
  }
}
