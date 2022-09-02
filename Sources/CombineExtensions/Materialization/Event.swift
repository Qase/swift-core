// Source: https://github.com/CombineCommunity/CombineExt

/// Represents a Combine Event
public enum Event<Output, Failure: Swift.Error> {
  case value(Output)
  case failure(Failure)
  case finished
}

// MARK: - Equatable Conformance

extension Event: Equatable where Output: Equatable, Failure: Equatable {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.finished, .finished):
      return true
    case let (.failure(err1), .failure(err2)):
      return err1 == err2
    case let (.value(val1), .value(val2)):
      return val1 == val2
    default:
      return false
    }
  }
}

// MARK: - Friendly Output

extension Event: CustomStringConvertible {
  public var description: String {
    switch self {
    case .value(let val):
      return "value(\(val))"
    case .failure(let err):
      return "failure(\(err))"
    case .finished:
      return "finished"
    }
  }
}

// MARK: - Event Convertible

/// A protocol representing `Event` convertible types
public protocol EventConvertible {
  associatedtype Output
  associatedtype Failure: Swift.Error

  var event: Event<Output, Failure> { get }
}

extension Event: EventConvertible {
  public var event: Event<Output, Failure> { self }
}

// MARK: - Associated value access

public extension Event {
  var value: Output? {
    guard case let .value(success) = self else {
      return nil
    }

    return success
  }

  var failure: Failure? {
    guard case let .failure(failure) = self else {
      return nil
    }

    return failure
  }
}
