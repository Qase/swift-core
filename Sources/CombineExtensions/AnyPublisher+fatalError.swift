import Combine

public extension AnyPublisher {
  static var fatalError: Self {
    Deferred {
      Future { _ in
        Swift.fatalError("Not implemented!")
      }
    }
    .eraseToAnyPublisher()
  }
}
