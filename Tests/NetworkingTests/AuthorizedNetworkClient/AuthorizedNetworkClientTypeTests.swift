import Combine
import CombineSchedulers
import KeyValueStorage
@testable import Networking
import XCTest

class AuthorizedNetworkClientTypeTests: XCTestCase {
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

  var authorizedNetworkClient: AuthorizedNetworkClientType!

  var subscriptions = Set<AnyCancellable>()
  var testScheduler: TestScheduler<DispatchQueue.SchedulerTimeType, DispatchQueue.SchedulerOptions>!

  override func setUp() {
    super.setUp()

    testScheduler = DispatchQueue.test
  }

  override func tearDown() {
    subscriptions = []
    testScheduler = nil
    authorizedNetworkClient = nil

    super.tearDown()
  }
}

// MARK: - TokenBundle + mock

extension AuthorizedNetworkClientTypeTests.TestToken {
  static let mock = AuthorizedNetworkClientTypeTests.TestToken(value: "test-token")
}
