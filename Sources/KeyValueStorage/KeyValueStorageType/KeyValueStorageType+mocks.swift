#if DEBUG
import Combine
import Foundation

// MARK: - Mock

public class KeyValueStorageTypeMock: KeyValueStorageType, KeyValueStorageRemoving, KeyValueStorageObservable {
  private let _store: (Encodable, KeyProviding, JSONEncoder) -> Result<Void, KeyValueStorageError>
  private let _remove: (KeyProviding) -> Result<Void, KeyValueStorageError>
  private let _removeAll: () -> Result<Void, KeyValueStorageError>
  private let _load: (KeyProviding, JSONDecoder) -> Result<Decodable?, KeyValueStorageError>
  private let observePublisher: AnyPublisher<Decodable?, KeyValueStorageError>

  public init(
    store: @escaping (Encodable, KeyProviding, JSONEncoder) -> Result<Void, KeyValueStorageError> = { _, _, _ in .success(()) },
    remove: @escaping (KeyProviding) -> Result<Void, KeyValueStorageError> = { _ in .success(()) },
    removeAll: @escaping () -> Result<Void, KeyValueStorageError> = { .success(()) },
    load: @escaping (KeyProviding, JSONDecoder) -> Result<Decodable?, KeyValueStorageError> = { _, _ in .success(nil) },
    observe: AnyPublisher<Decodable?, KeyValueStorageError> = Just(nil).setFailureType(to: KeyValueStorageError.self).eraseToAnyPublisher()
  ) {
    self._store = store
    self._remove = remove
    self._removeAll = removeAll
    self._load = load
    self.observePublisher = observe
  }

  public func store<T: Encodable>(
    _ object: T,
    forKey key: KeyProviding,
    jsonEncoder: JSONEncoder
  ) -> Result<Void, KeyValueStorageError> {
    _store(object, key, jsonEncoder)
  }

  public func remove(forKey key: KeyProviding) -> Result<Void, KeyValueStorageError> {
    _remove(key)
  }

  public func removeAll() -> Result<Void, KeyValueStorageError> {
    _removeAll()
  }

  public func load<T: Decodable>(
    forKey key: KeyProviding,
    jsonDecoder: JSONDecoder
  ) -> Result<T, KeyValueStorageError> {
    _load(key, jsonDecoder).map { value in
      guard let value = value as? T else { fatalError("Invalid value!") }

      return value
    }
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

// MARK: - Stub

public class KeyValueStorageTypeStub: KeyValueStorageTypeMock {
  public init(
    store: Result<Void, KeyValueStorageError> = .success(()),
    remove: Result<Void, KeyValueStorageError> = .success(()),
    removeAll: Result<Void, KeyValueStorageError> = .success(()),
    load: Result<Decodable?, KeyValueStorageError> = .success(nil),
    observe: AnyPublisher<Decodable?, KeyValueStorageError> = Just(nil).setFailureType(to: KeyValueStorageError.self).eraseToAnyPublisher()
  ) {
    super.init(
      store: { _, _, _ in store },
      remove: { _ in remove },
      removeAll: { removeAll },
      load: { _, _ in load },
      observe: observe
    )
  }
}

// MARK: - Spy

public class KeyValueStorageTypeSpy: KeyValueStorageTypeStub {
  private let onStore: ((Encodable, KeyProviding, JSONEncoder) -> Void)?
  private let onRemove: ((KeyProviding) -> Void)?
  private let onRemoveAll: (() -> Void)?
  private let onLoad: ((KeyProviding, JSONDecoder) -> Void)?
  private let onObserve: ((KeyProviding, JSONDecoder) -> Void)?

  public init(
    store: Result<Void, KeyValueStorageError> = .success(()),
    remove: Result<Void, KeyValueStorageError> = .success(()),
    removeAll: Result<Void, KeyValueStorageError> = .success(()),
    removeScope: Result<Void, KeyValueStorageError> = .success(()),
    load: Result<Decodable?, KeyValueStorageError> = .success(nil),
    observe: AnyPublisher<Decodable?, KeyValueStorageError> = Just(nil).setFailureType(to: KeyValueStorageError.self).eraseToAnyPublisher(),
    onStore: ((Encodable, KeyProviding, JSONEncoder) -> Void)? = nil,
    onRemove: ((KeyProviding) -> Void)? = nil,
    onRemoveAll: (() -> Void)? = nil,
    onLoad: ((KeyProviding, JSONDecoder) -> Void)? = nil,
    onObserve: ((KeyProviding, JSONDecoder) -> Void)? = nil
  ) {
    self.onStore = onStore
    self.onRemove = onRemove
    self.onRemoveAll = onRemoveAll
    self.onLoad = onLoad
    self.onObserve = onObserve

    super.init(store: store, remove: remove, removeAll: removeAll, load: load, observe: observe)
  }

  public override func store<T: Encodable>(
    _ object: T,
    forKey key: KeyProviding,
    jsonEncoder: JSONEncoder
  ) -> Result<Void, KeyValueStorageError> {
    onStore?(object, key, jsonEncoder)
    return super.store(object, forKey: key, jsonEncoder: jsonEncoder)
  }

  public override func remove(forKey key: KeyProviding) -> Result<Void, KeyValueStorageError> {
    onRemove?(key)
    return super.remove(forKey: key)
  }

  public override func removeAll() -> Result<Void, KeyValueStorageError> {
    onRemoveAll?()
    return super.removeAll()
  }

  public override func load<T: Decodable>(
    forKey key: KeyProviding,
    jsonDecoder: JSONDecoder
  ) -> Result<T, KeyValueStorageError> {
    onLoad?(key, jsonDecoder)
    return super.load(forKey: key, jsonDecoder: jsonDecoder)
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
