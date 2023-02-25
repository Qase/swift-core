import Combine
@testable import Networking
import RequestBuilder
import XCTest

extension NetworkClientTests {
  func test_clientError_failure() {
    let httpResponse: HTTPURLResponse = HTTPURLResponse(
      url: .mock,
      statusCode: 402,
      httpVersion: nil,
      headerFields: [String: String]()
    )!

    networkClient = NetworkClient(
      urlRequester: .successMock(withResponse: (Data(), httpResponse), delayedFor: 1, scheduler: testScheduler),
      networkMonitorClient: .mockSequence(withValues: [.available], onScheduler: testScheduler, every: 1),
      logUUID: UUID.init,
      loggerClient: .mock()
    )

    var errorReceived = false

    let response: AnyPublisher<(headers: [HTTPHeader], body: Data), NetworkError> = networkClient.request(.mock)

    response
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            XCTFail("Unexpected event - finished.")
          case let .failure(error):
            switch error.cause {
            case let .clientError(statusCode: statusCode) where statusCode == 402:
              errorReceived = true
            default:
              XCTFail("Unexpected event - failure: \(error.cause).")
            }
          }
        },
        receiveValue: { body in
          XCTFail("Unexpect event - element: \(body).")
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 2)

    XCTAssertTrue(errorReceived)
  }

  func test_serverError_failure() {
    let httpResponse: HTTPURLResponse = HTTPURLResponse(
      url: .mock,
      statusCode: 500,
      httpVersion: nil,
      headerFields: [String: String]()
    )!

    networkClient = NetworkClient(
      urlRequester: .successMock(withResponse: (Data(), httpResponse), delayedFor: 1, scheduler: testScheduler),
      networkMonitorClient: .mockSequence(withValues: [.available], onScheduler: testScheduler, every: 1),
      logUUID: UUID.init,
      loggerClient: .mock()
    )

    var errorReceived = false

    let response: AnyPublisher<(headers: [HTTPHeader], body: Data), NetworkError> = networkClient.request(.mock)

    response
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            XCTFail("Unexpected event - finished.")
          case let .failure(error):
            switch error.cause {
            case let .serverError(statusCode: statusCode) where statusCode == 500:
              errorReceived = true
            default:
              XCTFail("Unexpected event - failure: \(error.cause).")
            }
          }
        },
        receiveValue: { body in
          XCTFail("Unexpect event - element: \(body).")
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 2)

    XCTAssertTrue(errorReceived)
  }

  func test_unauthorized_failure() {
    let httpResponse: HTTPURLResponse = HTTPURLResponse(
      url: .mock,
      statusCode: 401,
      httpVersion: nil,
      headerFields: [String: String]()
    )!

    networkClient = NetworkClient(
      urlRequester: .successMock(withResponse: (Data(), httpResponse), delayedFor: 1, scheduler: testScheduler),
      networkMonitorClient: .mockSequence(withValues: [.available], onScheduler: testScheduler, every: 1),
      logUUID: UUID.init,
      loggerClient: .mock()
    )

    var errorReceived = false

    let response: AnyPublisher<(headers: [HTTPHeader], body: Data), NetworkError> = networkClient.request(.mock)

    response
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            XCTFail("Unexpected event - finished.")
          case let .failure(error):
            switch error.cause {
            case .unauthorized:
              errorReceived = true
            default:
              XCTFail("Unexpected event - failure: \(error.cause).")
            }
          }
        },
        receiveValue: { body in
          XCTFail("Unexpect event - element: \(body).")
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 2)

    XCTAssertTrue(errorReceived)
  }

  func test_URLError_failure_response() {
    networkClient = NetworkClient(
      urlRequester: .failureMock(withError: URLError(.badServerResponse), delayedFor: 1, scheduler: testScheduler),
      networkMonitorClient: .mockSequence(withValues: [.available], onScheduler: testScheduler, every: 1),
      logUUID: UUID.init,
      loggerClient: .mock()
    )

    var errorReceived = false

    let response: AnyPublisher<(headers: [HTTPHeader], body: Data), NetworkError> = networkClient.request(.mock)

    response
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            XCTFail("Unexpected event - finished.")
          case let .failure(error):
            switch error.cause {
            case .urlError(URLError(.badServerResponse)):
              errorReceived = true
            default:
              XCTFail("Unexpected event - failure: \(error.cause).")
            }
          }
        },
        receiveValue: { body in
          XCTFail("Unexpect event - element: \(body).")
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 2)

    XCTAssertTrue(errorReceived)
  }

  func test_invalidResponse_failure_response() {
    let urlResponse = URLResponse(url: .mock, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)

    networkClient = NetworkClient(
      urlRequester: .successMock(withResponse: (Data(), urlResponse), delayedFor: 1, scheduler: testScheduler),
      networkMonitorClient: .mockSequence(withValues: [.available], onScheduler: testScheduler, every: 1),
      logUUID: UUID.init,
      loggerClient: .mock()
    )

    var errorReceived = false

    let response: AnyPublisher<(headers: [HTTPHeader], body: Data), NetworkError> = networkClient.request(.mock)

    response
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            XCTFail("Unexpected event - finished.")
          case let .failure(error):
            switch error.cause {
            case .invalidResponse:
              errorReceived = true
            default:
              XCTFail("Unexpected event - failure: \(error.cause).")
            }
          }
        },
        receiveValue: { body in
          XCTFail("Unexpect event - element: \(body).")
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 2)
    XCTAssertTrue(errorReceived)
  }

  func test_noConnection_failure_response() {
    let urlResponse = URLResponse(url: .mock, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)

    networkClient = NetworkClient(
      urlRequester: .successMock(withResponse: (Data(), urlResponse), delayedFor: 1, scheduler: testScheduler),
      networkMonitorClient: .mockSequence(withValues: [.unavailable], onScheduler: testScheduler, every: 1),
      logUUID: UUID.init,
      loggerClient: .mock()
    )

    var errorReceived = false

    let response: AnyPublisher<(headers: [HTTPHeader], body: Data), NetworkError> = networkClient.request(.mock)

    response
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            XCTFail("Unexpected event - finished.")
          case let .failure(error):
            switch error.cause {
            case .noConnection:
              errorReceived = true
            default:
              XCTFail("Unexpected event - failure: \(error.cause).")
            }
          }
        },
        receiveValue: { body in
          XCTFail("Unexpect event - element: \(body).")
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 1)

    XCTAssertTrue(errorReceived)
  }

  func test_jsonDecodingError_failure_response() {
    let httpResponse: HTTPURLResponse = HTTPURLResponse(
      url: .mock,
      statusCode: 200,
      httpVersion: nil,
      headerFields: [:]
    )!

    let data = "invalid-data".data(using: .utf8)!

    networkClient = NetworkClient(
      urlRequester: .successMock(withResponse: (data, httpResponse), delayedFor: 1, scheduler: testScheduler),
      networkMonitorClient: .mockSequence(withValues: [.available], onScheduler: testScheduler, every: 1),
      logUUID: UUID.init,
      loggerClient: .mock()
    )

    var errorReceived = false

    let response: AnyPublisher<User, NetworkError> = networkClient.request(.mock)

    response
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            XCTFail("Unexpected event - finished.")
          case let .failure(error):
            switch error.cause {
            case .jsonDecodingError:
              errorReceived = true
            default:
              XCTFail("Unexpected event - failure: \(error.cause).")
            }
          }
        },
        receiveValue: { body in
          XCTFail("Unexpect event - element: \(body).")
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 2)

    XCTAssertTrue(errorReceived)
  }

  func test_request_and_response_are_logged_with_the_same_uuid() {
    let expectedUUID = "DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF"
    var uuidCalled = false
    var logURLRequestCalled = false
    var logURLResponseCalled = false

    let uuid = { () -> UUID in
      uuidCalled = true
      return UUID(uuidString: expectedUUID)!
    }

    let urlResponse = URLResponse(url: .mock, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)

    networkClient = NetworkClient(
      urlRequester: .successMock(withResponse: (Data(), urlResponse), delayedFor: 1, scheduler: testScheduler),
      networkMonitorClient: .mockSequence(withValues: [.available], onScheduler: testScheduler, every: 1),
      logUUID: uuid,
      loggerClient: .mock(
        logRequest: { uuid, _ in
          logURLRequestCalled = true
          XCTAssertEqual(uuid.uuidString, expectedUUID)
        },
        logURLResponse: { uuid, _, _ in
          logURLResponseCalled = true
          XCTAssertEqual(uuid.uuidString, expectedUUID)
        },
        logHTTPURLResponse: { _, _, _ in
          XCTFail("logHTTPURLResponse should not be called when HTTPURLResponse is unvailable")
        }
      )
    )

    let response: AnyPublisher<(headers: [HTTPHeader], object: User), NetworkError> = networkClient.request(.mock)

    response
      .sink(
        receiveCompletion: { _ in },
        receiveValue: { _ in }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 2)

    XCTAssertTrue(uuidCalled)
    XCTAssertTrue(logURLRequestCalled)
    XCTAssertTrue(logURLResponseCalled)
  }

  func test_requestID_is_assigned_from_response() {
    let expectedRequestID = "expected-request-id"
    var receivedRequestID: String?

    let httpResponse: HTTPURLResponse = HTTPURLResponse(
      url: .mock,
      statusCode: 500,
      httpVersion: nil,
      headerFields: [
        HTTPHeaderName.requestID.rawValue: expectedRequestID
      ]
    )!

    networkClient = NetworkClient(
      urlRequester: .successMock(withResponse: (Data(), httpResponse), delayedFor: 1, scheduler: testScheduler),
      networkMonitorClient: .mockSequence(withValues: [.available], onScheduler: testScheduler, every: 1),
      logUUID: UUID.init,
      loggerClient: .mock()
    )

    let response: AnyPublisher<(headers: [HTTPHeader], body: Data), NetworkError> = networkClient.request(.mock)

    response
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            XCTFail("Unexpected event - finished.")
          case let .failure(error):
            receivedRequestID = error.requestID
          }
        },
        receiveValue: { body in
          XCTFail("Unexpect event - element: \(body).")
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 2)
    XCTAssertEqual(receivedRequestID, expectedRequestID)
  }

  func test_timeout_failure_response() {
    let httpResponse: HTTPURLResponse = HTTPURLResponse(
      url: .mock,
      statusCode: 408,
      httpVersion: nil,
      headerFields: [String: String]()
    )!

    networkClient = NetworkClient(
      urlRequester: .successMock(withResponse: (Data(), httpResponse), delayedFor: 1, scheduler: testScheduler),
      networkMonitorClient: .mockSequence(withValues: [.available], onScheduler: testScheduler, every: 1),
      logUUID: UUID.init,
      loggerClient: .mock()
    )

    var errorReceived = false

    let response: AnyPublisher<(headers: [HTTPHeader], body: Data), NetworkError> = networkClient.request(.mock)

    response
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            XCTFail("Unexpected event - finished.")
          case let .failure(error):
            switch error.cause {
            case .timeout:
              errorReceived = true
            default:
              XCTFail("Unexpected event - failure: \(error.cause).")
            }
          }
        },
        receiveValue: { body in
          XCTFail("Unexpect event - element: \(body).")
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 2)

    XCTAssertTrue(errorReceived)
  }

  func test_timeout_failure() {
    networkClient = NetworkClient(
      urlRequester: .failureMock(withError: .init(.timedOut), delayedFor: 1, scheduler: testScheduler),
      networkMonitorClient: .mockSequence(withValues: [.available], onScheduler: testScheduler, every: 1),
      logUUID: UUID.init,
      loggerClient: .mock()
    )

    var errorReceived = false

    let response: AnyPublisher<(headers: [HTTPHeader], body: Data), NetworkError> = networkClient.request(.mock)

    response
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            XCTFail("Unexpected event - finished.")
          case let .failure(error):
            switch error.cause {
            case .timeout:
              errorReceived = true
            default:
              XCTFail("Unexpected event - failure: \(error.cause).")
            }
          }
        },
        receiveValue: { body in
          XCTFail("Unexpect event - element: \(body).")
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 2)

    XCTAssertTrue(errorReceived)
  }
}
