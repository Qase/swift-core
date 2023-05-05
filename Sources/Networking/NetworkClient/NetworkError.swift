import ErrorReporting
import Foundation

public struct NetworkError: CombineErrorReporting, URLRequestBuilderErrorCapable, ErrorReporting {
  
  public enum Cause: Error, CustomStringConvertible {
    case urlError(URLError)
    case invalidResponse
    case unauthorized
    case clientError(statusCode: Int)
    case serverError(statusCode: Int)
    case noConnection
    case jsonDecodingError(Error)
    case urlRequestBuilderError
    case timeout
    
    public var description: String {
      switch self {
      case let .urlError(urlError):
        return "urlError(urlError: \(urlError))"
      case .invalidResponse:
        return "invalidResponse"
      case .unauthorized:
        return "unauthorized"
      case let .clientError(statusCode):
        return "clientError(statusCode: \(statusCode))"
      case let .serverError(statusCode):
        return "serverError(statusCode: \(statusCode))"
      case .noConnection:
        return "noConnection"
      case let .jsonDecodingError(error):
        return "jsonDecodingError(error: \(error))"
      case .urlRequestBuilderError:
        return "urlRequestBuilderError"
      case .timeout:
        return "timeout"
      }
    }
    
    public var causeUIDescription: String {
      switch self {
      case .invalidResponse:
        return "Invalid response"
      case .urlError:
        return "Internal error"
      case .unauthorized:
        return "Bad credentials"
      case .clientError:
        return "Client error"
      case .serverError:
        return "Server error"
      case .noConnection:
        return "No connection"
      case .jsonDecodingError:
        return "Internal error"
      case .urlRequestBuilderError:
        return "Internal error"
      case .timeout:
        return "Timeout"
      }
    }
  }
  
  public var causeDescription: String {
    cause.description
  }
  
  public var causeUIdescription: String {
    cause.causeUIDescription
  }
  
  public let cause: Cause
  
  public var stackID: UUID
  public var underlyingError: CombineErrorReporting?
  public var requestID: String?
  
  init(
    stackID: UUID = UUID(),
    cause: Cause,
    underlyingError: CombineErrorReporting? = nil,
    requestID: String? = nil
  ) {
    self.stackID = stackID
    self.cause = cause
    self.underlyingError = underlyingError
    self.requestID = requestID
  }
}

// MARK: - NetworkError + Equatable

extension NetworkError: Equatable {
  public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
    lhs.isEqual(to: rhs)
  }
}

// MARK: - NetworkError + instances

public extension NetworkError {
  static func urlError(_ innerError: URLError) -> Self {
    NetworkError(cause: .urlError(innerError))
  }
  
  static var invalidResponse: Self {
    NetworkError(cause: .invalidResponse)
  }

  static var unauthorized: Self {
    NetworkError(cause: .unauthorized)
  }
  
  static func clientError(statusCode: Int) -> Self {
    NetworkError(cause: .clientError(statusCode: statusCode))
  }
  
  static func serverError(statusCode: Int) -> Self {
    NetworkError(cause: .serverError(statusCode: statusCode))
  }
  
  static var noConnection: Self {
    NetworkError(cause: .noConnection)
  }
  
  static func jsonDecodingError(_ innerError: Error) -> Self {
    NetworkError(cause: .jsonDecodingError(innerError))
  }
  
  static var urlRequestBuilderError: Self {
    NetworkError(cause: .urlRequestBuilderError)
  }
  
  static var timeoutError: Self {
    NetworkError(cause: .timeout)
  }
}
