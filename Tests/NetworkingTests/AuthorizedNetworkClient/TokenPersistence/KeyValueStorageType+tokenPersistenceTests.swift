import KeyValueStorage
import Networking
import Utils
import XCTest

class KeyValueStorageType_TokenPersistenceTests: XCTestCase {
  struct TestToken: TokenRepresenting {
    enum TokenType: String, KeyProviding, Hashable, Codable, CaseIterable {
      case typeA
      case typeB

      var keyPrefix: String { self.rawValue }
      var key: String { keyPrefix }
    }

    var type: TokenType
    var value: String

    init(value: String, type: TokenType) {
      self.value = value
      self.type = type
    }

    var description: String { "\(value)" }
  }

  func test_store_success() {
    var onStoreCalled = false

    let testToken = TestToken(value: "test-token", type: .typeB)

    let sut = KeyValueStorageTypeSpy(
      store: .success(()),
      onStore: { token, key, _ in
        XCTAssertEqual(token as? TestToken, testToken)
        XCTAssertEqual(key as? TestToken.TokenType, testToken.type)
        onStoreCalled = true
      }
    )

    let result = sut.store(token: testToken)

    switch result {
    case .success:
      XCTAssertTrue(onStoreCalled)
    case let .failure(error):
      XCTFail("Unexpected error: \(error).")
    }
  }

  func test_store_failure() {
    var onStoreCalled = false

    let testToken = TestToken(value: "test-token", type: .typeB)

    let sut = KeyValueStorageTypeSpy(
      store: .failure(.storeFailed(nil)),
      onStore: { token, key, _ in
        XCTAssertEqual(token as? TestToken, testToken)
        XCTAssertEqual(key as? TestToken.TokenType, testToken.type)
        onStoreCalled = true
      }
    )

    let result = sut.store(token: testToken)

    switch result {
    case .success:
      XCTFail("Unexpected success.")
    case let .failure(error):
      XCTAssertEqual(error.underlyingError as? KeyValueStorageError, .storeFailed(nil))
      XCTAssertTrue(onStoreCalled)
    }
  }

  func test_load_success() {
    var onLoadCalled = false

    let testToken = TestToken(value: "test-token", type: .typeB)

    let sut = KeyValueStorageTypeSpy(
      load: .success(testToken),
      onLoad: { key, _ in
        XCTAssertEqual(key as? TestToken.TokenType, testToken.type)
        onLoadCalled = true
      }
    )

    let result: Result<TestToken, TokenPersistenceError> = sut.load(forTokenType: testToken.type)

    switch result {
    case let .success(token):
      XCTAssertEqual(token, testToken)
      XCTAssertTrue(onLoadCalled)
    case let .failure(error):
      XCTFail("Unexpected error: \(error).")
    }
  }

  func test_load_failure() {
    var onLoadCalled = false

    let testToken = TestToken(value: "test-token", type: .typeB)

    let sut = KeyValueStorageTypeSpy(
      load: .failure(.loadFailed(nil)),
      onLoad: { key, _ in
        XCTAssertEqual(key as? TestToken.TokenType, testToken.type)
        onLoadCalled = true
      }
    )

    let result: Result<TestToken, TokenPersistenceError> = sut.load(forTokenType: testToken.type)

    switch result {
    case .success:
      XCTFail("Unexpected success.")
    case let .failure(error):
      XCTAssertEqual(error.underlyingError as? KeyValueStorageError, .loadFailed(nil))
      XCTAssertTrue(onLoadCalled)
    }
  }

  func test_load_nil_results_in_failure() {
    var onLoadCalled = false

    let testToken = TestToken(value: "test-token", type: .typeB)

    let sut = KeyValueStorageTypeSpy(
      load: .success(nil),
      onLoad: { key, _ in
        XCTAssertEqual(key as? TestToken.TokenType, testToken.type)
        onLoadCalled = true
      }
    )

    let result: Result<TestToken, TokenPersistenceError> = sut.load(forTokenType: testToken.type)

    switch result {
    case .success:
      XCTFail("Unexpected success.")
    case let .failure(error):
      XCTAssertEqual(error.underlyingError as? KeyValueStorageError, .loadFailed(nil))
      XCTAssertTrue(onLoadCalled)
    }
  }

  func test_remove_success() {
    var onRemoveCalled = false

    let testTokenType = TestToken.TokenType.typeB

    let sut = KeyValueStorageTypeSpy(
      remove: .success(()),
      onRemove: { key in
        XCTAssertEqual(key as? TestToken.TokenType, testTokenType)
        onRemoveCalled = true
      }
    )

    let result = sut.remove(forTokenType: testTokenType, ofType: TestToken.self)

    switch result {
    case .success:
      XCTAssertTrue(onRemoveCalled)
    case let .failure(error):
      XCTFail("Unexpected error: \(error).")
    }
  }

  func test_remove_failure() {
    var onRemoveCalled = false

    let testTokenType = TestToken.TokenType.typeB

    let sut = KeyValueStorageTypeSpy(
      remove: .failure(.removeFailed(nil)),
      onRemove: { key in
        XCTAssertEqual(key as? TestToken.TokenType, testTokenType)
        onRemoveCalled = true
      }
    )

    let result = sut.remove(forTokenType: .typeB, ofType: TestToken.self)

    switch result {
    case .success:
      XCTFail("Unexpected success.")
    case let .failure(error):
      XCTAssertEqual(error.underlyingError as? KeyValueStorageError, .removeFailed(nil))
      XCTAssertTrue(onRemoveCalled)
    }
  }
}
