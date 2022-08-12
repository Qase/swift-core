import Combine
import ErrorReporting
import XCTest

final class ErrorReportingTests: XCTestCase {
  struct TestError1: ErrorReporting, Equatable {
    var stackID: UUID
    var underlyingError: ErrorReporting?

    public var causeDescription: String { "" }

    init(stackID: UUID = UUID(), underlyingError: ErrorReporting? = nil) {
      self.stackID = stackID
      self.underlyingError = underlyingError
    }

    static func == (lhs: ErrorReportingTests.TestError1, rhs: ErrorReportingTests.TestError1) -> Bool {
      lhs.comparableDescription.description == rhs.comparableDescription.description
    }
  }

  struct TestError2: ErrorReporting {
    enum Cause: String, CustomStringConvertible {
      case errorCause1
      case errorCause2

      var description: String { self.rawValue }
    }

    let cause: Cause
    var stackID: UUID
    var underlyingError: ErrorReporting?

    var causeDescription: String { cause.description }

    init(stackID: UUID = UUID(), cause: Cause = .errorCause1) {
      self.stackID = stackID
      self.cause = cause
    }
  }

  var subscriptions = Set<AnyCancellable>()

  override func tearDown() {
    subscriptions = []

    super.tearDown()
  }

  func test_setChaingedProperties_method() {
    let error1 = TestError1(stackID: UUID(uuidString: "ffeac012-9911-11eb-a8b3-0242ac130003")!)
    var error2 = TestError2()

    error2.setProperties(from: error1)

    XCTAssertEqual(error1.stackID, error2.stackID)
    XCTAssertNotNil(error2.underlyingError as? TestError1)

    XCTAssertEqual(error2.underlyingError as! TestError1, error1)
  }

  func test_mapErrorReportable_simple_Publisher_extension() {
    let expectation = self.expectation(description: "")

    let error1 = TestError1(stackID: UUID(uuidString: "ffeac012-9911-11eb-a8b3-0242ac130003")!)

    Fail<Void, TestError1>(error: error1)
      .mapErrorReporting(to: TestError2())
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case let .failure(error2):
            XCTAssertEqual(error1.stackID, error2.stackID)
            XCTAssertNotNil(error2.underlyingError as? TestError1)
            XCTAssertEqual(error2.underlyingError as! TestError1, error1)
            expectation.fulfill()
          case .finished:
            XCTFail("Unexpected event received.")
          }
        },
        receiveValue: { _ in
          XCTFail("Unexpected event received.")
        }
      )
      .store(in: &subscriptions)

    waitForExpectations(timeout: 0.1)
  }

  func test_error_equality() {
    let stackID = UUID(uuidString: "ffeac012-9911-11eb-a8b3-0242ac130003")!

    let test1 = TestError1(
      stackID: stackID,
      underlyingError: TestError2(
        stackID: stackID,
        cause: .errorCause1
      )
    )

    var test2 = TestError1(
      stackID: stackID,
      underlyingError: TestError2(
        stackID: stackID,
        cause: .errorCause1
      )
    )

    XCTAssertEqual(test1, test2)

    test2.underlyingError = TestError2(
      stackID: stackID,
      cause: .errorCause2
    )

    XCTAssertNotEqual(test1, test2)

    test2.underlyingError = TestError2(
      stackID: UUID(uuidString: "ffeac012-9911-11eb-a8b3-0242ac130000")!,
      cause: .errorCause1
    )

    XCTAssertEqual(test1, test2)
  }

  func test_firstOfType_should_include_self() {
    let sut = TestError1(
      underlyingError: TestError1(
        underlyingError: TestError2()
      )
    )

    let result = sut.first(ofType: TestError1.self)

    XCTAssertEqual(result, sut)
  }

  func test_firstOfType_should_find_first_suitable_error() {
    let sut = TestError1(
      underlyingError: TestError1(
        underlyingError: TestError2()
      )
    )

    let result = sut.first(ofType: TestError2.self)

    XCTAssertNotNil(result)
  }

  func test_error_stack_contains_defined_error() {
    let sut = TestError1(
      underlyingError: TestError1(
        underlyingError: TestError2()
      )
    )

    let result = sut.contains(ofType: TestError2.self)

    XCTAssertNotNil(result)
  }

  func test_error_stack_does_not_contain_defined_error() {
    let sut = TestError1(
      underlyingError: TestError1(
        underlyingError: TestError1()
      )
    )

    let result = sut.contains(ofType: TestError2.self)

    XCTAssertNotNil(result)
  }
}
