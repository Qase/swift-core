import ErrorReporting
import Foundation

public struct TokenPersistenceError: ErrorReporting {
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
  public var underlyingError: ErrorReporting?

  private init(
    stackID: UUID = UUID(),
    cause: Cause,
    underlyingError: ErrorReporting? = nil
  ) {
    self.stackID = stackID
    self.cause = cause
    self.underlyingError = underlyingError
  }
}

// MARK: - TokenPersistenceError + Equatable

extension TokenPersistenceError: Equatable {
  public static func == (lhs: TokenPersistenceError, rhs: TokenPersistenceError) -> Bool {
    lhs.isEqual(to: rhs)
  }
}

// MARK: - Instances

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