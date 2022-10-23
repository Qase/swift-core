#if DEBUG
import Combine
import CoreToolkit

// MARK: - Stub

public class KeyValueStorageRemovingStub: KeyValueStorageRemoving {
  private let removeResult: Result<Void, KeyValueStorageError>
  private let removeAllResult: Result<Void, KeyValueStorageError>

  public init(
    remove: Result<Void, KeyValueStorageError> = .success(()),
    removeAll: Result<Void, KeyValueStorageError> = .success(())
  ) {
    self.removeResult = remove
    self.removeAllResult = removeAll
  }

  public func remove(forKey key: KeyProviding) -> Result<Void, KeyValueStorageError> {
    removeResult
  }

  public func removeAll() -> Result<Void, KeyValueStorageError> {
    removeAllResult
  }
}

// MARK: - Spy

public class KeyValueStorageRemovingSpy: KeyValueStorageTypeStub {
  private let onRemove: ((KeyProviding) -> Void)?
  private let onRemoveAll: (() -> Void)?

  public init(
    remove: Result<Void, KeyValueStorageError> = .success(()),
    removeAll: Result<Void, KeyValueStorageError> = .success(()),
    removeScope: Result<Void, KeyValueStorageError> = .success(()),
    onRemove: ((KeyProviding) -> Void)? = nil,
    onRemoveAll: (() -> Void)? = nil
  ) {
    self.onRemove = onRemove
    self.onRemoveAll = onRemoveAll

    super.init(remove: remove, removeAll: removeAll)
  }

  public override func remove(forKey key: KeyProviding) -> Result<Void, KeyValueStorageError> {
    onRemove?(key)
    return super.remove(forKey: key)
  }

  public override func removeAll() -> Result<Void, KeyValueStorageError> {
    onRemoveAll?()
    return super.removeAll()
  }
}

#endif
