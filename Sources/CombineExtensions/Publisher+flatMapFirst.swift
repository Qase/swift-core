import Combine
import Foundation

// MARK: - Publisher<Output, Failure: Error> + flatMapFirst

public extension Publisher {
  func flatMapFirst<P: Publisher>(
    _ transform: @escaping (Output) -> P
  ) -> AnyPublisher<P.Output, P.Failure> where Self.Failure == P.Failure {
    flatMapFirst(allowNextOnEvent: { _ in false }, transform: transform)
  }

  func flatMapFirst<P: Publisher, Output, Failure: Error>(
    _ transform: @escaping (Self.Output) -> P
  ) -> AnyPublisher<P.Output, P.Failure> where Self.Failure == P.Failure, P.Output == Event<Output, Failure> {
    // NOTE: Due to a possible race condition, the flatMapFirst must enable next upstream publisher to execute
    // already on Event.failure and not on the actual completion of the just executing publisher.
    flatMapFirst(allowNextOnEvent: { $0.failure != nil }, transform: transform)
  }

  private func flatMapFirst<P: Publisher>(
    allowNextOnEvent: @escaping (P.Output) -> Bool,
    transform: @escaping (Output) -> P
  ) -> AnyPublisher<P.Output, P.Failure> where Self.Failure == P.Failure {
    var isRunning = false
    let lock = NSRecursiveLock()

    func set(isRunning newValue: Bool) {
      defer { lock.unlock() }
      lock.lock()

      isRunning = newValue
    }

    return self
      .filter { _ in !isRunning }
      .map { output in
        transform(output)
          .handleEvents(
            receiveSubscription: { _ in
              set(isRunning: true)
            },
            receiveOutput: { value in
              if allowNextOnEvent(value) {
                set(isRunning: false)
              }
            },
            receiveCompletion: { _ in
              set(isRunning: false)
            },
            receiveCancel: {
              set(isRunning: false)
            }
          )
      }
      .switchToLatest()
      .eraseToAnyPublisher()
  }
}

// MARK: - Publisher<Output, Never> + flatMapFirst

public extension Publisher where Failure == Never {
  func flatMapFirst<P: Publisher>(
    _ transform: @escaping (Output) -> P
  ) -> AnyPublisher<P.Output, P.Failure> {
    setFailureType(to: P.Failure.self)
      .flatMapFirst(transform)
  }

  func flatMapFirst<P: Publisher, Output, Failure: Error>(
    _ transform: @escaping (Self.Output) -> P
  ) -> AnyPublisher<P.Output, P.Failure> where P.Output == Event<Output, Failure> {
    setFailureType(to: P.Failure.self)
      .flatMapFirst(transform)
  }
}
