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

extension AuthorizedNetworkClientTypeTests {
  func test_Data_with_headers_success_response_with_local_token() {
    var loadTokenCalled = false
    var authorizedRequestBuilderCalled = false

    authorizedNetworkClient = AuthorizedNetworkClient<TestToken>(
      networkClient: NetworkClient(
        urlSessionConfiguration: .default,
        urlRequester: .successMock(withResponse: (.userMock, HTTPURLResponse.mock), delayedFor: 1, scheduler: testScheduler),
        networkMonitorClient: .mockSequence(withValues: [.available], onScheduler: testScheduler, every: 1),
        logUUID: UUID.init,
        loggerClient: .mock()
      ),
      tokenClient: TokenClient<TestToken>(
        currentToken: Just(.mock)
          .setFailureType(to: TokenError.self)
          .handleEvents(receiveSubscription: { _ in
            loadTokenCalled = true
          })
          .delay(for: 1, scheduler: self.testScheduler)
          .eraseToAnyPublisher(),
        refreshToken: {
          fatalError("Shoud not be called!")
        },
        authorizedRequestBuilder: { request, token in
          XCTAssertEqual(token, .mock)
          authorizedRequestBuilderCalled = true
          return request
        }
      )
    )

    let response: AnyPublisher<(headers: [HTTPHeader], body: Data), AuthorizedNetworkError> = authorizedNetworkClient
      .authorizedRequest(.mock)

    var finished = false
    var valueReceivedCount = 0

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

    testScheduler.advance(by: 3)

    XCTAssertTrue(loadTokenCalled)
    XCTAssertTrue(authorizedRequestBuilderCalled)

    XCTAssertEqual(valueReceivedCount, 1)
    XCTAssertTrue(finished)
  }

  func test_User_with_headers_success_response_with_local_token() {
    var loadTokenCalled = false
    var authorizedRequestBuilderCalled = false

    authorizedNetworkClient = AuthorizedNetworkClient<TestToken>(
      networkClient: NetworkClient(
        urlSessionConfiguration: .default,
        urlRequester: .successMock(withResponse: (.userMock, HTTPURLResponse.mock), delayedFor: 1, scheduler: testScheduler),
        networkMonitorClient: .mockSequence(withValues: [.available], onScheduler: testScheduler, every: 1),
        logUUID: UUID.init,
        loggerClient: .mock()
      ),
      tokenClient: TokenClient<TestToken>(
        currentToken: Just(.mock)
          .setFailureType(to: TokenError.self)
          .handleEvents(receiveSubscription: { _ in
            loadTokenCalled = true
          })
          .delay(for: 1, scheduler: self.testScheduler)
          .eraseToAnyPublisher(),
        refreshToken: {
          fatalError("Shoud not be called!")
        },
        authorizedRequestBuilder: { request, token in
          XCTAssertEqual(token, .mock)
          authorizedRequestBuilderCalled = true
          return request
        }
      )
    )

    var valueReceivedCount = 0
    var finished = false

    let response: AnyPublisher<(headers: [HTTPHeader], object: User), AuthorizedNetworkError> = authorizedNetworkClient
      .authorizedRequest(.mock)

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

    testScheduler.advance(by: 3)

    XCTAssertTrue(loadTokenCalled)
    XCTAssertTrue(authorizedRequestBuilderCalled)

    XCTAssertEqual(valueReceivedCount, 1)
    XCTAssertTrue(finished)
  }

  func test_User_without_headers_success_response_with_local_token() {
    var loadTokenCalled = false
    var authorizedRequestBuilderCalled = false

    authorizedNetworkClient = AuthorizedNetworkClient<TestToken>(
      networkClient: NetworkClient(
        urlSessionConfiguration: .default,
        urlRequester: .successMock(withResponse: (.userMock, HTTPURLResponse.mock), delayedFor: 1, scheduler: testScheduler),
        networkMonitorClient: .mockSequence(withValues: [.available], onScheduler: testScheduler, every: 1),
        logUUID: UUID.init,
        loggerClient: .mock()
      ),
      tokenClient: TokenClient<TestToken>(
        currentToken: Just(.mock)
          .setFailureType(to: TokenError.self)
          .handleEvents(receiveSubscription: { _ in
            loadTokenCalled = true
          })
          .delay(for: 1, scheduler: self.testScheduler)
          .eraseToAnyPublisher(),
        refreshToken: {
          fatalError("Shoud not be called!")
        },
        authorizedRequestBuilder: { request, token in
          XCTAssertEqual(token, .mock)
          authorizedRequestBuilderCalled = true
          return request
        }
      )
    )

    var valueReceivedCount = 0
    var finished = false

    let response: AnyPublisher<User, AuthorizedNetworkError> = authorizedNetworkClient
      .authorizedRequest(.mock)

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

    testScheduler.advance(by: 3)

    XCTAssertTrue(loadTokenCalled)
    XCTAssertTrue(authorizedRequestBuilderCalled)

    XCTAssertEqual(valueReceivedCount, 1)
    XCTAssertTrue(finished)
  }

  func test_unauthorized_failure_then_success_after_token_refreshing() {
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
        urlSessionConfiguration: .default,
        urlRequester: .init { _ in { _ in
            let response = networkRequestCount == 0
            ? (Data(), unauthorizedHTTPResponse)
            : (.userMock, successHTTPResponse)

            return Just(response)
              .setFailureType(to: URLError.self)
              .handleEvents(receiveSubscription: { _ in networkRequestCount += 1 })
              .delay(for: 1, scheduler: self.testScheduler)
              .eraseToAnyPublisher()
          }
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

    var valueReceivedCount = 0
    var finished = false

    let response: AnyPublisher<(headers: [HTTPHeader], body: Data), AuthorizedNetworkError> = authorizedNetworkClient
      .authorizedRequest(.mock)

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
          XCTAssertTrue(receivedHeaders.isEmpty)
          XCTAssertEqual(body, .userMock)
          valueReceivedCount += 1
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 7)

    XCTAssertEqual(networkRequestCount, 2)
    XCTAssertEqual(currentTokenCount, 2)
    XCTAssertEqual(refreshTokenCount, 1)
    XCTAssertEqual(authorizedRequestBuilderCount, 2)

    XCTAssertEqual(valueReceivedCount, 1)
    XCTAssertTrue(finished)
  }

  func test_local_validation_failure_then_success_after_token_refreshing() {
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
        urlSessionConfiguration: .default,
        urlRequester: .init { _ in { _ in
            return Just((.userMock, successHTTPResponse))
              .setFailureType(to: URLError.self)
              .handleEvents(receiveSubscription: { _ in
                networkRequestCount += 1
              })
              .delay(for: 1, scheduler: self.testScheduler)
              .eraseToAnyPublisher()
          }
        },
        networkMonitorClient: .mockSequence(withValues: [.available], onScheduler: testScheduler, every: 1),
        logUUID: UUID.init,
        loggerClient: .mock()
      ),
      tokenClient: TokenClient<TestToken>(
        currentToken: {
          let publisher = Publishers.Create<TestToken, TokenError> { subscriber in
            if currentTokenCount == 0 {
              subscriber.send(completion: .failure(.tokenLocallyInvalid))
            } else {
              subscriber.send(.mock)
              subscriber.send(completion: .finished)
            }

            return AnyCancellable {}
          }

          return publisher
            .handleEvents(receiveSubscription: { _ in currentTokenCount += 1 })
            .delay(for: 1, scheduler: self.testScheduler)
            .eraseToAnyPublisher()
        }(),
        refreshToken: {
          Just(())
            .setFailureType(to: TokenError.self)
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

    var valueReceivedCount = 0
    var finished = false

    let response: AnyPublisher<(headers: [HTTPHeader], body: Data), AuthorizedNetworkError> = authorizedNetworkClient
      .authorizedRequest(.mock)

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
          XCTAssertTrue(receivedHeaders.isEmpty)
          XCTAssertEqual(body, .userMock)
          valueReceivedCount += 1
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 5)

    XCTAssertEqual(networkRequestCount, 1)
    XCTAssertEqual(currentTokenCount, 2)
    XCTAssertEqual(refreshTokenCount, 1)
    XCTAssertEqual(authorizedRequestBuilderCount, 1)

    XCTAssertEqual(valueReceivedCount, 1)
    XCTAssertTrue(finished)
  }

  func test_unauthorized_failure_then_token_refreshing_failure_then_success_on_refresh_retrying() {
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
        urlSessionConfiguration: .default,
        urlRequester: .init { _ in { _ in
            let response = networkRequestCount == 0
            ? (Data(), unauthorizedHTTPResponse)
            : (.userMock, successHTTPResponse)

            return Just(response)
              .setFailureType(to: URLError.self)
              .handleEvents(receiveSubscription: { _ in networkRequestCount += 1 })
              .delay(for: 1, scheduler: self.testScheduler)
              .eraseToAnyPublisher()
          }
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
          Deferred<AnyPublisher<Void, TokenError>> {
            let refresh = refreshTokenCount >= 2
            ? Just(()).setFailureType(to: TokenError.self).eraseToAnyPublisher()
            : Fail(error: .refreshError).eraseToAnyPublisher()

            return refresh
              .handleEvents(receiveSubscription: { _ in
                refreshTokenCount += 1
              })
              .delay(for: 1, scheduler: self.testScheduler)
              .eraseToAnyPublisher()
          }
          .eraseToAnyPublisher()
        },
        authorizedRequestBuilder: { request, token in
          XCTAssertEqual(token, .mock)
          authorizedRequestBuilderCount += 1

          return request
        }
      )
    )

    var valueReceivedCount = 0
    var finished = false

    let response: AnyPublisher<(headers: [HTTPHeader], body: Data), AuthorizedNetworkError> = authorizedNetworkClient
      .authorizedRequest(.mock)

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
          XCTAssertTrue(receivedHeaders.isEmpty)
          XCTAssertEqual(body, .userMock)
          valueReceivedCount += 1
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 9)

    XCTAssertEqual(networkRequestCount, 2)
    XCTAssertEqual(currentTokenCount, 2)
    XCTAssertEqual(refreshTokenCount, 3)
    XCTAssertEqual(authorizedRequestBuilderCount, 2)

    XCTAssertEqual(valueReceivedCount, 1)
    XCTAssertTrue(finished)
  }
}
