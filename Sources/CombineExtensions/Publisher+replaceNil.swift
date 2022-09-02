import Combine

public extension Publisher {
  func replaceNil<T>(
    with publisher: AnyPublisher<T, Self.Failure>
  ) -> AnyPublisher<T, Self.Failure>
  where Self.Output == T? {
    flatMap { output -> AnyPublisher<T, Self.Failure> in
      if let output = output {
        return Just(output)
          .setFailureType(to: Self.Failure.self)
          .eraseToAnyPublisher()
      } else {
        return publisher
      }
    }
    .eraseToAnyPublisher()
  }
}
