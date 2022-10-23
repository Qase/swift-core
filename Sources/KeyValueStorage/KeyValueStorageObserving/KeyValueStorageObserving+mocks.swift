#if DEBUG
import Combine
import CoreToolkit
import Foundation

// MARK: - Stub

public class KeyValueStorageObservingStub: KeyValueStorageObservable {
  private let observePublisher: AnyPublisher<Decodable?, KeyValueStorageError>

  public init(
    observe: AnyPublisher<Decodable?, KeyValueStorageError> = Just(nil).setFailureType(to: KeyValueStorageError.self).eraseToAnyPublisher()
  ) {
    self.observePublisher = observe
  }

  public func observe<T>(
    forKey: KeyProviding,
    jsonDecoder: JSONDecoder
  ) -> AnyPublisher<T?, KeyValueStorageError> where T: Decodable {
    observePublisher
      .map { $0 as? T }
      .eraseToAnyPublisher()
  }
}

// MARK: - Spy

public class KeyValueStorageObservingSpy: KeyValueStorageObservingStub {
  private let onObserve: ((KeyProviding, JSONDecoder) -> Void)?

  public init(
    observe: AnyPublisher<Decodable?, KeyValueStorageError> = Just(nil).setFailureType(to: KeyValueStorageError.self).eraseToAnyPublisher(),
    onObserve: ((KeyProviding, JSONDecoder) -> Void)? = nil
  ) {
    self.onObserve = onObserve

    super.init(observe: observe)
  }

  public override func observe<T>(
    forKey key: KeyProviding,
    jsonDecoder: JSONDecoder
  ) -> AnyPublisher<T?, KeyValueStorageError> where T: Decodable {
    onObserve?(key, jsonDecoder)
    return super.observe(forKey: key, jsonDecoder: jsonDecoder)
  }
}

#endif
