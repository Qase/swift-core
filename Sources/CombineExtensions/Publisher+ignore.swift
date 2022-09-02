import Combine

public extension Publisher {
  func ignoreFailure<NewFailure>(
    setFailureType: NewFailure.Type
  ) -> AnyPublisher<Output, NewFailure> {
    self
      .catch { _ in Empty() }
      .setFailureType(to: NewFailure.self)
      .eraseToAnyPublisher()
  }

  func ignoreFailure() -> AnyPublisher<Output, Never> {
    self
      .catch { _ in Empty() }
      .setFailureType(to: Never.self)
      .eraseToAnyPublisher()
  }
}
