import Combine
@testable import Networking
import RequestBuilder
import XCTest

// MARK: - Mocks

private extension Request {
  static var validMock: Self = Request(endpoint: "https://reqres.in/api/users/1")

  static func invalidMock(withError error: URLRequestError) -> Self {
    Request(endpoint: "https://reqres.in/api/users/1") {
      URLRequestComponent { _ in .failure(error) }
    }
  }
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

// MARK: - Tests

extension NetworkClientTests {
  func test_URLRequest_build_failure() {
    networkClient = NetworkClient(
      urlSessionConfiguration: .default,
      urlRequester: .mock(),
      networkMonitorClient: .mock(),
      logUUID: UUID.init,
      loggerClient: .mock()
    )

    var errorReceived = false

    let response: AnyPublisher<(headers: [HTTPHeader], body: Data), NetworkError> = Request
      .invalidMock(withError: .endpointParsingError)
      .execute(using: networkClient)

    response
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            XCTFail("Unexpected event - finished.")
          case let .failure(error) where error.underlyingError is URLRequestError:
            errorReceived = true
          case let .failure(error):
            XCTFail("Unexpected event - error \(error).")
          }
        },
        receiveValue: { body in
          XCTFail("Unexpect event - element: \(body).")
        }
      )
      .store(in: &subscriptions)

    XCTAssertTrue(errorReceived)
  }

  func test_unauthorized_request() {
    networkClient = NetworkClient(
      urlSessionConfiguration: .default,
      urlRequester: .successMock(withResponse: (Data(), HTTPURLResponse.mock), delayedFor: 1, scheduler: testScheduler),
      networkMonitorClient: .mockSequence(withValues: [.available], onScheduler: testScheduler, every: 1),
      logUUID: UUID.init,
      loggerClient: .mock()
    )

    var valueReceived = false
    var finished = false

    let response: AnyPublisher<(headers: [HTTPHeader], body: Data), NetworkError> = Request.validMock
      .execute(using: networkClient)

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
        receiveValue: { _, _ in
          valueReceived = true
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 2)

    XCTAssertTrue(valueReceived)
    XCTAssertTrue(finished)
  }
}
