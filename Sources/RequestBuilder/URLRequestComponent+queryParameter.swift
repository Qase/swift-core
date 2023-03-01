import Foundation
import Utils

private extension URLRequestComponent {
  static func queryParameter(name: String, value: LosslessStringConvertible) -> Self {
    .init { urlRequest in
      Result<String, URLRequestError>.from(
        optional: urlRequest.url?.absoluteString,
        onNil: .endpointParsingError
      )
        .map(URLComponents.init(string:))
        .flatMap { $0.map(Result.success) ?? .failure(.invalidURLComponents) }
        .map { urlComponents -> URLComponents in
          let newQueryItem = URLQueryItem(name: name, value: String(describing: value))

          var newURLComponents = urlComponents
          newURLComponents.queryItems = (urlComponents.queryItems ?? []) + [newQueryItem]

          return newURLComponents
        }
        .map(\.url)
        .map { url in
          var newURLRequest = urlRequest
          newURLRequest.url = url

          return newURLRequest
        }
    }
  }
}

// MARK: - Syntax sugar

public typealias QueryParameter = URLRequestComponent

public extension QueryParameter {
  init(_ name: String, parameterValue: LosslessStringConvertible) {
    self = URLRequestComponent.queryParameter(name: name, value: parameterValue)
  }
}
