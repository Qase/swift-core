import Combine

public extension Publisher {
  func convertToExternalModel<E: Error, C: ExternalModelConvertible>(
    using converter: C,
    onNil: E
  ) -> AnyPublisher<C.ExternalModel, E> where Self.Output == C.DomainModel, Self.Failure == Never {
    flatMap { domainModel -> AnyPublisher<C.ExternalModel, E> in
      guard let externalModel = converter.externalModel(fromDomain: domainModel) else {
        return Fail(error: onNil).eraseToAnyPublisher()
      }

      return Just(externalModel)
        .setFailureType(to: E.self)
        .eraseToAnyPublisher()
    }
    .eraseToAnyPublisher()
  }

  func convertToDomainModel<E: Error, C: DomainModelConvertible>(
    using converter: C,
    onNil: E
  ) -> AnyPublisher<C.DomainModel, E> where Self.Output == C.ExternalModel, Self.Failure == Never {
    flatMap { externalModel -> AnyPublisher<C.DomainModel, E> in
      guard let domainModel = converter.domainModel(fromExternal: externalModel) else {
        return Fail(error: onNil).eraseToAnyPublisher()
      }

      return Just(domainModel)
        .setFailureType(to: E.self)
        .eraseToAnyPublisher()
    }
    .eraseToAnyPublisher()
  }
}
