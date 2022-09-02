import Combine
import CombineSchedulers
import XCTest

class Publisher_replaceNilTests: XCTestCase {
  var cancellables: Set<AnyCancellable>!

  override func setUp() {
    super.setUp()

    cancellables = []
  }

  func test_replaceNil_should_not_subscribe_on_provided_subscriber_on_non_nil_value() {
    let onNilSubscribedExpectation = expectation(description: #function)
    onNilSubscribedExpectation.isInverted = true
    let valueExpectation = expectation(description: "Value received")

    let subject: PassthroughSubject<String?, Never> = .init()
    let expectedValue = "Expected Value"
    let unexpectedValue = "Unexpected Value"

    let onNilPublisher = Just(unexpectedValue)
      .handleEvents(
        receiveSubscription: { _ in
          onNilSubscribedExpectation.fulfill()
        }
      )
      .eraseToAnyPublisher()

    subject
      .replaceNil(with: onNilPublisher)
      .sink { value in
        guard value == expectedValue else {
          XCTFail("Received unexpected value")
          return
        }

        valueExpectation.fulfill()
      }
      .store(in: &cancellables)

    subject.send(expectedValue)

    waitForExpectations(timeout: 0.1)
  }

  func test_replaceNil_should_subscribe_on_provided_subscriber_on_nil_value() {
    let onNilSubscribedExpectation = expectation(description: #function)
    let valueExpectation = expectation(description: "Value received")

    let subject: PassthroughSubject<String?, Never> = .init()
    let expectedValue = "Expected Value"

    let onNilPublisher = Just(expectedValue)
      .handleEvents(
        receiveSubscription: { _ in
          onNilSubscribedExpectation.fulfill()
        }
      )
      .eraseToAnyPublisher()

    subject
      .replaceNil(with: onNilPublisher)
      .sink { value in
        guard value == expectedValue else {
          XCTFail("Received unexpected value")
          return
        }

        valueExpectation.fulfill()
      }
      .store(in: &cancellables)

    subject.send(nil)

    waitForExpectations(timeout: 0.1)
  }
}
