import KeyValueStorage
import XCTest

// MARK: - Mocks

private extension UserDefaults_KeyValueStorageTypeTests {
  struct User: Codable, Equatable {
    let name: String
    let age: Int
  }

  enum TestKeys: KeyProviding {
    case testKey(String)
    case testKey2(String)
    case testKey3

    var keyPrefix: String {
      switch self {
      case .testKey:
        return "testKey"
      case .testKey2:
        return "testKey2"
      case .testKey3:
        return "testKey3"
      }
    }

    var key: String {
      switch self {
      case let .testKey(value):
        return "\(keyPrefix)-\(value)"
      case let .testKey2(value):
        return "\(keyPrefix)-\(value)"
      case .testKey3:
        return keyPrefix
      }
    }
  }
}

// MARK: - Tests

final class UserDefaults_KeyValueStorageTypeTests: XCTestCase {
  private var sut: KeyValueStorageType!
  private let suiteName = "test"

  override func setUp() {
    super.setUp()

    sut = UserDefaults(suiteName: suiteName)
  }

  override func tearDown() {
    UserDefaults().removePersistentDomain(forName: suiteName)
    sut = nil

    super.tearDown()
  }

  func test_load_returns_no_data_when_nothing_is_stored() {
    let key = TestKeys.testKey("test_load_returns_no_data_when_nothing_is_stored")
    let loadResult = sut.load(forKey: key, ofType: String.self)

    XCTAssertEqual(loadResult, .success(nil))
  }

  func test_store_and_load_string() {
    let key = TestKeys.testKey("test_store_and_load_string")
    let testString = "myskoda"

    let storeResult = sut.store(testString, forKey: key)

    if case .failure(let error) = storeResult {
      XCTFail("Unexpected error received: \(error)")
    }

    let loadResult = sut.load(forKey: key, ofType: String.self)

    XCTAssertEqual(loadResult, .success(testString))
  }

  func test_store_and_load_int() {
    let key = TestKeys.testKey("test_store_and_load_int")
    let testInt = 100

    let storeResult = sut.store(testInt, forKey: key)

    if case .failure(let error) = storeResult {
      XCTFail("Unexpected error received: \(error)")
    }

    let loadResult = sut.load(forKey: key, ofType: Int.self)

    XCTAssertEqual(loadResult, .success(testInt))
  }

  func test_store_and_load_double() {
    let key = TestKeys.testKey("test_store_and_load_double")
    let testDouble = 100.1

    let storeResult = sut.store(testDouble, forKey: key)

    if case .failure(let error) = storeResult {
      XCTFail("Unexpected error received: \(error)")
    }

    let loadResult = sut.load(forKey: key, ofType: Double.self)

    XCTAssertEqual(loadResult, .success(testDouble))
  }

  func test_store_and_load_custom_object() {
    let key = TestKeys.testKey("test_store_and_load_custom_object")
    let testObject = User(name: "Peter", age: 23)

    let storeResult = sut.store(testObject, forKey: key)

    if case .failure(let error) = storeResult {
      XCTFail("Unexpected error received: \(error)")
    }

    let loadResult = sut.load(forKey: key, ofType: User.self)

    XCTAssertEqual(loadResult, .success(testObject))
  }

  func test_load_returns_error_when_store_and_load_types_mismatch() {
    let key = TestKeys.testKey("test_load_returns_error_when_store_and_load_types_mismatch")
    let testInt = 100

    _ = sut.store(testInt, forKey: key)

    let loadResult = sut.load(forKey: key, ofType: String.self)

    switch loadResult {
    case .success(let string):
      XCTFail("Unexpected data loaded: \(String(describing: string))")
    case .failure(let keyValueStorageError):
      switch keyValueStorageError.cause {
      case .decodingFailed:
        break
      default:
        XCTFail("Wrong error received: \(keyValueStorageError)")
      }
    }
  }

  func test_remove() {
    let key = TestKeys.testKey("test_delete")
    let testObject = User(name: "Peter", age: 23)

    _ = sut.store(testObject, forKey: key)

    let successLoadResult = sut.load(forKey: key, ofType: User.self)

    switch successLoadResult {
    case .success(let user):
      XCTAssertEqual(user, testObject)
    case .failure(let error):
      XCTFail("Unexpected error received: \(error)")
    }

    let removeResult = sut.remove(forKey: key)

    switch removeResult {
    case.success:
      break
    case .failure(let error):
      XCTFail("Unexpected error received: \(error)")
    }

    let loadResult = sut.load(forKey: key, ofType: String.self)

    XCTAssertEqual(loadResult, .success(nil))
  }

  func test_removeAll() {
    (1...20).forEach { index in
      let key = TestKeys.testKey("test_key_\(index)")
      let testObject = User(name: "Peter \(index)", age: 23)

      _ = sut.store(testObject, forKey: key)

      let successLoadResult = sut.load(forKey: key, ofType: User.self)

      switch successLoadResult {
      case .success(let user):
        XCTAssertEqual(user, testObject)
      case .failure(let error):
        XCTFail("Unexpected error received: \(error)")
      }
    }

    let removeAllResult = sut.removeAll()

    switch removeAllResult {
    case.success:
      break
    case .failure(let error):
      XCTFail("Unexpected error received: \(error)")
    }

    (1...20).forEach { index in
      let key = TestKeys.testKey("test_key_\(index)")
      let successLoadResult = sut.load(forKey: key, ofType: User.self)

      XCTAssertEqual(successLoadResult, .success(nil))
    }
  }
}
