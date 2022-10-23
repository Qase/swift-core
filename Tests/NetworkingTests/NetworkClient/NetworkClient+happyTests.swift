import Combine
import Foundation
@testable import Networking
import RequestBuilder
import XCTest

// MARK: - Mocks

private extension Array where Element == HTTPHeader {
  static var mock = [
    HTTPHeader.accept(.json),
    HTTPHeader.contentType(.json)
  ]
}

private extension HTTPURLResponse {
  static var mock = HTTPURLResponse(
    url: .mock,
    statusCode: 200,
    httpVersion: nil,
    headerFields: [
      "\(HTTPHeaderName.acceptType.rawValue)": "\(AcceptTypeValue.json.rawValue)",
      "\(HTTPHeaderName.contentType.rawValue)": "\(ContentTypeValue.json.rawValue)"
    ]
  )!
}

private extension Data {
  static var userMock = try! JSONEncoder().encode(User.mock)
}

// MARK: - Tests

extension NetworkClientTests {
  func test_Data_with_headers_success_response() {
    var transformRequestCalled = false

    networkClient = NetworkClient(
      urlSessionConfiguration: .default,
      urlRequester: .successMock(withResponse: (.userMock, HTTPURLResponse.mock), delayedFor: 1, scheduler: testScheduler),
      networkMonitorClient: .mockSequence(withValues: [.available], onScheduler: testScheduler, every: 1),
      logUUID: UUID.init,
      loggerClient: .mock(),
      transformRequest: { urlRequest in
        transformRequestCalled = true
        return urlRequest
      }
    )

    var valueReceivedCount = 0
    var finished = false

    let response: AnyPublisher<(headers: [HTTPHeader], body: Data), NetworkError> = networkClient.request(.mock)

    response
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            finished = true
          case let .failure(error):
            XCTFail("Unexpected event - failure: \(error)")
          }
        },
        receiveValue: { receivedHeaders, body in
          XCTAssertTrue(Set([HTTPHeader].mock).symmetricDifference(Set(receivedHeaders)).isEmpty)
          XCTAssertEqual(.userMock, body)
          valueReceivedCount += 1
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 2)

    XCTAssertTrue(transformRequestCalled)
    XCTAssertEqual(valueReceivedCount, 1)
    XCTAssertTrue(finished)
  }

  func test_User_with_headers_success_response() {
    var transformRequestCalled = false

    networkClient = NetworkClient(
      urlSessionConfiguration: .default,
      urlRequester: .successMock(withResponse: (.userMock, HTTPURLResponse.mock), delayedFor: 1, scheduler: testScheduler),
      networkMonitorClient: .mockSequence(withValues: [.available], onScheduler: testScheduler, every: 1),
      logUUID: UUID.init,
      loggerClient: .mock(),
      transformRequest: { urlRequest in
        transformRequestCalled = true
        return urlRequest
      }
    )

    var valueReceivedCount = 0
    var finished = false

    let response: AnyPublisher<(headers: [HTTPHeader], object: User), NetworkError> = networkClient.request(.mock)

    response
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            finished = true
          case let .failure(error):
            XCTFail("Unexpected event - failure: \(error)")
          }
        },
        receiveValue: { receivedHeaders, object in
          XCTAssertTrue(Set([HTTPHeader].mock).symmetricDifference(Set(receivedHeaders)).isEmpty)
          XCTAssertEqual(User.mock, object)
          valueReceivedCount += 1
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 2)

    XCTAssertTrue(transformRequestCalled)
    XCTAssertEqual(valueReceivedCount, 1)
    XCTAssertTrue(finished)
  }

  func test_User_without_headers_success_response() {
    var transformRequestCalled = false

    networkClient = NetworkClient(
      urlSessionConfiguration: .default,
      urlRequester: .successMock(withResponse: (.userMock, HTTPURLResponse.mock), delayedFor: 1, scheduler: testScheduler),
      networkMonitorClient: .mockSequence(withValues: [.available], onScheduler: testScheduler, every: 1),
      logUUID: UUID.init,
      loggerClient: .mock(),
      transformRequest: { urlRequest in
        transformRequestCalled = true
        return urlRequest
      }
    )

    var valueReceivedCount = 0
    var finished = false

    let response: AnyPublisher<User, NetworkError> = networkClient.request(.mock)

    response
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            finished = true
          case let .failure(error):
            XCTFail("Unexpected event - failure: \(error)")
          }
        },
        receiveValue: { object in
          XCTAssertEqual(User.mock, object)
          valueReceivedCount += 1
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 2)

    XCTAssertTrue(transformRequestCalled)
    XCTAssertEqual(valueReceivedCount, 1)
    XCTAssertTrue(finished)
  }

  func test_request_and_http_response_are_logged_with_the_same_uuid() {
    let expectedUUID = "DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF"
    var uuidCalled = false
    var logURLRequestCalled = false
    var logHTTPURLResponseCalled = false

    let uuid = { () -> UUID in
      uuidCalled = true
      return UUID(uuidString: expectedUUID)!
    }

    networkClient = NetworkClient(
      urlSessionConfiguration: .default,
      urlRequester: .successMock(withResponse: (.userMock, HTTPURLResponse.mock), delayedFor: 1, scheduler: testScheduler),
      networkMonitorClient: .mockSequence(withValues: [.available], onScheduler: testScheduler, every: 1),
      logUUID: uuid,
      loggerClient: .mock(
        logRequest: { uuid, _ in
          logURLRequestCalled = true
          XCTAssertEqual(uuid.uuidString, expectedUUID)
        },
        logURLResponse: { _, _, _ in
          XCTFail("logURLResponse should not be called when HTTPURLResponse is available")
        },
        logHTTPURLResponse: { uuid, _, _ in
          logHTTPURLResponseCalled = true
          XCTAssertEqual(uuid.uuidString, expectedUUID)
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
    XCTAssertTrue(logHTTPURLResponseCalled)
  }
}
