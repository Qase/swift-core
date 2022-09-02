import Combine
import XCTest

final class Publisher_flatMapResultTests: XCTestCase {
  struct TestError: Error, Equatable {}

  var subscriptions = Set<AnyCancellable>()

  func test_upstream_value_flatMapResult_generates_value() {
    var valueReceived = false
    var finishedReceived = false

    Just(5)
      .setFailureType(to: TestError.self)
      .flatMapResult { number -> Result<Int, TestError> in
      .success(number + 1)
      }
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case let .failure(error):
            XCTFail("Unexpected event received - error: (\(error).")
          case .finished:
            finishedReceived = true
          }
        },
        receiveValue: { value in
          XCTAssertEqual(value, 6)
          valueReceived = true
        }
      )
      .store(in: &subscriptions)

    XCTAssertTrue(valueReceived)
    XCTAssertTrue(finishedReceived)
  }

  func test_upstream_value_flatMapResult_generates_failure() {
    var errorReceived = false

    Just(5)
      .setFailureType(to: TestError.self)
      .flatMapResult { _ -> Result<Int, TestError> in
      .failure(TestError())
      }
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case let .failure(error):
            XCTAssertEqual(error, TestError())
            errorReceived = true
          case .finished:
            XCTFail("Unexpected event received - finished.")
          }
        },
        receiveValue: { value in
          XCTFail("Unexpected event received - value: \(value).")
        }
      )
      .store(in: &subscriptions)

    XCTAssertTrue(errorReceived)
  }

  func test_upstream_error_flatMapResult_skipped() {
    var flatMapCalled = false
    var errorReceived = false

    Fail<Int, TestError>(error: TestError())
      .flatMapResult { number -> Result<Int, TestError> in
        flatMapCalled = true
        return .success(number + 1)
      }
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case let .failure(error):
            XCTAssertEqual(flatMapCalled, false)
            XCTAssertEqual(error, TestError())
            errorReceived = true
          case .finished:
            XCTFail("Unexpected event received - finished.")
          }
        },
        receiveValue: { value in
          XCTFail("Unexpected event received - value: \(value).")
        }
      )
      .store(in: &subscriptions)

    XCTAssertFalse(flatMapCalled)
    XCTAssertTrue(errorReceived)
  }
}
