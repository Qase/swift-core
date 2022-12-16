import Foundation

public extension URLRequest {
  static func with(method: HTTPMethod) -> (URLRequest) -> URLRequest {
    { urlRequest in
      var newURLRequest = urlRequest
      newURLRequest.httpMethod = method.rawValue

      return newURLRequest
    }
  }

  static func with(headers: [HTTPHeader]) -> (URLRequest) -> URLRequest {
    { urlRequest in
      let headerFields = Dictionary(uniqueKeysWithValues: zip(headers.map(\.name), headers.map(\.value)))

      var newURLRequest = urlRequest
      newURLRequest.allHTTPHeaderFields = (urlRequest.allHTTPHeaderFields ?? [:]).merging(headerFields) { $1 }

      return newURLRequest
    }
  }

  static func with<T: Encodable>(
    body: T,
    jsonEncoder: JSONEncoder = JSONEncoder()
  ) -> (URLRequest) -> Result<URLRequest, URLRequestError> {
    { urlRequest in
      Result<Data, URLRequestError>.execute(
        { try jsonEncoder.encode(body) },
        onThrows: URLRequestError.bodyEncodingError
      )
        .map { body in
          var newURLRequest = urlRequest
          newURLRequest.httpBody = body

          return newURLRequest
        }
    }
  }
}

// MARK: - Syntax sugar functions to enhance ergonomics

private extension Result {
  static func lift(_ transform: @escaping (Success) -> Success) -> (Result<Success, Failure>) -> Result<Success, Failure> {
    { $0.map(transform) }
  }

  static func lift(
    _ transform: @escaping (Success) -> Result<Success, Failure>
  ) -> (Result<Success, Failure>) -> Result<Success, Failure> {
    { $0.flatMap(transform) }
  }
}

extension URLRequest {
  static func with(method: HTTPMethod) -> (Result<URLRequest, URLRequestError>) -> Result<URLRequest, URLRequestError> {
    Result<URLRequest, URLRequestError>.lift(URLRequest.with(method: method))
  }

  static func with(headers: [HTTPHeader]) -> (Result<URLRequest, URLRequestError>) -> Result<URLRequest, URLRequestError> {
    Result<URLRequest, URLRequestError>.lift(URLRequest.with(headers: headers))
  }

  static func with<T: Encodable>(
    body: T,
    jsonEncoder: JSONEncoder = JSONEncoder()
  ) -> (Result<URLRequest, URLRequestError>) -> Result<URLRequest, URLRequestError> {
    Result<URLRequest, URLRequestError>.lift(with(body: body, jsonEncoder: jsonEncoder))
  }
}
