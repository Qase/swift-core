import Combine
import ErrorReporting

// MARK: General flatMap extensions

/// upstream: `Publisher<Output, Failure>`
/// transform: `(Output) -> Publisher<NewOutput, Failure>`
/// downstream: `Publisher<NewOutput, Failure>`
public extension Publisher where Failure: CombineErrorReporting {
  func flatMap<A: AnyObject, P: Publisher>(
    weak obj: A,
    in file: String = #file,
    on line: Int = #line,
    logger log: @escaping (String) -> Void = { Swift.print($0) },
    onWeakNil: P,
    _ transform: @escaping (A, Self.Output) -> P
  ) -> Publishers.FlatMap<P, Self> where Self.Failure == P.Failure {
    flatMap { [weak obj] element -> P in
      guard let obj = obj else {
        log("Self is nil in file: \(file), on line: \(line)!")
        return onWeakNil
      }

      return transform(obj, element)
    }
  }
}

// MARK: - ErrorHandling flatMap extensions

/// upstream: `Publisher<Output, Failure: ErrorReporting>`
/// transfer: `(Output) -> Publisher<NewOutput, Failure: ErrorReporting`
/// downstream: `Publisher<NewOutput, Failure: ErrorReporting>`
public extension Publisher where Failure: CombineErrorReporting {
  func flatMap<A: AnyObject, P: Publisher>(
    weak obj: A,
    in file: String = #file,
    on line: Int = #line,
    logger log: @escaping (String) -> Void = { Swift.print($0) },
    onWeakNil error: Failure,
    _ transform: @escaping (A, Output) -> P
  ) -> AnyPublisher<P.Output, Failure> where P.Failure == Failure {
    flatMap { [weak obj] element -> AnyPublisher<P.Output, P.Failure> in
      guard let obj = obj else {
        log("Self is nil in file: \(file), on line: \(line)!")

        var newError = error
        newError.setProperties(from: GeneralError.weakNil(file: file, line: line))

        return Fail<P.Output, Failure>(error: newError)
          .eraseToAnyPublisher()
      }

      return transform(obj, element)
        .eraseToAnyPublisher()
    }
    .eraseToAnyPublisher()
  }
}

/// upstream: `Publisher<Output, Never>`
/// transform" `(Output) -> Publisher<NewOutput, Failure: ErrorReporting>`
/// downstream: `Publisher<NewOutput, Failure: ErrorReporting>`
public extension Publisher where Failure == Never {
  func flatMap<A: AnyObject, P: Publisher>(
    weak obj: A,
    in file: String = #file,
    on line: Int = #line,
    logger log: @escaping (String) -> Void = { Swift.print($0) },
    onWeakNil error: P.Failure,
    _ transform: @escaping (A, Self.Output) -> P
  ) -> AnyPublisher<P.Output, P.Failure> where P.Failure: CombineErrorReporting {
    flatMap { [weak obj] element -> AnyPublisher<P.Output, P.Failure> in
      guard let obj = obj else {
        log("Self is nil in file: \(file), on line: \(line)!")

        var newError = error
        newError.setProperties(from: GeneralError.weakNil(file: file, line: line))

        return Fail<P.Output, P.Failure>(error: newError)
          .eraseToAnyPublisher()
      }

      return transform(obj, element)
        .eraseToAnyPublisher()
    }
    .eraseToAnyPublisher()
  }
}

/// upstream: `Publisher<Output, Failure: ErrorReporting>`
/// transfer: `(Output) -> Publisher<NewOutput, Failure: Never>`
/// downstream: `Publisher<NewOutput, Failure: ErrorReporting>`
public extension Publisher where Failure: CombineErrorReporting {
  func flatMap<A: AnyObject, P: Publisher>(
    weak obj: A,
    in file: String = #file,
    on line: Int = #line,
    logger log: @escaping (String) -> Void = { Swift.print($0) },
    onWeakNil error: Failure,
    _ transform: @escaping (A, Output) -> P
  ) -> AnyPublisher<P.Output, Failure> where P.Failure == Never {
    flatMap { [weak obj] element -> AnyPublisher<P.Output, Failure> in
      guard let obj = obj else {
        log("Self is nil in file: \(file), on line: \(line)!")

        var newError = error
        newError.setProperties(from: GeneralError.weakNil(file: file, line: line))

        return Fail<P.Output, Failure>(error: newError)
          .eraseToAnyPublisher()
      }

      return transform(obj, element)
        .setFailureType(to: Failure.self)
        .eraseToAnyPublisher()
    }
    .eraseToAnyPublisher()
  }
}
