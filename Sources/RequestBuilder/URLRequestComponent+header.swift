import Foundation

private extension URLRequestComponent {
  static func header(_ header: HTTPHeader) -> Self {
    .init { urlRequest in
      let headerFields = Dictionary(uniqueKeysWithValues: [(header.name, header.value)])

      var newURLRequest = urlRequest
      newURLRequest.allHTTPHeaderFields = (urlRequest.allHTTPHeaderFields ?? [:]).merging(headerFields) { $1 }

      return Result.success(newURLRequest)
    }
  }
}

// MARK: - Syntax sugar

public typealias Header = URLRequestComponent

public extension Header {
  init(_ header: HTTPHeader) {
    self = URLRequestComponent.header(header)
  }

  init(_ name: String, headerValue: String) {
    self = URLRequestComponent.header(.init(name: name, value: headerValue))
  }

  init(_ name: HTTPHeaderName, headerValue: String) {
    self = URLRequestComponent.header(.init(name: name, value: headerValue))
  }
}
