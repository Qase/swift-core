public protocol ErrorReporting: Error, CustomDebugStringConvertible, CustomStringConvertible, Equatable {
}

public extension ErrorReporting {
  static func ==(lhs: Self, rhs: Self) -> Bool {
    return lhs.description == rhs.description && lhs.debugDescription == rhs.debugDescription
    }
}
