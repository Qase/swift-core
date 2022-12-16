@testable import ModelConvertible
import XCTest

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

final class ModelConvertibleTests: XCTestCase {
  private let converter = ModelConverter<DomainUser, ExternalUser>(
    externalModelConverter: { domainUser -> ExternalUser in
      ExternalUser(
        name: domainUser.firstName,
        surname: domainUser.lastName,
        address: domainUser.localAddress)
    },
    domainModelConverter: { externalUser -> DomainUser in
      DomainUser(
        firstName: externalUser.name,
        lastName: externalUser.surname,
        localAddress: externalUser.address
      )
    })

  func test_to_external_model_converter() {
    let externalUser = ExternalUser(
      name: "external-John",
      surname: "external-Doe",
      address: "external-random-address"
    )

    let domainUser = converter.domainModel(fromExternal: externalUser)

    XCTAssertEqual(domainUser?.firstName, "external-John")
    XCTAssertEqual(domainUser?.lastName, "external-Doe")
    XCTAssertEqual(domainUser?.localAddress, "external-random-address")
  }

  func test_to_internal_model_converter() {
    let domainUser = DomainUser(
      firstName: "internal-John",
      lastName: "internal-Doe",
      localAddress: "internal-random-address"
    )

    let externalUser = converter.externalModel(fromDomain: domainUser)

    XCTAssertEqual(externalUser?.name, "internal-John")
    XCTAssertEqual(externalUser?.surname, "internal-Doe")
    XCTAssertEqual(externalUser?.address, "internal-random-address")
  }
}
