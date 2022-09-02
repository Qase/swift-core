#if !os(watchOS)
import Combine
import CombineExtensions
import XCTest

// Source: https://github.com/CombineCommunity/CombineExt

class Publisher_createTests: XCTestCase {
  enum MyError: Swift.Error {
    case failure
  }

  var subscription: AnyCancellable!

  private var completion: Subscribers.Completion<MyError>?
  private var values = [String]()
  private var canceled = false
  private let allValues = ["Hello", "World", "What's", "Up?"]

  override func setUp() {
    canceled = false
    values = []
    completion = nil
  }

  func testUnlimitedDemandFinished() {
    let subscriber = makeSubscriber(demand: .unlimited)
    let publisher = makePublisher(fail: false)

    publisher.subscribe(subscriber)

    XCTAssertEqual(completion, .finished)
    XCTAssertTrue(canceled)
    XCTAssertEqual(values, allValues)
  }

  func testLimitedDemandFinished() {
    let subscriber = makeSubscriber(demand: .max(2))

    let publisher = AnyPublisher<String, MyError> { subscriber in
      self.allValues.forEach { subscriber.send($0) }
      subscriber.send(completion: .finished)

      return AnyCancellable { [weak self] in
        self?.canceled = true
      }
    }

    publisher.subscribe(subscriber)

    XCTAssertEqual(completion, .finished)
    XCTAssertTrue(canceled)
    XCTAssertEqual(values, Array(allValues.prefix(2)))
  }

  func testNoDemandFinished() {
    let subscriber = makeSubscriber(demand: .none)
    let publisher = makePublisher(fail: false)

    publisher.subscribe(subscriber)

    XCTAssertEqual(completion, .finished)
    XCTAssertTrue(canceled)
    XCTAssertTrue(values.isEmpty)
  }

  func testUnlimitedDemandError() {
    let subscriber = makeSubscriber(demand: .unlimited)
    let publisher = makePublisher(fail: true)

    publisher.subscribe(subscriber)

    XCTAssertEqual(completion, .failure(MyError.failure))
    XCTAssertTrue(canceled)
    XCTAssertEqual(values, allValues)
  }

  func testLimitedDemandError() {
    let subscriber = makeSubscriber(demand: .max(2))
    let publisher = makePublisher(fail: true)

    publisher.subscribe(subscriber)

    XCTAssertEqual(completion, .failure(MyError.failure))
    XCTAssertTrue(canceled)
    XCTAssertEqual(values, Array(allValues.prefix(2)))
  }

  func testNoDemandError() {
    let subscriber = makeSubscriber(demand: .none)
    let publisher = makePublisher(fail: true)

    publisher.subscribe(subscriber)

    XCTAssertEqual(completion, .failure(MyError.failure))
    XCTAssertTrue(canceled)
    XCTAssertTrue(values.isEmpty)
  }

  var cancelable: Cancellable?

  func testManualCancelation() {
    let publisher = AnyPublisher<String, Never>.create { _ in
      return AnyCancellable { [weak self] in self?.canceled = true }
    }

    cancelable = publisher.sink { _ in }
    XCTAssertFalse(canceled)
    cancelable?.cancel()
    XCTAssertTrue(canceled)
  }
}

// MARK: - Private Helpers
private extension Publisher_createTests {
  func makePublisher(fail: Bool = false) -> AnyPublisher<String, Publisher_createTests.MyError> {
    AnyPublisher<String, MyError>.create { subscriber in
      self.allValues.forEach { subscriber.send($0) }
      subscriber.send(completion: fail ? .failure(MyError.failure) : .finished)

      return AnyCancellable { [weak self] in
        self?.canceled = true
      }
    }
    .eraseToAnyPublisher()
  }

  func makeSubscriber(demand: Subscribers.Demand) -> AnySubscriber<String, Publisher_createTests.MyError> {
    return AnySubscriber(
      receiveSubscription: { subscription in
        XCTAssertEqual("\(subscription)", "Create.Subscription<String, MyError>")
        subscription.request(demand)
      },
      receiveValue: { value in
        self.values.append(value)
        return .none
      },
      receiveCompletion: { finished in
        self.completion = finished
      })
  }
}
#endif
