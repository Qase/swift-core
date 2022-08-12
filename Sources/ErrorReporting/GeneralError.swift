import Foundation

public struct GeneralError: ErrorReporting {
  public enum Cause: Error, CustomStringConvertible {
    case weakNil(file: String, line: Int)
    
    public var description: String {
      switch self {
      case let .weakNil(file, line):
        return "weakNil(file: \(file), line: \(line))"
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

// MARK: - GeneralError + Equatable

extension GeneralError: Equatable {
  public static func == (lhs: GeneralError, rhs: GeneralError) -> Bool {
    lhs.isEqual(to: rhs)
  }
}

// MARK: - Instances

public extension GeneralError {
  static func weakNil(file: String, line: Int) -> Self {
    GeneralError(cause: .weakNil(file: file, line: line))
  }
}

