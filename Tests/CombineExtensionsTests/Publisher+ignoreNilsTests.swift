import Combine
import CombineSchedulers
import XCTest

class Publisher_ignoreNilsTests: XCTestCase {
  private var sut: PassthroughSubject<Int?, IgnoreNilsError>!
  private var cancellables: Set<AnyCancellable>!

  override func setUp() {
    super.setUp()

    sut = .init()
    cancellables = []
  }

  func test_non_nil_value_should_be_passed() {
    let expectation = expectation(description: #function)
    let expectedValue = 42

    sut
      .ignoreNils()
      .sink(
        receiveCompletion: { _ in
          XCTFail("SUT should not complete.")
        },
        receiveValue: { receivedValue in
          XCTAssertEqual(receivedValue, expectedValue)
          expectation.fulfill()
        }
      )
      .store(in: &cancellables)

    sut.send(nil)
    sut.send(expectedValue)

    waitForExpectations(timeout: 0.1)
  }

  func test_finish_should_be_passed_down() {
    let expectation = expectation(description: #function)

    sut
      .ignoreNils()
      .sink(
        receiveCompletion: { completion in
          XCTAssertEqual(completion, .finished)
          expectation.fulfill()
        },
        receiveValue: { receivedValue in
          XCTFail("SUT should not receive a value: \(receivedValue).")
        }
      )
      .store(in: &cancellables)

    sut.send(nil)
    sut.send(completion: .finished)

    waitForExpectations(timeout: 0.1)
  }

  func test_error_should_be_passed_down() {
    let expectation = expectation(description: #function)

    sut
      .ignoreNils()
      .sink(
        receiveCompletion: { completion in
          XCTAssertEqual(completion, .failure(.failed))
          expectation.fulfill()
        },
        receiveValue: { receivedValue in
          XCTFail("SUT should not receive a value: \(receivedValue).")
        }
      )
      .store(in: &cancellables)

    sut.send(nil)
    sut.send(completion: .failure(.failed))

    waitForExpectations(timeout: 0.1)
  }
}

private enum IgnoreNilsError: Error {
  case failed
}
