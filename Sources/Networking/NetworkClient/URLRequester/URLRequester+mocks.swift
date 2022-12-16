import Combine
import Foundation

extension URLRequester {
  static func mock(
    request: @escaping RequestFunction = { _ in { _ in fatalError("Not implemented!") } }
  ) -> Self {
    .init(request: request)
  }

  static func successMock<S: Scheduler>(
    withResponse response: (Data, URLResponse),
    delayedFor time: S.SchedulerTimeType.Stride,
    scheduler: S
  ) -> Self {
    .init { _ in { _ in
        Just(response)
          .setFailureType(to: URLError.self)
          .delay(for: time, scheduler: scheduler)
          .eraseToAnyPublisher()
      }
    }
  }

  static func failureMock<S: Scheduler>(
    withError error: URLError,
    delayedFor time: S.SchedulerTimeType.Stride,
    scheduler: S
  ) -> Self {
    .init { _ in { _ in
        Fail<(data: Data, response: URLResponse), URLError>(error: error)
          .delay(for: time, scheduler: scheduler)
          .eraseToAnyPublisher()
      }
    }
  }
}
