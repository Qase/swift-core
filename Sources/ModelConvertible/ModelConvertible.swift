import Foundation

public protocol ExternalModelConvertible {
  associatedtype ExternalModel
  associatedtype DomainModel

  func externalModel(fromDomain domainModel: DomainModel) -> ExternalModel?
}

public protocol DomainModelConvertible {
  associatedtype ExternalModel
  associatedtype DomainModel

  func domainModel(fromExternal externalModel: ExternalModel) -> DomainModel?
}

/// A protocol that can be used to implement custom model converter that can be used for
/// models that are to be converted from and to models from an external module.
public protocol ModelConvertible: ExternalModelConvertible, DomainModelConvertible {}

/// A pre-defined model converter that can be used for models that are to be converted from
/// and to models from an external module.
public struct ModelConverter<DomainModel, ExternalModel>: ModelConvertible {
  public typealias ExternalModelConverter = (DomainModel) -> ExternalModel?
  public typealias DomainModelConverter = (ExternalModel) -> DomainModel?

  private let externalModelConverter: ExternalModelConverter?
  private let domainModelConverter: DomainModelConverter?

  public init(
    externalModelConverter: ExternalModelConverter? = nil,
    domainModelConverter: DomainModelConverter? = nil
  ) {
    self.externalModelConverter = externalModelConverter
    self.domainModelConverter = domainModelConverter
  }

  public func externalModel(fromDomain domainModel: DomainModel) -> ExternalModel? {
    externalModelConverter?(domainModel)
  }

  public func domainModel(fromExternal externalModel: ExternalModel) -> DomainModel? {
    domainModelConverter?(externalModel)
  }
}
