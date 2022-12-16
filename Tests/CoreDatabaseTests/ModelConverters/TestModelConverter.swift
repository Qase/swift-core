import CoreDatabase

extension DatabaseModelConverter where DatabaseModel == TestModel, DomainModel == DomainTestModel {
  static var live: DatabaseModelConverter<TestModel, DomainTestModel> = .init { testModel, domainTestModel in
    testModel.id = domainTestModel.id
    testModel.name = domainTestModel.name
  }
}

extension DomainModelConverter where DatabaseModel == TestModel, DomainModel == DomainTestModel {
  static let live: Self = .init { testModel in
    DomainTestModel(id: testModel.id, name: testModel.name)
  }
}
