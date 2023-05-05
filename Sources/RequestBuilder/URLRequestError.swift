import ErrorReporting
import Foundation

public struct URLRequestError: CombineErrorReporting, ErrorReporting {
 
  public enum Cause: Error, CustomStringConvertible {
    case endpointParsingError
    case parameterParsingError
    case invalidURLComponents
    case bodyEncodingError(Error)
    
    public var description: String {
      switch self {
      case .endpointParsingError:
        return "endpointParsingError"
      case .parameterParsingError:
        return "parameterParsingError"
      case .invalidURLComponents:
        return "invalidURLComponents"
      case let .bodyEncodingError(error):
        return "bodyEncodingError(error: \(error))"
      }
    }
    
    public var UIdescription: String {
      return "Endpoint errror"
    }
  }
  
  public var causeDescription: String {
    cause.description
  }
  
  public var causeUIdescription: String {
    cause.UIdescription
  }
  
  public let cause: Cause
  
  public var stackID: UUID
  public var underlyingError: CombineErrorReporting?
  
  private init(
    stackID: UUID = UUID(),
    cause: Cause,
    underlyingError: CombineErrorReporting? = nil
  ) {
    self.stackID = stackID
    self.cause = cause
    self.underlyingError = underlyingError
  }
}

// MARK: - URLRequestError + Equatable

extension URLRequestError: Equatable {
  public static func == (lhs: URLRequestError, rhs: URLRequestError) -> Bool {
    lhs.isEqual(to: rhs)
  }
}

// MARK: - URLRequestError + instances

public extension URLRequestError {
  static var endpointParsingError: Self {
    URLRequestError(cause: .endpointParsingError)
  }
  
  static var parameterParsingError: Self {
    URLRequestError(cause: .parameterParsingError)
  }
  
  static var invalidURLComponents: Self {
    URLRequestError(cause: .invalidURLComponents)
  }
  
  static func bodyEncodingError(_ innerError: Error) -> Self {
    URLRequestError(cause: .bodyEncodingError(innerError))
  }
}
