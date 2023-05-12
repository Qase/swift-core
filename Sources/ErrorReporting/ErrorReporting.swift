public protocol ErrorReporting: Error, CustomDebugStringConvertible, CustomStringConvertible, Equatable {}

public extension ErrorReporting {
  static func ==(lhs: Self, rhs: Self) -> Bool {
    lhs.description == rhs.description && lhs.debugDescription == rhs.debugDescription
  }
}
