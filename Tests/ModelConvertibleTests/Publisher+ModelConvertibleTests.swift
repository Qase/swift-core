import Combine
import ErrorReporting
@testable import ModelConvertible
import XCTestDynamicOverlay
import XCTest

// MARK: - Mocks

private struct ExternalUser {
  let name: String
  let surname: String
  let address: String
}

private struct DomainUser {
  let firstName: String
  let lastName: String
  let localAddress: String
}

private struct TestError: ErrorReporting, Equatable, ModelConvertibleErrorCapable {
  enum Cause {
    case modelConvertibleError

    var description: String {
      switch self {
      case .modelConvertibleError:
        return "modelConvertibleError"
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

  static var modelConvertibleError: Self {
    .init(cause: .modelConvertibleError)
  }

  public static func == (lhs: TestError, rhs: TestError) -> Bool {
    lhs.isEqual(to: rhs)
  }
}

// MARK: - Tests

final class Publisher_ModelConvertibleTests: XCTestCase {
  var subscriptions = Set<AnyCancellable>()

  override func tearDown() {
    subscriptions = []

    super.tearDown()
  }

  private let converter = ModelConverter<DomainUser, ExternalUser>(
    externalModelConverter: { domainUser in
      ExternalUser(
        name: domainUser.firstName,
        surname: domainUser.lastName,
        address: domainUser.localAddress)
    },
    domainModelConverter: { externalUser in
      DomainUser(
        firstName: externalUser.name,
        lastName: externalUser.surname,
        localAddress: externalUser.address
      )
    }
  )

  func test_publisher_external_model_converting_success() {
    let externalUser = ExternalUser(
      name: "external-John",
      surname: "external-Doe",
      address: "external-random-address"
    )

    var valueReceived = false
    var finished = false

    let converted = Just(externalUser)
      .setFailureType(to: TestError.self)
      .convertToDomainModel(using: converter)

    converted
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            finished = true
          case let .failure(error):
            XCTFail("Unexpected event - failure: \(error)")
          }
        },
        receiveValue: { domainUser in
          XCTAssertEqual(domainUser.firstName, "external-John")
          XCTAssertEqual(domainUser.lastName, "external-Doe")
          XCTAssertEqual(domainUser.localAddress, "external-random-address")

          valueReceived = true
        }
      )
      .store(in: &subscriptions)

    XCTAssertTrue(valueReceived)
    XCTAssertTrue(finished)
  }

  func test_publisher_domain_model_converting_success() {
    let domainUser = DomainUser(
      firstName: "internal-John",
      lastName: "internal-Doe",
      localAddress: "internal-random-address"
    )

    var valueReceived = false
    var finished = false

    let converted = Just(domainUser)
      .setFailureType(to: TestError.self)
      .convertToExternalModel(using: converter)

    converted
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            finished = true
          case let .failure(error):
            XCTFail("Unexpected event - failure: \(error)")
          }
        },
        receiveValue: { externalUser in
          XCTAssertEqual(externalUser.name, "internal-John")
          XCTAssertEqual(externalUser.surname, "internal-Doe")
          XCTAssertEqual(externalUser.address, "internal-random-address")

          valueReceived = true
        }
      )
      .store(in: &subscriptions)

    XCTAssertTrue(valueReceived)
    XCTAssertTrue(finished)
  }

  func test_publisher_domain_model_converting_error() {
    let failingConverter = ModelConverter<DomainUser, ExternalUser>(
      externalModelConverter: { _ in nil },
      domainModelConverter: unimplemented("Should not be called!")
    )

    let domainUser = DomainUser(
      firstName: "internal-John",
      lastName: "internal-Doe",
      localAddress: "internal-random-address"
    )

    var errorReceived = false

    let converted = Just(domainUser)
      .setFailureType(to: TestError.self)
      .convertToExternalModel(using: failingConverter)

    converted
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            XCTFail("Unexpected event - finished.")
          case let .failure(error) where error.cause == .modelConvertibleError && error.underlyingError == nil:
            errorReceived = true
          case let .failure(error):
            XCTFail("Unexpected event - error \(error).")
          }
        },
        receiveValue: { body in
          XCTFail("Unexpected event - element: \(body).")
        }
      )
      .store(in: &subscriptions)

    XCTAssertTrue(errorReceived)
  }

  func test_publisher_external_model_converting_error() {
    let failingConverter = ModelConverter<DomainUser, ExternalUser>(
      externalModelConverter: unimplemented("Should not be called!"),
      domainModelConverter: { _ in nil }
    )

    let externalUser = ExternalUser(
      name: "external-John",
      surname: "external-Doe",
      address: "external-random-address"
    )

    var errorReceived = false

    let converted = Just(externalUser)
      .setFailureType(to: TestError.self)
      .convertToDomainModel(using: failingConverter)

    converted
      .sink(
        receiveCompletion: { completion in
          switch completion {
          case .finished:
            XCTFail("Unexpected event - finished.")
          case let .failure(error) where error.cause == .modelConvertibleError && error.underlyingError == nil:
            errorReceived = true
          case let .failure(error):
            XCTFail("Unexpected event - error \(error).")
          }
        },
        receiveValue: { body in
          XCTFail("Unexpected event - element: \(body).")
        }
      )
      .store(in: &subscriptions)

    XCTAssertTrue(errorReceived)
  }
}
