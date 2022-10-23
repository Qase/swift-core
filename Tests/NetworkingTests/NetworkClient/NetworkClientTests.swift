import Combine
import CombineSchedulers
@testable import Networking
import XCTest

class NetworkClientTests: XCTestCase {
  var networkClient: NetworkClientType!

  var subscriptions = Set<AnyCancellable>()
  var testScheduler: TestScheduler<DispatchQueue.SchedulerTimeType, DispatchQueue.SchedulerOptions>!

  override func setUp() {
    super.setUp()

    testScheduler = DispatchQueue.test
  }

  override func tearDown() {
    subscriptions = []
    networkClient = nil
    testScheduler = nil

    super.tearDown()
  }
}
