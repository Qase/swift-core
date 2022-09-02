import ErrorReporting
import Foundation

public struct TokenError: ErrorReporting {
  public enum Cause: Error, CustomStringConvertible {
    case localTokenError
    case tokenLocallyInvalid
    case refreshError

    public var description: String {
      switch self {
      case .localTokenError:
          return "localTokenError"
      case .tokenLocallyInvalid:
          return "tokenLocallyInvalid"
      case .refreshError:
          return "refreshError"
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

// MARK: - TokenError + Equatable

extension TokenError: Equatable {
  public static func == (lhs: TokenError, rhs: TokenError) -> Bool {
    lhs.isEqual(to: rhs)
  }
}

// MARK: - Instances

extension TokenError {
  static var localTokenError: Self {
    TokenError(cause: .localTokenError)
  }

  static var tokenLocallyInvalid: Self {
    TokenError(cause: .tokenLocallyInvalid)
  }

  static var refreshError: Self {
    TokenError(cause: .refreshError)
  }
}
