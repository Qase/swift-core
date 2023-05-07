import ErrorReporting
import Foundation

public struct TokenPersistenceError: CombineErrorReporting, ErrorReporting {
  public enum Cause: Error, CustomStringConvertible {
    case loadTokenError
    case storeTokenError
    case deleteTokenError

    public var description: String {
      switch self {
      case .loadTokenError:
          return "loadTokenError"
      case .storeTokenError:
          return "storeTokenError"
      case .deleteTokenError:
          return "deleteTokenError"
      }
    }
  }

  public var causeDescription: String {
    cause.description
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

// MARK: - TokenPersistenceError + instances

extension TokenPersistenceError {
  static var loadTokenError: Self {
    TokenPersistenceError(cause: .loadTokenError)
  }

  static var storeTokenError: Self {
    TokenPersistenceError(cause: .storeTokenError)
  }

  static var deleteTokenError: Self {
    TokenPersistenceError(cause: .deleteTokenError)
  }
}
