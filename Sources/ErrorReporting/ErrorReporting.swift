import Combine
import Foundation

public protocol ErrorReporting: Error, CustomStringConvertible, CustomDebugStringConvertible, ErrorComparing {
  var stackID: UUID { get set }
  var causeDescription: String { get }
  var underlyingError: ErrorReporting? { get set }
}

// MARK: - ErrorReporting + ErrorComparing

public extension ErrorReporting {
  // NOTE: This value is used to compare errors. Equatable conformance is required by TCA architecture and for testing purposes.
  // It describes the whole error stack while not using the stackID property.
  // Two error stacks might be equal even if linked by a different stackID.
  // The stackID property is used only to link individual errors within the stack and does not carry any business important information.
  var comparableDescription: CustomStringConvertible {
    let underlyingErrorDescription = underlyingError.map { "\n |_ \($0.comparableDescription)" } ?? ""

    return "\(type(of: self)) - cause: \(causeDescription)\(underlyingErrorDescription)"
  }
}

//MARK: - ErrorReporting + Equatable

public extension ErrorReporting where Self: Equatable {
  func isEqual(to error: ErrorReporting) -> Bool {
    self.comparableDescription.description == error.comparableDescription.description
  }
}


// MARK: - ErrorReporting + StringConvertible

public extension ErrorReporting {
  var description: String {
    "\(type(of: self)) - stackID: \(stackID.uuidString) - cause: \(causeDescription)"
  }

  var debugDescription: String {
    let underlyingErrorDescription = underlyingError.map { "\n |_ \($0.debugDescription)" } ?? ""

    return "\(description)\(underlyingErrorDescription)"
  }
}

// MARK: - Publisher + mapErrorReporting

public extension ErrorReporting {
  mutating func setProperties(from error: ErrorReporting) {
    self.stackID = error.stackID
    self.underlyingError = error
  }
}

public extension Publisher where Failure: ErrorReporting {
  func mapErrorReporting<NewError: ErrorReporting>(
    _ transform: @escaping (Failure) -> NewError
  ) -> Publishers.MapError<Self, NewError> {
    mapError { error in
      var resultingError = transform(error)
      resultingError.setProperties(from: error)

      return resultingError
    }
  }

  func mapErrorReporting<NewError: ErrorReporting>(
    to newError: NewError
  ) -> Publishers.MapError<Self, NewError> {
    mapErrorReporting { _ in newError }
  }
}

public extension Publisher where Output: ErrorReporting {
  func mapErrorReporting<NewError: ErrorReporting>(
    _ transform: @escaping (Output) -> NewError
  ) -> Publishers.Map<Self, NewError> {
    map { error in
      var resultingError = transform(error)
      resultingError.setProperties(from: error)

      return resultingError
    }
  }

  func mapErrorReporting<NewError: ErrorReporting>(
    to newError: NewError
  ) -> Publishers.Map<Self, NewError> {
    mapErrorReporting { _ in newError }
  }
}

// MARK: - Result + mapErrorReporting

public extension Result where Failure: ErrorReporting {
  func mapErrorReporting<E2: ErrorReporting>(
    _ transform: @escaping (Failure) -> E2
  ) -> Result<Success, E2> {
    mapError { error in
      var resultingError = transform(error)
      resultingError.setProperties(from: error)

      return resultingError
    }
  }

  func mapErrorReporting<NewError: ErrorReporting>(
    to newError: NewError
  ) -> Result<Success, NewError> {
    mapErrorReporting { _ in newError }
  }
}

// MARK: - ErrorReporting + first

public extension ErrorReporting {
  /// Returns the first error in the underlying stack of errors (including self)
  /// that satisfies the given predicate.
  ///
  /// - Parameter predicate: A closure that takes an error from the stack as
  ///   its argument and returns a Boolean value indicating whether the
  ///   element is a match.
  /// - Returns: The first element of the stack that satisfies `predicate`,
  ///   or `nil` if there is no element that satisfies `predicate`.
  func first(where predicate: (ErrorReporting) throws -> Bool) rethrows -> ErrorReporting? {
    try predicate(self)
    ? self
    : underlyingError?.first(where: predicate)
  }

  /// Returns `true` if it finds an error in the underlying stack of errors (including self)
  /// that satisfies the given predicate.
  ///
  /// - Parameter predicate: A closure that takes an error from the stack as
  ///   its argument and returns a Boolean value indicating whether the
  ///   element is a match.
  /// - Returns: `true` if any of the errors within the stack of errors (including self) satisfies `predicate`, `false` otherwise.
  func contains(where predicate: (ErrorReporting) throws -> Bool) rethrows -> Bool {
    try first(where: predicate) != nil
  }

  /// Returns the first error in the underlying stack of errors (including self)
  /// of the given type.
  ///
  /// Shorthand for:
  /// ```
  /// first(where: { $0 is Error }) as? Error
  /// ```
  ///
  /// - Parameter type: A type of error to be found in the stack of errors.
  /// - Returns: The first error of the of the given `type`, or `nil` if not found.
  func first<Error>(ofType type: Error.Type) -> Error? {
    first { $0 is Error } as? Error
  }

  /// Returns `true` if it finds an error in the underlying stack of errors (including self) that is of the given type.
  ///
  /// Shorthand for:
  /// ```
  /// first(where: { $0 is Error }) as? Error
  /// ```
  ///
  /// - Parameter type: A type of error to be found in the stack of errors.
  /// - Returns: `true` if any of the errors within the stack of errors (including self) is of the given type, `false` otherwise.
  func contains<Error>(ofType type: Error.Type) -> Bool {
    first(ofType: type) != nil
  }
}
