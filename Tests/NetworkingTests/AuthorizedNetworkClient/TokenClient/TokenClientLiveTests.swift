import Combine
import CombineSchedulers
import KeyValueStorage
@testable import Networking
import Utils
import XCTest

class TokenClientLiveTests: XCTestCase {
  struct TestToken: TokenRepresenting {
    enum TokenType: String, KeyProviding, Hashable, Codable, CaseIterable {
      case single

      var keyPrefix: String { self.rawValue }
      var key: String { keyPrefix }
    }

    var type: TokenType
    var value: String

    init(value: String) {
      self.value = value
      self.type = .single
    }

    var description: String { "\(value)" }
  }

  var tokenClient: TokenClientLive<TestToken>!
  var testScheduler: TestScheduler<DispatchQueue.SchedulerTimeType, DispatchQueue.SchedulerOptions>!
  var subscriptions = Set<AnyCancellable>()

  override func setUp() {
    super.setUp()

    testScheduler = DispatchQueue.test
  }

  override func tearDown() {
    subscriptions = []
    tokenClient = nil
    testScheduler = nil

    super.tearDown()
  }

  func test_default_current_token_success() {
    let testToken = TestToken(value: "localToken")

    var loadTokenCount = 0
    var validateTokenCount = 0

    tokenClient = TokenClientLive(
      loadToken: {
        Just(testToken).setFailureType(to: TokenPersistenceError.self)
          .handleEvents(receiveSubscription: { _ in
            loadTokenCount += 1
          })
          .delay(for: 1, scheduler: self.testScheduler)
          .eraseToAnyPublisher()
      },
      isTokenValid: { _ in
        Just(true)
          .handleEvents(receiveSubscription: { _ in validateTokenCount += 1 })
          .delay(for: 1, scheduler: self.testScheduler)
          .eraseToAnyPublisher()
      },
      storeToken: { _ in fatalError("Should not be called!") },
      refreshTokenRequest: { _ in fatalError("Should not be called!") }
    )

    var valueReceived = false
    var completionReceived = false

    tokenClient.currentToken
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            completionReceived = true
          case let .failure(error):
            XCTFail("Unexpected event received - error: \(error).")
          }
        }, receiveValue: { receivedtoken in
          XCTAssertEqual(receivedtoken, testToken)
          valueReceived = true
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 2)

    XCTAssertEqual(loadTokenCount, 1)
    XCTAssertEqual(validateTokenCount, 1)

    XCTAssertTrue(valueReceived)
    XCTAssertTrue(completionReceived)
  }

  func test_default_current_token_failure() {
    var loadTokenCount = 0

    tokenClient = TokenClientLive(
      loadToken: {
        Fail(error: .loadTokenError)
          .handleEvents(receiveSubscription: { _ in
            loadTokenCount += 1
          })
          .delay(for: 1, scheduler: self.testScheduler)
          .eraseToAnyPublisher()
      },
      isTokenValid: { _ in fatalError("Should not be called!") },
      storeToken: { _ in fatalError("Should not be called!") },
      refreshTokenRequest: { _ in fatalError("Should not be called!") }
    )

    var errorReceived = false

    tokenClient.currentToken
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            XCTFail("Unexpected event received - finished.")
          case let .failure(error) where error.cause == .localTokenError:
            errorReceived = true
          case let .failure(error):
            XCTFail("Unexpected event received - error: \(error).")
          }
        }, receiveValue: { receivedtoken in
          XCTFail("Unexpected event received - value: \(receivedtoken).")
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 1)

    XCTAssertEqual(loadTokenCount, 1)

    XCTAssertTrue(errorReceived)
  }

  func test_default_current_token_validation_failure() {
    var loadTokenCount = 0
    var validateTokenCount = 0

    tokenClient = TokenClientLive(
      loadToken: {
        Just(.init(value: "localToken")).setFailureType(to: TokenPersistenceError.self)
          .handleEvents(receiveSubscription: { _ in
            loadTokenCount += 1
          })
          .delay(for: 1, scheduler: self.testScheduler)
          .eraseToAnyPublisher()
      },
      isTokenValid: { _ in
        Just(false)
          .delay(for: 1, scheduler: self.testScheduler)
          .handleEvents(receiveSubscription: { _ in validateTokenCount += 1 })
          .eraseToAnyPublisher()
      },
      storeToken: { _ in fatalError("Should not be called!") },
      refreshTokenRequest: { _ in fatalError("Should not be called!") }
    )

    var errorReceived = false

    tokenClient.currentToken
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            XCTFail("Unexpected event received - finished.")
          case let .failure(error) where error.cause == .tokenLocallyInvalid:
            errorReceived = true
          case let .failure(error):
            XCTFail("Unexpected event received - error: \(error).")
          }
        }, receiveValue: { receivedtoken in
          XCTFail("Unexpected event received - value: \(receivedtoken).")
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 2)

    XCTAssertEqual(loadTokenCount, 1)
    XCTAssertEqual(validateTokenCount, 1)

    XCTAssertTrue(errorReceived)
  }

  func test_wait_for_current_token_when_refreshing() {
    var loadTokenCount = 0
    var storeTokenCount = 0
    var refreshTokenCount = 0

    var testToken = TestToken(value: "localToken")

    tokenClient = TokenClientLive(
      loadToken: {
        Just(testToken)
          .setFailureType(to: TokenPersistenceError.self)
          .handleEvents(receiveSubscription: { _ in
            loadTokenCount += 1
          })
          .delay(for: 1, scheduler: self.testScheduler)
          .eraseToAnyPublisher()
      },
      storeToken: { newToken in
        Just(())
          .setFailureType(to: TokenPersistenceError.self)
          .handleEvents(receiveSubscription: { _ in
            testToken = newToken
            storeTokenCount += 1
          })
          .delay(for: 1, scheduler: self.testScheduler)
          .eraseToAnyPublisher()
      },
      refreshTokenRequest: { invalidToken in
        Just(.init(value: "new_\(invalidToken)"))
          .setFailureType(to: TokenError.self)
          .handleEvents(receiveSubscription: { _ in
            refreshTokenCount += 1
          })
          .delay(for: 1, scheduler: self.testScheduler)
          .eraseToAnyPublisher()
      }
    )

    var refreshValueReceived = false
    var refreshCompletionReceived = false

    tokenClient.refresh()
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            refreshCompletionReceived = true
          case let .failure(error):
            XCTFail("Unexpected event received - error: \(error).")
          }
        },
        receiveValue: { _ in
          refreshValueReceived = true
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 1)

    var currentTokenValueReceived = false
    var currentTokenCompletionReceived = false

    tokenClient.currentToken
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            currentTokenCompletionReceived = true
          case let .failure(error):
            XCTFail("Unexpected event received - error: \(error).")
          }
        },
        receiveValue: { currentToken in
          XCTAssertEqual(currentToken, .init(value: "new_localToken"))
          currentTokenValueReceived = true
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 3)

    XCTAssertEqual(loadTokenCount, 2)
    XCTAssertEqual(storeTokenCount, 1)
    XCTAssertEqual(refreshTokenCount, 1)

    XCTAssertTrue(refreshValueReceived)
    XCTAssertTrue(refreshCompletionReceived)
    XCTAssertTrue(currentTokenValueReceived)
    XCTAssertTrue(currentTokenCompletionReceived)
  }

  func test_single_refresh_request() {
    var loadTokenCount = 0
    var storeTokenCount = 0
    var refreshTokenCount = 0

    tokenClient = TokenClientLive(
      loadToken: {
        Just(TestToken(value: "localToken"))
          .setFailureType(to: TokenPersistenceError.self)
          .handleEvents(receiveSubscription: { _ in
            loadTokenCount += 1
          })
          .delay(for: 1, scheduler: self.testScheduler)
          .eraseToAnyPublisher()
      },
      storeToken: { _ in
        Just(())
          .setFailureType(to: TokenPersistenceError.self)
          .handleEvents(receiveSubscription: { _ in
            storeTokenCount += 1
          })
          .delay(for: 1, scheduler: self.testScheduler)
          .eraseToAnyPublisher()

      },
      refreshTokenRequest: { invalidToken in
        Just(TestToken(value: "new_\(invalidToken)"))
          .setFailureType(to: TokenError.self)
          .handleEvents(receiveSubscription: { _ in
            refreshTokenCount += 1
          })
          .delay(for: 1, scheduler: self.testScheduler)
          .eraseToAnyPublisher()
      }
    )

    var valueReceived = false
    var completionReceived = false

    tokenClient.refresh()
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            completionReceived = true
          case let .failure(error):
            XCTFail("Unexpected event received - error: \(error).")
          }
        },
        receiveValue: { _ in
          valueReceived = true
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 3)

    XCTAssertEqual(loadTokenCount, 1)
    XCTAssertEqual(storeTokenCount, 1)
    XCTAssertEqual(refreshTokenCount, 1)

    XCTAssertTrue(valueReceived)
    XCTAssertTrue(completionReceived)
  }

  func test_multiple_refresh_requests_cause_single_refresh_call() {
    var loadTokenCount = 0
    var storeTokenCount = 0
    var refreshTokenCount = 0

    tokenClient = TokenClientLive(
      loadToken: {
        Just(TestToken(value: "localToken"))
          .setFailureType(to: TokenPersistenceError.self)
          .handleEvents(receiveSubscription: { _ in
            loadTokenCount += 1
          })
          .delay(for: 1, scheduler: self.testScheduler)
          .eraseToAnyPublisher()
      },
      storeToken: { _ in
        Just(()).setFailureType(to: TokenPersistenceError.self)
          .handleEvents(receiveSubscription: { _ in
            storeTokenCount += 1
          })
          .delay(for: 1, scheduler: self.testScheduler)
          .eraseToAnyPublisher()
      },
      refreshTokenRequest: { invalidToken in
        Just(TestToken(value: "new_\(invalidToken)"))
          .setFailureType(to: TokenError.self)
          .handleEvents(receiveSubscription: { _ in
            refreshTokenCount += 1
          })
          .delay(for: 1, scheduler: self.testScheduler)
          .eraseToAnyPublisher()
      }
    )

    var valueReceived = false
    var finishedReceived = false

    let refreshRequest1 = tokenClient.refresh()
    let refreshRequest2 = tokenClient.refresh()
    let refreshRequest3 = tokenClient.refresh()
    let refreshRequest4 = tokenClient.refresh()

    Publishers.Zip4(refreshRequest1, refreshRequest2, refreshRequest3, refreshRequest4)
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case let .failure(error):
            XCTFail("Unexpected event received - error: \(error).")
          case .finished:
            finishedReceived = true
          }

        },
        receiveValue: { _ in
          valueReceived = true
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 3)

    XCTAssertEqual(loadTokenCount, 4)
    XCTAssertEqual(storeTokenCount, 1)
    XCTAssertEqual(refreshTokenCount, 1)

    XCTAssertTrue(valueReceived)
    XCTAssertTrue(finishedReceived)
  }

  func test_load_token_failure() {
    var loadTokenCount = 0

    tokenClient = TokenClientLive(
      loadToken: {
        Fail(error: .loadTokenError)
          .handleEvents(receiveSubscription: { _ in
            loadTokenCount += 1
          })
          .delay(for: 1, scheduler: self.testScheduler)
          .eraseToAnyPublisher()
      },
      storeToken: { _ in
        fatalError("Should not be called!")
      },
      refreshTokenRequest: { _ in
        fatalError("Should not be called!")
      }
    )

    var errorReceived = false

    tokenClient.refresh()
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case let .failure(error):
            switch error.cause {
            case .localTokenError:
              errorReceived = true
            default:
              XCTFail("Unexpected event received - error: \(error).")
            }
          case .finished:
            XCTFail("Unexpected event received - finished.")
          }
        },
        receiveValue: { _ in
          XCTFail("Unexpected event received - value.")
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 1)

    XCTAssertEqual(loadTokenCount, 1)
    XCTAssertTrue(errorReceived)
  }

  func test_refresh_token_failure() {
    var loadTokenCount = 0
    var refreshTokenCount = 0

    tokenClient = TokenClientLive(
      loadToken: {
        Just(TestToken(value: "localToken"))
          .setFailureType(to: TokenPersistenceError.self)
          .handleEvents(receiveSubscription: { _ in
            loadTokenCount += 1
          })
          .delay(for: 1, scheduler: self.testScheduler)
          .eraseToAnyPublisher()
      },
      storeToken: { _ in
        fatalError("Should not be called!")
      },
      refreshTokenRequest: { _ in
        Fail(error: .refreshError)
          .handleEvents(receiveSubscription: { _ in
            refreshTokenCount += 1
          })
          .delay(for: 1, scheduler: self.testScheduler)
          .eraseToAnyPublisher()
      }
    )

    var errorReceived = false

    tokenClient.refresh()
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case let .failure(error):
            switch error.cause {
            case .refreshError:
              errorReceived = true
            default:
              XCTFail("Unexpected event received - error: \(error).")
            }
          case .finished:
            XCTFail("Unexpected event received - finished.")
          }
        },
        receiveValue: { _ in
          XCTFail("Unexpected event received - value.")
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 2)

    XCTAssertEqual(loadTokenCount, 1)
    XCTAssertEqual(refreshTokenCount, 1)
    XCTAssertTrue(errorReceived)
  }

  func test_store_token_failure() {
    var loadTokenCount = 0
    var storeTokenCount = 0
    var refreshTokenCount = 0

    tokenClient = TokenClientLive(
      loadToken: {
        Just(TestToken(value: "localToken"))
          .setFailureType(to: TokenPersistenceError.self)
          .handleEvents(receiveSubscription: { _ in
            loadTokenCount += 1
          })
          .delay(for: 1, scheduler: self.testScheduler)
          .eraseToAnyPublisher()
      },
      storeToken: { _ in
        Fail(error: .storeTokenError)
          .handleEvents(receiveSubscription: { _ in
            storeTokenCount += 1
          })
          .delay(for: 1, scheduler: self.testScheduler)
          .eraseToAnyPublisher()
      },
      refreshTokenRequest: { invalidToken in
        Just(TestToken(value: "new_\(invalidToken)"))
          .setFailureType(to: TokenError.self)
          .handleEvents(receiveSubscription: { _ in
            refreshTokenCount += 1
          })
          .delay(for: 1, scheduler: self.testScheduler)
          .eraseToAnyPublisher()
      }
    )

    var errorReceived = false

    tokenClient.refresh()
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case let .failure(error):
            switch error.cause {
            case .localTokenError:
              errorReceived = true
            default:
              XCTFail("Unexpected event received - error: \(error).")
            }
          case .finished:
            XCTFail("Unexpected event received - finished.")
          }
        },
        receiveValue: { _ in
          XCTFail("Unexpected event received - value.")
        }
      )
      .store(in: &subscriptions)

    testScheduler.advance(by: 3)

    XCTAssertEqual(loadTokenCount, 1)
    XCTAssertEqual(storeTokenCount, 1)
    XCTAssertEqual(refreshTokenCount, 1)
    XCTAssertTrue(errorReceived)
  }
}
