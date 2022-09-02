import Combine
import XCTest

final class Publisher_loggerTests: XCTestCase {
  var cancellables: Set<AnyCancellable>!

  override func setUp() {
    super.setUp()

    cancellables = []
  }

  func test_when_call_log_in_reactive_stream_with_all_values_then_all_messages_are_logged() {
    let expectedValue: String = "test value"

    var loggedMessages: [String] = []

    Just(expectedValue)
      .log(
        logger: { loggedMessages.append($0) },
        loggingLifecycle: true,
        loggingCompletion: true,
        loggingValues: true
      )
      .sink(receiveValue: { _ in })
      .store(in: &cancellables)

    XCTAssertEqual(loggedMessages[0], "receive subscription: (Just)")
    XCTAssertEqual(loggedMessages[1], "receive request: (unlimited)")
    XCTAssertEqual(loggedMessages[2], "receive value: (\(expectedValue))")
    XCTAssertEqual(loggedMessages[3], "receive completion: finished")
    XCTAssertEqual(loggedMessages.count, 4)
  }

  func test_when_call_log_in_reactive_stream_with_completion_only_then_only_completion_is_logged() {
    let expectedValue: String = "test value"

    var loggedMessages: [String] = []

    Just(expectedValue)
      .log(
        logger: { loggedMessages.append($0) },
        loggingLifecycle: false,
        loggingCompletion: true,
        loggingValues: false
      )
      .sink(receiveValue: { _ in })
      .store(in: &cancellables)

    XCTAssertEqual(loggedMessages[0], "receive completion: finished")
    XCTAssertEqual(loggedMessages.count, 1)
  }

  func test_when_call_log_in_reactive_stream_with_lifecycle_messages_only_then_only_lifecycle_messages_are_logged() {
    let expectedValue: String = "test value"

    var loggedMessages: [String] = []

    Just(expectedValue)
      .log(
        logger: { loggedMessages.append($0) },
        loggingLifecycle: true,
        loggingCompletion: false,
        loggingValues: false
      )
      .sink(receiveValue: { _ in })
      .store(in: &cancellables)

    XCTAssertEqual(loggedMessages[0], "receive subscription: (Just)")
    XCTAssertEqual(loggedMessages[1], "receive request: (unlimited)")
    XCTAssertEqual(loggedMessages.count, 2)
  }
}
