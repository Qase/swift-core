import CoreDatabase

extension DatabaseRepository where DatabaseModel == TestModel, DomainModel == DomainTestModel {
  static func live(usingClient databaseClient: DatabaseClientType) -> Self {
    .init(
      databaseClient: databaseClient,
      databaseModelConverter: .live,
      domainModelConverter: .live
    )
  }
}
