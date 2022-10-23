import Foundation

private extension URLRequestComponent {
  static func method(_ method: HTTPMethod) -> Self {
    .init { urlRequest in
      var newURLRequest = urlRequest
      newURLRequest.httpMethod = method.rawValue

      return Result.success(newURLRequest)
    }
  }
}

// MARK: - Syntax sugar

public typealias Method = URLRequestComponent

public extension Method {
  init(_ method: HTTPMethod) {
    self = URLRequestComponent.method(method)
  }
}
