import Combine
import Foundation

public protocol CombineErrorReporting: Error, CustomStringConvertible, CustomDebugStringConvertible, ErrorComparing {
  var stackID: UUID { get set }
  var causeDescription: String { get }
  var underlyingError: CombineErrorReporting? { get set }
}

// MARK: - CombineErrorReporting + ErrorComparing

public extension CombineErrorReporting {
  // NOTE: This value is used to compare errors. Equatable conformance is required by TCA architecture and for testing purposes.
  // It describes the whole error stack while not using the stackID property.
  // Two error stacks might be equal even if linked by a different stackID.
  // The stackID property is used only to link individual errors within the stack and does not carry any business important information.
  var comparableDescription: CustomStringConvertible {
    let underlyingErrorDescription = underlyingError.map { "\n |_ \($0.comparableDescription)" } ?? ""

    return "\(type(of: self)) - cause: \(causeDescription)\(underlyingErrorDescription)"
  }
}

//MARK: - CombineErrorReporting + Equatable

public extension CombineErrorReporting where Self: Equatable {
  func isEqual(to error: CombineErrorReporting) -> Bool {
    self.comparableDescription.description == error.comparableDescription.description
  }
}


// MARK: - CombineErrorReporting + StringConvertible

public extension CombineErrorReporting {
  var description: String {
    "\(type(of: self)) - stackID: \(stackID.uuidString) - cause: \(causeDescription)"
  }

  var debugDescription: String {
    let underlyingErrorDescription = underlyingError.map { "\n |_ \($0.debugDescription)" } ?? ""

    return "\(description)\(underlyingErrorDescription)"
  }
}

// MARK: - Publisher + mapErrorReporting

public extension CombineErrorReporting {
  mutating func setProperties(from error: CombineErrorReporting) {
    self.stackID = error.stackID
    self.underlyingError = error
  }
}

public extension Publisher where Failure: CombineErrorReporting {
  func mapErrorReporting<NewError: CombineErrorReporting>(
    _ transform: @escaping (Failure) -> NewError
  ) -> Publishers.MapError<Self, NewError> {
    mapError { error in
      var resultingError = transform(error)
      resultingError.setProperties(from: error)

      return resultingError
    }
  }

  func mapErrorReporting<NewError: CombineErrorReporting>(
    to newError: NewError
  ) -> Publishers.MapError<Self, NewError> {
    mapErrorReporting { _ in newError }
  }
}

public extension Publisher where Output: CombineErrorReporting {
  func mapErrorReporting<NewError: CombineErrorReporting>(
    _ transform: @escaping (Output) -> NewError
  ) -> Publishers.Map<Self, NewError> {
    map { error in
      var resultingError = transform(error)
      resultingError.setProperties(from: error)

      return resultingError
    }
  }

  func mapErrorReporting<NewError: CombineErrorReporting>(
    to newError: NewError
  ) -> Publishers.Map<Self, NewError> {
    mapErrorReporting { _ in newError }
  }
}

// MARK: - Result + mapErrorReporting

public extension Result where Failure: CombineErrorReporting {
  func mapErrorReporting<E2: CombineErrorReporting>(
    _ transform: @escaping (Failure) -> E2
  ) -> Result<Success, E2> {
    mapError { error in
      var resultingError = transform(error)
      resultingError.setProperties(from: error)

      return resultingError
    }
  }

  func mapErrorReporting<NewError: CombineErrorReporting>(
    to newError: NewError
  ) -> Result<Success, NewError> {
    mapErrorReporting { _ in newError }
  }
}

// MARK: - CombineErrorReporting + first

public extension CombineErrorReporting {
  /// Returns the first error in the underlying stack of errors (including self)
  /// that satisfies the given predicate.
  ///
  /// - Parameter predicate: A closure that takes an error from the stack as
  ///   its argument and returns a Boolean value indicating whether the
  ///   element is a match.
  /// - Returns: The first element of the stack that satisfies `predicate`,
  ///   or `nil` if there is no element that satisfies `predicate`.
  func first(where predicate: (CombineErrorReporting) throws -> Bool) rethrows -> CombineErrorReporting? {
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
  func contains(where predicate: (CombineErrorReporting) throws -> Bool) rethrows -> Bool {
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
