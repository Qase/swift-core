#if DEBUG
import Combine
import Foundation

public enum NetworkPath {
  case available
  case unavailable

  var isAvailable: Bool { self == .available }
}

public extension NetworkMonitorClient {
  static func mock(
    isNetworkAvailable: AnyPublisher<Bool, Never> = .fatalError
  ) -> Self {
    .init(isNetworkAvailable: isNetworkAvailable)
  }

  static func mockJust<S: Scheduler>(
    value: NetworkPath,
    delayedFor time: S.SchedulerTimeType.Stride,
    scheduler: S
  ) -> Self {
    mock(
      isNetworkAvailable: Just(value.isAvailable)
        .delay(for: time, scheduler: scheduler)
        .eraseToAnyPublisher()
    )
  }

  static func mockSequence<S: Scheduler>(
    withValues values: [NetworkPath],
    onScheduler scheduler: S,
    every timeDelay: S.SchedulerTimeType.Stride
  ) -> Self {
    mock(
      isNetworkAvailable: values.publisher
        .flatMap(maxPublishers: .max(1)) { Just($0.isAvailable).delay(for: timeDelay, scheduler: scheduler) }
        .eraseToAnyPublisher()
    )
  }
}
#endif
