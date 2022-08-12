import Combine
import CombineExtensions
import CombineSchedulers
import XCTest

class Publisher_flatMapFirstTests: XCTestCase {
  var cancellables: Set<AnyCancellable>!

  override func setUp() {
    super.setUp()

    cancellables = []
  }

  struct TestError: Error, Equatable {}

  func test_flatMapFirst_single_publisher_single_flatMap() {
    let testScheduler = DispatchQueue.test

    var innerPublisherSubscriptionCount = 0
    var innerPublisherCompletionCount = 0
    var isUpstreamCompleted = false

    Just("").setFailureType(to: Never.self)
      .delay(for: 1, scheduler: testScheduler)
      .flatMapFirst { _ -> AnyPublisher<Date, Never> in
        return Just(Date())
          .delay(for: 1, scheduler: testScheduler)
          .handleEvents(
            receiveSubscription: { _ in innerPublisherSubscriptionCount += 1 },
            receiveCompletion: { _ in innerPublisherCompletionCount += 1 }
          )
          .eraseToAnyPublisher()
      }
      .sink(
        receiveCompletion: { completion in
          if case .finished = completion {
            isUpstreamCompleted = true
          }
        },
        receiveValue: { _ in }
      )
      .store(in: &cancellables)

    testScheduler.advance(by: 2)

    XCTAssertEqual(innerPublisherSubscriptionCount, 1)
    XCTAssertEqual(innerPublisherCompletionCount, 1)
    XCTAssertTrue(isUpstreamCompleted)
  }

  func test_flatMapFirst_error_upstream_skipping_flatMap() {
    let testScheduler = DispatchQueue.test

    var innerPublisherSubscriptionCount = 0
    var isUpstreamCompleted = false

    Fail(error: TestError()).eraseToAnyPublisher()
      .delay(for: 1, scheduler: testScheduler)
      .flatMapFirst { (_: String) -> AnyPublisher<Date, TestError> in
        return Just(Date()).setFailureType(to: TestError.self)
          .handleEvents(receiveSubscription: { _ in innerPublisherSubscriptionCount += 1 })
          .eraseToAnyPublisher()
      }
      .sink(
        receiveCompletion: { completion in
          if case let .failure(error) = completion {
            XCTAssertEqual(error, TestError())
            isUpstreamCompleted = true
          }
        },
        receiveValue: { _ in }
      )
      .store(in: &cancellables)

    testScheduler.advance(by: 1)

    XCTAssertEqual(innerPublisherSubscriptionCount, 0)
    XCTAssertTrue(isUpstreamCompleted)
  }

  func test_flatMapFirst_multiple_publishers_handled_accordingly() {
    let testScheduler = DispatchQueue.test

    var innerPublisherSubscriptionCount = 0
    var innerPublisherCompletionCount = 0
    var isUpstreamCompleted = false

    testScheduler.timerPublisher(every: 1)
      .autoconnect()
      .prefix(100)
      .flatMapFirst { _ -> AnyPublisher<Date, Never> in
        return Just(Date())
          .handleEvents(
            receiveSubscription: { _ in innerPublisherSubscriptionCount += 1 },
            receiveCompletion: { _ in innerPublisherCompletionCount += 1 }
          )
          .delay(for: 10, scheduler: testScheduler)
          .eraseToAnyPublisher()
      }
      .sink(
        receiveCompletion: { completion in
          if case .finished = completion {
            isUpstreamCompleted = true
          }
        },
        receiveValue: { _ in }
      )
      .store(in: &cancellables)

    testScheduler.advance(by: 110)

    XCTAssertEqual(innerPublisherSubscriptionCount, 10)
    XCTAssertEqual(innerPublisherCompletionCount, 10)
    XCTAssertTrue(isUpstreamCompleted)
  }

  func test_flatMapFirst_race_condition_caused_by_materialized_publisher() {
    let testScheduler = DispatchQueue.test

    let eventSubject = PassthroughSubject<Void, Never>()
    let successsSubject = PassthroughSubject<Void, Never>()
    let failureSubject = PassthroughSubject<TestError, Never>()

    var eventSubscriptionCount = 0
    var eventCompletionCount = 0
    var eventCancelCount = 0

    eventSubject
      .flatMapFirst { _ in
        Fail<Void, TestError>(error: TestError())
          .delay(for: 1, scheduler: testScheduler)
          .materialize()
          .handleEvents(
            receiveSubscription: { _ in eventSubscriptionCount += 1 },
            receiveCompletion: { _ in eventCompletionCount += 1 },
            receiveCancel: { eventCancelCount += 1 }
          )
          .eraseToAnyPublisher()
      }
      .sink(
        receiveValue: { event in
          switch event {
          case .value:
            successsSubject.send(())
          case let .failure(error):
            failureSubject.send(error)
          case .finished:
            ()
          }
        }
      )
      .store(in: &cancellables)

    let job: AnyPublisher<Void, TestError> = {
      let triggerEvent = Publishers.Create<Void, TestError> { subscriber in
        eventSubject.send(())

        subscriber.send(())
        subscriber.send(completion: .finished)

        return AnyCancellable {}
      }

      let response = Publishers.Amb(
        first: successsSubject.setFailureType(to: TestError.self).eraseToAnyPublisher(),
        second: failureSubject.flatMap { Fail(error: $0).eraseToAnyPublisher() }
      )

      return Publishers.Zip(triggerEvent, response)
        .map { _ in }
        .eraseToAnyPublisher()
    }()

    var errorReceivedCount = 0

    job
      .retry(2)
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            XCTFail("Unexpected vevent - finished.")
          case let .failure(error):
            XCTAssertEqual(error, TestError())
            errorReceivedCount += 1
          }
        },
        receiveValue: { value in
          XCTFail("Unexpected event - value: \(value).")
        }
      )
      .store(in: &cancellables)

    testScheduler.advance(by: 6)

    XCTAssertEqual(eventSubscriptionCount, 3)
    XCTAssertEqual(eventCancelCount, 2)
    XCTAssertEqual(eventCompletionCount, 1)

    XCTAssertEqual(errorReceivedCount, 1)
  }
}
