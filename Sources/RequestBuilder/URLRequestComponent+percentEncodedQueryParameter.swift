import Foundation
import Utils

private extension URLRequestComponent {
  static func percentEncodedQueryParameter(name: String, value: LosslessStringConvertible) -> Self {
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
          newURLComponents.queryItems = (urlComponents.queryItems ?? [])
          newURLComponents.percentEncodedQueryItems?.append(newQueryItem)

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

public typealias PercentEncodedQueryParameter = URLRequestComponent

public extension PercentEncodedQueryParameter {
  init(_ name: String, encodedValue: LosslessStringConvertible) {
    self = URLRequestComponent.percentEncodedQueryParameter(name: name, value: encodedValue)
  }
}
