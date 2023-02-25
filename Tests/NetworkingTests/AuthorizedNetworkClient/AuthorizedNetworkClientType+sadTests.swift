import Combine
import Foundation
@testable import Networking
import RequestBuilder
import XCTest

extension AuthorizedNetworkClientTypeTests {
  func test_unauthorized_again_after_successful_refresh() {
    let unauthorizedHTTPResponse: HTTPURLResponse = HTTPURLResponse(
      url: .mock,
      statusCode: 401,
      httpVersion: nil,
      headerFields: [String: String]()
    )!

    var networkRequestCount = 0
    var currentTokenCount = 0
    var refreshTokenCount = 0
    var authorizedRequestBuilderCount = 0

    authorizedNetworkClient = AuthorizedNetworkClient<TestToken>(
      networkClient: NetworkClient(
        urlRequester: .init { _ in
          Just((Data(), unauthorizedHTTPResponse))
            .setFailureType(to: URLError.self)
            .handleEvents(receiveSubscription: { _ in networkRequestCount += 1 })
            .delay(for: 1, scheduler: self.testScheduler)
            .eraseToAnyPublisher()
        },
        networkMonitorClient: .mockSequence(withValues: [.available], onScheduler: testScheduler, every: 1),
        logUUID: UUID.init,
        loggerClient: .mock()
      ),
      tokenClient: TokenClient<TestToken>(
        currentToken: Just(.mock)
          .setFailureType(to: TokenError.self)
          .handleEvents(receiveSubscription: { _ in
            currentTokenCount += 1
          })
          .delay(for: 1, scheduler: self.testScheduler)
          .eraseToAnyPublisher(),
        refreshToken: {
          Just(())
            .setFailureType(to: TokenError.self)
            .handleEvents(receiveSubscription: { _ in refreshTokenCount += 1 })
            .delay(for: 1, scheduler: self.testScheduler)
            .eraseToAnyPublisher()
        },
        authorizedRequestBuilder: { request, token in
          XCTAssertEqual(token, .mock)
          authorizedRequestBuilderCount += 1

          return request
        }
      )
    )

    var errorReceived = false

    let response: AnyPublisher<(headers: [HTTPHeader], object: Double), AuthorizedNetworkError> = authorizedNetworkClient
      .authorizedRequest(.mock)

    response
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            XCTFail("Unexpected event - finished.")
          case let .failure(error):
            switch error.cause {
            case .networkError where error.underlyingError is NetworkError:
              switch (error.underlyingError as! NetworkError).cause {
              case .unauthorized:
                errorReceived = true
              default:
                XCTFail("Unexpected event - failure: \(error).")
              }
            default:
              XCTFail("Unexpected event - failure: \(error).")
            }
          }
        },
        receiveValue: { _, body in
          XCTFail("Unexpected event - failure: \(body).")
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 11)

    XCTAssertEqual(networkRequestCount, 3)
    XCTAssertEqual(currentTokenCount, 3)
    XCTAssertEqual(refreshTokenCount, 2)
    XCTAssertEqual(authorizedRequestBuilderCount, 3)

    XCTAssertTrue(errorReceived)
  }

  func test_network_response_error_passed_through_without_refreshing() {
    let serverErrorHTTPResponse: HTTPURLResponse = HTTPURLResponse(
      url: .mock,
      statusCode: 500,
      httpVersion: nil,
      headerFields: [String: String]()
    )!

    var currentTokenCalled = false
    var authorizedRequestBuilderCalled = false

    authorizedNetworkClient = AuthorizedNetworkClient<TestToken>(
      networkClient: NetworkClient(
        urlRequester: .successMock(withResponse: (Data(), serverErrorHTTPResponse), delayedFor: 1, scheduler: testScheduler),
        networkMonitorClient: .mockSequence(withValues: [.available], onScheduler: testScheduler, every: 1),
        logUUID: UUID.init,
        loggerClient: .mock()
      ),
      tokenClient: TokenClient<TestToken>(
        currentToken: Just(.mock)
          .setFailureType(to: TokenError.self)
          .handleEvents(receiveSubscription: { _ in currentTokenCalled = true })
          .delay(for: 1, scheduler: self.testScheduler)
          .eraseToAnyPublisher(),
        refreshToken: {
          fatalError("Should not be called!")
        },
        authorizedRequestBuilder: { request, token in
          XCTAssertEqual(token, .mock)
          authorizedRequestBuilderCalled = true

          return request
        }
      )
    )

    var errorReceived = false

    let response: AnyPublisher<(headers: [HTTPHeader], body: Data), AuthorizedNetworkError> = authorizedNetworkClient
      .authorizedRequest(.mock)

    response
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            XCTFail("Unexpected event - finished.")
          case let .failure(error):
            switch error.cause {
            case .networkError where error.underlyingError is NetworkError:
              switch (error.underlyingError as! NetworkError).cause {
              case let .serverError(statusCode: statusCode) where statusCode == 500:
                errorReceived = true
              default:
                XCTFail("Unexpected event - failure: \(error).")
              }
            default:
              XCTFail("Unexpected event - failure: \(error).")
            }
          }
        },
        receiveValue: { _, body in
          XCTFail("Unexpected event - failure: \(body).")
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 3)

    XCTAssertTrue(currentTokenCalled)
    XCTAssertTrue(authorizedRequestBuilderCalled)

    XCTAssertTrue(errorReceived)
  }

  func test_network_monitor_error_passed_through_without_refreshing() {
    var currentTokenCalled = false
    var authorizedRequestBuilderCalled = false

    authorizedNetworkClient = AuthorizedNetworkClient<TestToken>(
      networkClient: NetworkClient(
        urlRequester: .mock(),
        networkMonitorClient: .mockSequence(withValues: [.unavailable], onScheduler: testScheduler, every: 1),
        logUUID: UUID.init,
        loggerClient: .mock()
      ),
      tokenClient: TokenClient<TestToken>(
        currentToken: Just(.mock)
          .setFailureType(to: TokenError.self)
          .handleEvents(receiveSubscription: { _ in currentTokenCalled = true })
          .delay(for: 1, scheduler: self.testScheduler)
          .eraseToAnyPublisher(),
        refreshToken: {
          fatalError("Should not be called!")
        },
        authorizedRequestBuilder: { request, token in
          XCTAssertEqual(token, .mock)
          authorizedRequestBuilderCalled = true

          return request
        }
      )
    )

    var errorReceived = false

    let response: AnyPublisher<(headers: [HTTPHeader], body: Data), AuthorizedNetworkError> = authorizedNetworkClient
      .authorizedRequest(.mock)

    response
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            XCTFail("Unexpected event - finished.")
          case let .failure(error):
            switch error.cause {
            case .networkError where error.underlyingError is NetworkError:
              switch (error.underlyingError as! NetworkError).cause {
              case .noConnection:
                errorReceived = true
              default:
                XCTFail("Unexpected event - failure: \(error).")
              }
            default:
              XCTFail("Unexpected event - failure: \(error).")
            }
          }
        },
        receiveValue: { _, body in
          XCTFail("Unexpected event - failure: \(body).")
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 3)

    XCTAssertTrue(currentTokenCalled)
    XCTAssertTrue(authorizedRequestBuilderCalled)

    XCTAssertTrue(errorReceived)
  }

  func test_load_token_for_request_error_passed_through() {
    var currentTokenCalled = false

    authorizedNetworkClient = AuthorizedNetworkClient<TestToken>(
      networkClient: NetworkClient(
        urlRequester: .mock(),
        networkMonitorClient: .mock(),
        logUUID: UUID.init,
        loggerClient: .mock()
      ),
      tokenClient: TokenClient<TestToken>(
        currentToken: Fail(error: .localTokenError)
          .handleEvents(receiveSubscription: { _ in currentTokenCalled = true })
          .delay(for: 1, scheduler: self.testScheduler)
          .eraseToAnyPublisher(),
        refreshToken: {
          fatalError("Should not be called!")
        },
        authorizedRequestBuilder: { _, _  in
          fatalError("Should not be called!")
        }
      )
    )

    var errorReceived = false

    let response: AnyPublisher<(headers: [HTTPHeader], body: Data), AuthorizedNetworkError> = authorizedNetworkClient
      .authorizedRequest(.mock)

    response
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            XCTFail("Unexpected event - finished.")
          case let .failure(error):
            switch error.cause {
            case .localTokenError where error.underlyingError is TokenError:
              switch (error.underlyingError as! TokenError).cause {
              case .localTokenError:
                errorReceived = true
              default:
                XCTFail("Unexpected event - failure: \(error).")
              }
            default:
              XCTFail("Unexpected event - failure: \(error).")
            }
          }
        },
        receiveValue: { _, body in
          XCTFail("Unexpected event - failure: \(body).")
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 1)

    XCTAssertTrue(currentTokenCalled)

    XCTAssertTrue(errorReceived)
  }

  func test_unauthorized_failure_then_token_refreshing_failure_then_failure_on_refresh_retrying() {
    let unauthorizedHTTPResponse: HTTPURLResponse = HTTPURLResponse(
      url: .mock,
      statusCode: 401,
      httpVersion: nil,
      headerFields: [String: String]()
    )!

    let successHTTPResponse: HTTPURLResponse = HTTPURLResponse(
      url: .mock,
      statusCode: 200,
      httpVersion: nil,
      headerFields: [String: String]()
    )!

    var networkRequestCount = 0
    var currentTokenCount = 0
    var refreshTokenCount = 0
    var authorizedRequestBuilderCount = 0

    authorizedNetworkClient = AuthorizedNetworkClient<TestToken>(
      networkClient: NetworkClient(
        urlRequester: .init { _ in
          let response = networkRequestCount == 0
          ? (Data(), unauthorizedHTTPResponse)
          : (Data(), successHTTPResponse)

          return Just(response)
            .setFailureType(to: URLError.self)
            .handleEvents(receiveSubscription: { _ in networkRequestCount += 1 })
            .delay(for: 1, scheduler: self.testScheduler)
            .eraseToAnyPublisher()
        },
        networkMonitorClient: .mockSequence(withValues: [.available], onScheduler: testScheduler, every: 1),
        logUUID: UUID.init,
        loggerClient: .mock()
      ),
      tokenClient: TokenClient<TestToken>(
        currentToken: Just(.mock)
          .setFailureType(to: TokenError.self)
          .handleEvents(receiveSubscription: { _ in
            currentTokenCount += 1
          })
          .delay(for: 1, scheduler: self.testScheduler)
          .eraseToAnyPublisher(),
        refreshToken: {
          Fail(error: .refreshError)
            .eraseToAnyPublisher()
            .handleEvents(receiveSubscription: { _ in
              refreshTokenCount += 1
            })
            .delay(for: 1, scheduler: self.testScheduler)
            .eraseToAnyPublisher()
        },
        authorizedRequestBuilder: { request, token in
          XCTAssertEqual(token, .mock)
          authorizedRequestBuilderCount += 1

          return request
        }
      )
    )

    var errorReceived = false

    let response: AnyPublisher<(headers: [HTTPHeader], body: Data), AuthorizedNetworkError> = authorizedNetworkClient
      .authorizedRequest(.mock)

    response
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            XCTFail("Unexpected event - finished.")
          case let .failure(error):
            switch error.cause {
            case .refreshTokenError:
              errorReceived = true
            default:
              XCTFail("Unexpected event - failure: \(error).")
            }
          }
        },
        receiveValue: { _, body in
          XCTFail("Unexpected event - failure: \(body).")
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 8)

    XCTAssertEqual(networkRequestCount, 1)
    XCTAssertEqual(currentTokenCount, 1)
    XCTAssertEqual(refreshTokenCount, 3)
    XCTAssertEqual(authorizedRequestBuilderCount, 1)

    XCTAssertTrue(errorReceived)
  }

  func test_unauthorized_failure_then_token_refreshing_failure_then_skipping_retry_when_clientError_on_refresh_retrying() {
    let unauthorizedHTTPResponse: HTTPURLResponse = HTTPURLResponse(
      url: .mock,
      statusCode: 401,
      httpVersion: nil,
      headerFields: [String: String]()
    )!

    let successHTTPResponse: HTTPURLResponse = HTTPURLResponse(
      url: .mock,
      statusCode: 200,
      httpVersion: nil,
      headerFields: [String: String]()
    )!

    var networkRequestCount = 0
    var currentTokenCount = 0
    var refreshTokenCount = 0
    var authorizedRequestBuilderCount = 0

    authorizedNetworkClient = AuthorizedNetworkClient<TestToken>(
      networkClient: NetworkClient(
        urlRequester: .init { _ in
          let response = networkRequestCount == 0
          ? (Data(), unauthorizedHTTPResponse)
          : (Data(), successHTTPResponse)

          return Just(response)
            .setFailureType(to: URLError.self)
            .handleEvents(receiveSubscription: { _ in networkRequestCount += 1 })
            .delay(for: 1, scheduler: self.testScheduler)
            .eraseToAnyPublisher()
        },
        networkMonitorClient: .mockSequence(withValues: [.available], onScheduler: testScheduler, every: 1),
        logUUID: UUID.init,
        loggerClient: .mock()
      ),
      tokenClient: TokenClient<TestToken>(
        currentToken: Just(.mock)
          .setFailureType(to: TokenError.self)
          .handleEvents(receiveSubscription: { _ in
            currentTokenCount += 1
          })
          .delay(for: 1, scheduler: self.testScheduler)
          .eraseToAnyPublisher(),
        refreshToken: {
          var refreshErrorWithClientError = TokenError.refreshError
          refreshErrorWithClientError.underlyingError = NetworkError.clientError(statusCode: 400)

          return Fail(error: refreshErrorWithClientError)
            .eraseToAnyPublisher()
            .handleEvents(receiveSubscription: { _ in
              refreshTokenCount += 1
            })
            .delay(for: 1, scheduler: self.testScheduler)
            .eraseToAnyPublisher()
        },
        authorizedRequestBuilder: { request, token in
          XCTAssertEqual(token, .mock)
          authorizedRequestBuilderCount += 1

          return request
        }
      )
    )

    var errorReceived = false

    let response: AnyPublisher<(headers: [HTTPHeader], body: Data), AuthorizedNetworkError> = authorizedNetworkClient
      .authorizedRequest(.mock)

    response
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            XCTFail("Unexpected event - finished.")
          case let .failure(error):
            switch error.cause {
            case .refreshTokenError:
              errorReceived = true
            default:
              XCTFail("Unexpected event - failure: \(error).")
            }
          }
        },
        receiveValue: { _, body in
          XCTFail("Unexpected event - failure: \(body).")
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 4)

    XCTAssertEqual(networkRequestCount, 1)
    XCTAssertEqual(currentTokenCount, 1)
    XCTAssertEqual(refreshTokenCount, 1)
    XCTAssertEqual(authorizedRequestBuilderCount, 1)

    XCTAssertTrue(errorReceived)
  }

  func test_ignoring_to_be_ignored_errors() {
    let ignoreOutputOnError: (AuthorizedNetworkError) -> Bool = { error in
      if case .localTokenError = error.cause {
        return true
      }

      return false
    }

    authorizedNetworkClient = AuthorizedNetworkClient<TestToken>(
      networkClient: NetworkClient(
        urlRequester: .mock(),
        networkMonitorClient: .mock(),
        logUUID: UUID.init,
        loggerClient: .mock()
      ),
      tokenClient: TokenClient<TestToken>(
        currentToken: Fail(error: .localTokenError).eraseToAnyPublisher(),
        refreshToken: { fatalError("Not implemented!") },
        authorizedRequestBuilder: { _, _ in fatalError("Not implemented!") }
      ),
      ignoreOutputOnError: ignoreOutputOnError
    )

    var finishedReceived = false

    let response: AnyPublisher<(headers: [HTTPHeader], body: Data), AuthorizedNetworkError> = authorizedNetworkClient
      .authorizedRequest(.mock)

    response
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            finishedReceived = true
          case let .failure(error):
            XCTFail("Unexpected event - failure: \(error).")
          }
        },
        receiveValue: { _, body in
          XCTFail("Unexpected event - failure: \(body).")
        }
      )
      .store(in: &subscriptions)

    XCTAssertTrue(finishedReceived)
  }

  func test_passing_through_not_to_be_ignored_errors() {
    let ignoreOutputOnError: (AuthorizedNetworkError) -> Bool = { error in
      if case .localTokenError = error.cause {
        return true
      }

      return false
    }

    authorizedNetworkClient = AuthorizedNetworkClient<TestToken>(
      networkClient: NetworkClient(
        urlRequester: .mock(),
        networkMonitorClient: .mock(
          isNetworkAvailable: Just(false).eraseToAnyPublisher()
        ),
        logUUID: UUID.init,
        loggerClient: .mock()
      ),
      tokenClient: TokenClient<TestToken>(
        currentToken: Just(.mock).setFailureType(to: TokenError.self).eraseToAnyPublisher(),
        refreshToken: { fatalError("Not implemented!") },
        authorizedRequestBuilder: { request, _ in request }
      ),
      ignoreOutputOnError: ignoreOutputOnError
    )

    var errorReceived = false

    let response: AnyPublisher<(headers: [HTTPHeader], body: Data), AuthorizedNetworkError> = authorizedNetworkClient
      .authorizedRequest(.mock)

    response
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            XCTFail("Unexpected event - finished.")
          case let .failure(error):
            switch error.cause {
            case .networkError where error.underlyingError is NetworkError:
              switch (error.underlyingError as! NetworkError).cause {
              case .noConnection:
                errorReceived = true
              default:
                XCTFail("Unexpected event - failure: \(error).")
              }
            default:
              XCTFail("Unexpected event - failure: \(error).")
            }
          }
        },
        receiveValue: { _, body in
          XCTFail("Unexpected event - failure: \(body).")
        }
      )
      .store(in: &subscriptions)

    XCTAssertTrue(errorReceived)
  }
}
