import ErrorReporting
import Foundation

public struct AuthorizedNetworkError: ErrorReporting {
  public enum Cause: Error, CustomStringConvertible {
    case networkError
    case localTokenError
    case refreshTokenError
    case unknownToken

    public var description: String {
      switch self {
      case .networkError:
          return "networkError"
      case .localTokenError:
          return "localTokenError"
      case .refreshTokenError:
          return "refreshTokenError"
      case .unknownToken:
        return "unknownToken"
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

// MARK: - AuthorizedNetworkError + Equatable

extension AuthorizedNetworkError: Equatable {
  public static func == (lhs: AuthorizedNetworkError, rhs: AuthorizedNetworkError) -> Bool {
    lhs.isEqual(to: rhs)
  }
}

// MARK: - AuthorizedNetworkError + instances

public extension AuthorizedNetworkError {
  static var networkError: Self {
    AuthorizedNetworkError(cause: .networkError)
  }

  static var localTokenError: Self {
    AuthorizedNetworkError(cause: .localTokenError)
  }

  static var refreshTokenError: Self {
    AuthorizedNetworkError(cause: .refreshTokenError)
  }

  static var unknownToken: Self {
    AuthorizedNetworkError(cause: .unknownToken)
  }
}
