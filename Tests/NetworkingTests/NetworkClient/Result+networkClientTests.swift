import Combine
import CombineSchedulers
import ErrorReporting
@testable import Networking
import RequestBuilder
import XCTest
import XCTestDynamicOverlay

// MARK: - Mocks

private extension Result where Success == URLRequest, Failure == URLRequestError {
  static var validMock: Self = .success(URLRequest(url: URL(string: "https://reqres.in/api/users/1")!))
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

private struct TestError: ErrorReporting, Equatable, NetworkErrorCapable {
  enum Cause {
    case networkError

    var description: String {
      switch self {
      case .networkError:
        return "networkError"
      }
    }
  }

  public var causeDescription: String {
    cause.description
  }

  public let cause: Cause
  public var stackID: UUID
  public var underlyingError: ErrorReporting?

  private init(
    stackID: UUID = UUID(),
    cause: Cause,
    underlyingError: ErrorReporting? = nil
  ) {
    self.stackID = stackID
    self.cause = cause
    self.underlyingError = underlyingError
  }

  static var networkError: Self {
    .init(cause: .networkError)
  }

  public static func == (lhs: TestError, rhs: TestError) -> Bool {
    lhs.isEqual(to: rhs)
  }
}

// MARK: - Tests

final class Request_networkClientTests: XCTestCase {
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

  func test_URLRequest_build_error() {
    networkClient = NetworkClient(
      urlSessionConfiguration: .default,
      urlRequester: .mock(),
      networkMonitorClient: .mock(),
      logUUID: UUID.init,
      loggerClient: .mock()
    )

    var errorReceived = false

    let request: Result<URLRequest, URLRequestError> = .failure(URLRequestError.invalidURLComponents)

    let response: AnyPublisher<(headers: [HTTPHeader], body: Data), TestError> = request
      .execute(using: networkClient)

    response
      .sink(
        receiveCompletion: { completion in
          Swift.print(completion)
          switch completion {
          case .finished:
            XCTFail("Unexpected event - finished.")
          case let .failure(error) where error.cause == .networkError && error.underlyingError is NetworkError:
            let networkError = (error.underlyingError as! NetworkError)
            if case .urlRequestBuilderError = networkError.cause, networkError.underlyingError is URLRequestError {
              errorReceived = true
            } else {
              XCTFail("Unexpected event - error \(error).")
            }
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

  func test_network_error() {
    let scheduler = DispatchQueue.immediate

    networkClient = NetworkClient(
      urlSessionConfiguration: .default,
      urlRequester: .failureMock(withError: URLError(.badServerResponse), delayedFor: 0, scheduler: scheduler),
      networkMonitorClient: .mockJust(value: .available, delayedFor: 0, scheduler: scheduler),
      logUUID: UUID.init,
      loggerClient: .mock()
    )

    var errorReceived = false

    let response: AnyPublisher<(headers: [HTTPHeader], body: Data), TestError> = Result.validMock
      .execute(using: networkClient)

    response
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            XCTFail("Unexpected event - finished.")
          case let .failure(error) where error.cause == .networkError && error.underlyingError is NetworkError:
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

  func test_successful_network_error_conversion() {
    let scheduler = DispatchQueue.immediate

    networkClient = NetworkClient(
      urlSessionConfiguration: .default,
      urlRequester: .failureMock(withError: URLError(.badServerResponse), delayedFor: 0, scheduler: scheduler),
      networkMonitorClient: .mockJust(value: .available, delayedFor: 0, scheduler: scheduler),
      logUUID: UUID.init,
      loggerClient: .mock()
    )

    var errorReceived = false

    let response: AnyPublisher<(headers: [HTTPHeader], body: Data), TestError> = Result.validMock
      .execute(
        using: networkClient,
        mapNetworkError: { _ in TestError.networkError }
      )

    response
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            XCTFail("Unexpected event - finished.")
          case let .failure(error) where error.cause == .networkError && error.underlyingError == nil:
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

  func test_successful_Data_response() {
    let scheduler = DispatchQueue.immediate

    networkClient = NetworkClient(
      urlSessionConfiguration: .default,
      urlRequester: .successMock(withResponse: (Data(), HTTPURLResponse.mock), delayedFor: 0, scheduler: scheduler),
      networkMonitorClient: .mockJust(value: .available, delayedFor: 0, scheduler: scheduler),
      logUUID: UUID.init,
      loggerClient: .mock()
    )

    var valueReceived = false
    var finished = false

    let response: AnyPublisher<(headers: [HTTPHeader], body: Data), TestError> = Result.validMock
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
        receiveValue: { _, data in
          XCTAssertEqual(data, Data())
          valueReceived = true
        }
      )
      .store(in: &subscriptions)

    XCTAssertTrue(valueReceived)
    XCTAssertTrue(finished)
  }

  func test_successful_Decodable_response() {
    let scheduler = DispatchQueue.immediate

    networkClient = NetworkClient(
      urlSessionConfiguration: .default,
      urlRequester: .successMock(withResponse: (Data.userMock, HTTPURLResponse.mock), delayedFor: 0, scheduler: scheduler),
      networkMonitorClient: .mockJust(value: .available, delayedFor: 0, scheduler: scheduler),
      logUUID: UUID.init,
      loggerClient: .mock()
    )

    var valueReceived = false
    var finished = false

    let response: AnyPublisher<(headers: [HTTPHeader], object: User), TestError> = Result.validMock
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
        receiveValue: { _, data in
          XCTAssertEqual(data, User.mock)
          valueReceived = true
        }
      )
      .store(in: &subscriptions)

    XCTAssertTrue(valueReceived)
    XCTAssertTrue(finished)
  }
}
