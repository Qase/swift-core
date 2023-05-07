import ErrorReporting
import Foundation

public struct KeyValueStorageError: CombineErrorReporting, ErrorReporting {
  public enum Cause: Error, CustomStringConvertible {
    /// Triggered when save error occurs.
    case storeFailed(Error?)
    /// Triggered when load error occurs.
    case loadFailed(Error?)
    /// Triggered when delete error occurs.
    case removeFailed(Error?)
    /// Triggered when decoding error occurs.
    case decodingFailed(Error?)

    public var description: String {
      switch self {
      case let .storeFailed(error):
        return "storeFailed(error: \(String(describing: error)))"
      case let .loadFailed(error):
        return "loadFailed(error: \(String(describing: error)))"
      case let .removeFailed(error):
        return "removeFailed(error: \(String(describing: error)))"
      case let .decodingFailed(error):
        return "decodingFailed(error: \(String(describing: error)))"
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

// MARK: - KeyValueStorageError + Equatable
//
//extension KeyValueStorageError: Equatable {
//  public static func == (lhs: KeyValueStorageError, rhs: KeyValueStorageError) -> Bool {
//    lhs.isEqual(to: rhs)
//  }
//}

// MARK: - KeyValueStorageError + instances

public extension KeyValueStorageError {
  static func storeFailed(_ innerError: Error?) -> Self {
    KeyValueStorageError(cause: .storeFailed(innerError))
  }

  static func loadFailed(_ innerError: Error?) -> Self {
    KeyValueStorageError(cause: .loadFailed(innerError))
  }

  static func removeFailed(_ innerError: Error?) -> Self {
    KeyValueStorageError(cause: .removeFailed(innerError))
  }

  static func decodingFailed(_ innerError: Error?) -> Self {
    KeyValueStorageError(cause: .decodingFailed(innerError))
  }
}
