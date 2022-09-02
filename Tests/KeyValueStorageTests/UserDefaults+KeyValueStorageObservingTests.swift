import Combine
import CombineSchedulers
import KeyValueStorage
import XCTest

// MARK: - Mocks

private extension UserDefaults_KeyValueStorageObservingTests {
  struct User: Codable, Equatable {
    let name: String
    let age: Int
  }

  enum TestKeys: KeyProviding {
    case testKey(String)

    var keyPrefix: String {
      switch self {
      case .testKey:
        return "testKey"
      }
    }

    var key: String {
      switch self {
      case let .testKey(value):
        return "\(keyPrefix)-\(value)"
      }
    }
  }
}

// MARK: - Tests

final class UserDefaults_KeyValueStorageObservingTests: XCTestCase {
  private var sut: (KeyValueStorageObservable & KeyValueStorageType)!
  private let suitName = "test"
  private var subscriptions = Set<AnyCancellable>()

  override func setUp() {
    super.setUp()

    sut = UserDefaults(suiteName: suitName)
  }

  override func tearDown() {
    subscriptions = []
    UserDefaults().removePersistentDomain(forName: suitName)
    sut = nil

    super.tearDown()
  }

  func test_observation_of_Int_values() {
    let key = TestKeys.testKey("test_observation_of_Int_values")

    var observedValues: [Int?] = []

    sut.observe(forKey: key, ofType: Int.self)
      .sink(
        receiveCompletion: { completion in
          XCTFail("Unexpected completion - \(completion).")
        },
        receiveValue: { newValue in
          observedValues.append(newValue)
        }
      )
      .store(in: &subscriptions)

    _ = sut.store(2, forKey: key)
    _ = sut.store(5, forKey: key)
    _ = sut.remove(forKey: key)
    _ = sut.store(8, forKey: key)
    _ = sut.store(1, forKey: key)

    XCTAssertEqual([nil, 2, 5, nil, 8, 1], observedValues)
  }

  func test_multiple_observations_of_Int_values() {
    let key = TestKeys.testKey("test_multiple_observations_of_Int_values")

    var observedValues1: [Int?] = []
    var observedValues2: [Int?] = []

    sut.observe(forKey: key, ofType: Int.self)
      .sink(
        receiveCompletion: { completion in
          XCTFail("Unexpected completion - \(completion).")
        },
        receiveValue: { newValue in
          observedValues1.append(newValue)
        }
      )
      .store(in: &subscriptions)

    sut.observe(forKey: key, ofType: Int.self)
      .sink(
        receiveCompletion: { completion in
          XCTFail("Unexpected completion - \(completion).")
        },
        receiveValue: { newValue in
          observedValues2.append(newValue)
        }
      )
      .store(in: &subscriptions)

    _ = sut.store(2, forKey: key)
    _ = sut.store(5, forKey: key)
    _ = sut.remove(forKey: key)
    _ = sut.store(8, forKey: key)
    _ = sut.store(1, forKey: key)

    XCTAssertEqual([nil, 2, 5, nil, 8, 1], observedValues1)
    XCTAssertEqual([nil, 2, 5, nil, 8, 1], observedValues2)
  }

  func test_observation_of_User_values() {
    let key = TestKeys.testKey("test_observation_of_User_values")

    var observedValues: [User?] = []

    _ = sut.store(User(name: "A", age: 10), forKey: key)

    sut.observe(forKey: key, ofType: User.self)
      .sink(
        receiveCompletion: { completion in
          XCTFail("Unexpected completion - \(completion).")
        },
        receiveValue: { newValue in
          observedValues.append(newValue)
        }
      )
      .store(in: &subscriptions)

    _ = sut.store(User(name: "B", age: 11), forKey: key)
    _ = sut.remove(forKey: key)
    _ = sut.store(User(name: "C", age: 12), forKey: key)
    _ = sut.store(User(name: "D", age: 13), forKey: key)

    XCTAssertEqual(
      [
        User(name: "A", age: 10),
        User(name: "B", age: 11),
        nil,
        User(name: "C", age: 12),
        User(name: "D", age: 13)
      ],
      observedValues
    )
  }

  func test_failure_when_observing_mismatch_type() {
    let key = TestKeys.testKey("test_failure_when_observing_mismatch_type")

    var errorReceived = false

    _ = sut.store(User(name: "A", age: 10), forKey: key)

    sut.observe(forKey: key, ofType: Int.self)
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case let .failure(error):
            switch error.cause {
            case .decodingFailed:
              errorReceived = true
            default:
              XCTFail("Unexpected failure - \(error).")
            }
          case .finished:
            XCTFail("Unexpected finished.")
          }
        },
        receiveValue: { newValue in
          XCTFail("Unexpected value received: \(String(describing: newValue)).")
        }
      )
      .store(in: &subscriptions)

    XCTAssertTrue(errorReceived)
  }

  func test_delayed_observation() {
    let testScheduler = DispatchQueue.test
    let key = TestKeys.testKey("test_delayed_observation")

    var observedValues: [Int?] = []

    sut.observe(forKey: key, ofType: Int.self)
      .sink(
        receiveCompletion: { completion in
          XCTFail("Unexpected completion - \(completion).")
        },
        receiveValue: { newValue in
          observedValues.append(newValue)
        }
      )
      .store(in: &subscriptions)

    testScheduler.schedule(after: testScheduler.now.advanced(by: 1)) {
      _ = self.sut.store(2, forKey: key)
    }

    testScheduler.schedule(after: testScheduler.now.advanced(by: 2)) {
      _ = self.sut.store(5, forKey: key)
    }

    testScheduler.schedule(after: testScheduler.now.advanced(by: 3)) {
      _ = self.sut.remove(forKey: key)
    }

    testScheduler.schedule(after: testScheduler.now.advanced(by: 4)) {
      _ = self.sut.store(8, forKey: key)
    }

    testScheduler.schedule(after: testScheduler.now.advanced(by: 5)) {
      _ = self.sut.store(1, forKey: key)
    }

    testScheduler.advance(by: 15)

    XCTAssertEqual([nil, 2, 5, nil, 8, 1], observedValues)
  }
}
