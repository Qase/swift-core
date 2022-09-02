import Combine

public extension Publisher where Output: OptionalType {
  func ignoreNils() -> AnyPublisher<Output.Wrapped, Failure> {
    compactMap(\.value)
      .eraseToAnyPublisher()
  }
}

public protocol OptionalType {
  associatedtype Wrapped

  var value: Wrapped? { get }
}

extension Optional: OptionalType {
  public var value: Wrapped? { self }
}
