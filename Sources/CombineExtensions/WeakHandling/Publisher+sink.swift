import Combine

public extension Publisher {
  func sink<A: AnyObject>(
    weak obj: A,
    in file: String = #file,
    on line: Int = #line,
    logger log: @escaping (String) -> Void = { Swift.print($0) },
    shouldAssertOnNil: Bool = true,
    receiveCompletion: @escaping (A, Subscribers.Completion<Self.Failure>) -> Void,
    receiveValue: @escaping (A, Self.Output) -> Void
  ) -> AnyCancellable {
    sink(
      receiveCompletion: { [weak obj] completion in
        guard let obj = obj else {
          let logMessage = "Self is nil in file: \(file), on line: \(line)!"
          log(logMessage)

          if shouldAssertOnNil { Swift.assertionFailure(logMessage) }

          return
        }

        receiveCompletion(obj, completion)
      },
      receiveValue: { [ weak obj] value in
        guard let obj = obj else {
          let logMessage = "Self is nil in file: \(file), on line: \(line)!"
          log(logMessage)

          if shouldAssertOnNil { Swift.assertionFailure(logMessage) }

          return
        }

        receiveValue(obj, value)
      }
    )
  }
}

public extension Publisher where Self.Failure == Never {
  func sink<A: AnyObject>(
    weak obj: A,
    in file: String = #file,
    on line: Int = #line,
    logger log: @escaping (String) -> Void = { Swift.print($0) },
    shouldAssertOnNil: Bool = true,
    receiveCompletion: ((A, Subscribers.Completion<Self.Failure>) -> Void)? = nil,
    receiveValue: @escaping (A, Self.Output) -> Void
  ) -> AnyCancellable {
    sink(
      receiveCompletion: { [weak obj] completion in
        guard let obj = obj else {
          let logMessage = "Self is nil in file: \(file), on line: \(line)!"
          log(logMessage)

          if shouldAssertOnNil { Swift.assertionFailure(logMessage) }

          return
        }

        receiveCompletion?(obj, completion)
      },
      receiveValue: { [ weak obj] value in
        guard let obj = obj else {
          let logMessage = "Self is nil in file: \(file), on line: \(line)!"
          log(logMessage)

          if shouldAssertOnNil { Swift.assertionFailure(logMessage) }

          return
        }

        receiveValue(obj, value)
      }
    )
  }
}
