import ErrorReporting
import Foundation

public struct DatabaseError: ErrorReporting {
  public enum Cause: Error, CustomDebugStringConvertible {//, Equatable {
    case fetchError(Error?)
    case nilWhenFetch
    case objectExistsWhenCreate
    case saveError(Error)
    case deleteError(Error)
    case observeError
    
    public var debugDescription: String {
      switch self {
      case let .fetchError(error):
        return "ErrorCause.fetchError(error: \(String(describing: error)))."
      case .nilWhenFetch:
        return "ErrorCause.nilWhenFetch."
      case .objectExistsWhenCreate:
        return "ErrorCause.objectExistsWhenCreate"
      case let .saveError(error):
        return "ErrorCause.saveError(error: \(error))."
      case let .deleteError(error):
        return "ErrorCause.deleteError(error: \(error))."
      case .observeError:
        return "ErrorCause.observeError"
      }
    }
    
//    public static func == (lhs: DatabaseError.Cause, rhs: DatabaseError.Cause) -> Bool {
//      switch (lhs, rhs) {
//      case (.fetchError, .fetchError):
//        return true
//      case (.nilWhenFetch, .nilWhenFetch):
//        return true
//      case (.objectExistsWhenCreate, .objectExistsWhenCreate):
//        return true
//      case (.saveError, .saveError):
//        return true
//      case (.deleteError, .deleteError):
//        return true
//      case (.observeError, .observeError):
//        return true
//      default:
//        return false
//      }
//    }
  }
  
  public var causeDescription: String {
    cause.debugDescription
  }

  public let cause: Cause

  public var stackID: UUID
  public var underlyingError: ErrorReporting?
  public var requestID: String?
  
  init(
    stackID: UUID = UUID(),
    cause: Cause,
    underlyingError: ErrorReporting? = nil,
    requestID: String? = nil
  ) {
    self.stackID = stackID
    self.cause = cause
    self.underlyingError = underlyingError
    self.requestID = requestID
  }
}

// MARK: - DatabaseError + Equatable

extension DatabaseError: Equatable {
  public static func == (lhs: DatabaseError, rhs: DatabaseError) -> Bool {
    lhs.isEqual(to: rhs)
  }
}

// MARK: - NetworkError instances

public extension DatabaseError {
  static var fetchError: (Error?) -> Self {
    { .init(cause: .fetchError($0)) }
  }
  
  static var saveError: (Error) -> Self {
    { .init(cause: .saveError($0)) }
  }
  
  static var nilWhenFetch: Self {
    .init(cause: .nilWhenFetch)
  }
  
  static var objectExistsWhenCreate: Self {
    .init(cause: .objectExistsWhenCreate)
  }
  
  static var deleteError: (Error) -> Self {
    { .init(cause: .deleteError($0)) }
  }
  
  static var observeError: Self {
    .init(cause: .observeError)
  }
}
