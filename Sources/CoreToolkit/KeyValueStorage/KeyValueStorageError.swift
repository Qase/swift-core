import Foundation
import ErrorReporting

public struct KeyValueStorageError: ErrorReporting {
  public enum Cause: Error, CustomStringConvertible {
    case storeError(Error)
    case noData
    case loadError(Error)
    case deleteError(Error)

    public var description: String {
      let caseString: (String) -> String = { "ErrorCause.\($0)" }

      switch self {
      case let .storeError(error):
        return caseString("storeError(\(error.localizedDescription).")
      case .noData:
        return caseString("noData")
      case let .loadError(error):
        return caseString("loadError(\(error.localizedDescription).")
      case let .deleteError(error):
        return caseString("deleteError(\(error.localizedDescription)).")
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

// MARK: - KeyValueStorageError + Equatable

extension KeyValueStorageError: Equatable {
  public static func == (lhs: KeyValueStorageError, rhs: KeyValueStorageError) -> Bool {
    lhs.isEqual(to: rhs)
  }
}

// MARK: - Instances

public extension KeyValueStorageError {
  static var storeError: (Error) -> Self = { error in
    .init(cause: .storeError(error))
  }

  static var noData: Self {
    .init(cause: .noData)
  }

  static var loadError: (Error) -> Self = { error in
    .init(cause: .loadError(error))
  }

  static var deleteError: (Error) -> Self = { error in
    .init(cause: .deleteError(error))
  }
}
