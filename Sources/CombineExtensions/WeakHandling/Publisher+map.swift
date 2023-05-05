import Combine
import ErrorReporting

// MARK: - ErrorHandling map extensions

/// upstream: `Publisher<Output, Failure: ErrorReporting>`
/// transform: `(Output) -> NewOutput`
/// downstream: `Publisher<NewOutput, Failure: ErrorReporting>`
public extension Publisher where Failure: CombineErrorReporting {
  func map<A: AnyObject, NewOutput>(
    weak obj: A,
    in file: String = #file,
    on line: Int = #line,
    logger log: @escaping (String) -> Void = { Swift.print($0) },
    onWeakNil error: Failure,
    _ transform: @escaping (A, Output) -> NewOutput
  ) -> AnyPublisher<NewOutput, Failure> {
    flatMap { [weak obj] output -> AnyPublisher<NewOutput, Failure> in
      guard let obj = obj else {
        log("Self is nil in file: \(file), on line: \(line)!")

        var newError = error
        newError.setProperties(from: GeneralError.weakNil(file: file, line: line))

        return Fail<NewOutput, Failure>(error: error)
          .eraseToAnyPublisher()
      }

      return Just(transform(obj, output))
        .setFailureType(to: Failure.self)
        .eraseToAnyPublisher()
    }
    .eraseToAnyPublisher()
  }
}

/// upstream: `Publisher<Output, Never>`
/// transform: `(Output) -> NewOutput`
/// downstream: `Publisher<NewOutput, Failure>`
public extension Publisher where Failure == Never {
  func map<A: AnyObject, NewOutput, NewFailure: CombineErrorReporting>(
    weak obj: A,
    in file: String = #file,
    on line: Int = #line,
    logger log: @escaping (String) -> Void = { Swift.print($0) },
    onWeakNil error: NewFailure,
    _ transform: @escaping (A, Output) -> NewOutput
  ) -> AnyPublisher<NewOutput, NewFailure> {
    flatMap { [weak obj] output -> AnyPublisher<NewOutput, NewFailure> in
      guard let obj = obj else {
        log("Self is nil in file: \(file), on line: \(line)!")

        var newError = error
        newError.setProperties(from: GeneralError.weakNil(file: file, line: line))

        return Fail<NewOutput, NewFailure>(error: error)
          .eraseToAnyPublisher()
      }

      return Just(transform(obj, output))
        .setFailureType(to: NewFailure.self)
        .eraseToAnyPublisher()
    }
    .eraseToAnyPublisher()
  }
}
