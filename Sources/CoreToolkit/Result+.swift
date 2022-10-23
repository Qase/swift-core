import Foundation

public extension Result {
  static func execute<T, E: Error>(_ function: @escaping () throws -> T, onThrows errorFunction: (Error) -> E) -> Result<T, E> {
    do {
      return .success(try function())
    } catch let error {
      return .failure(errorFunction(error))
    }
  }
}

public extension Result {
  static func from<T, E: Error>(optional: T?, onNil error: E) -> Result<T, E> {
    optional.map(Result<T, E>.success) ?? Result<T, E>.failure(error)
  }
}

public extension Result {
  var success: Success? {
    guard case let .success(success) = self else {
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
