public protocol KeyValueStorageRemoving {
  /// Remove data from the key-value storage.
  ///
  /// - Parameters:
  ///   - forKey: Key to identify the data in the storage.
  ///
  /// - Returns: `Void`, if the operation is successfull. `KeyValueStorageError`, if the operation is unsuccessfull.
  ///
  func remove(forKey key: KeyProviding) -> Result<Void, KeyValueStorageError>

  /// Remove all data from the key-value storage.
  /// - Returns: `Void`, if the operation is successfull. `KeyValueStorageError`, if the operation is unsuccessfull.
  func removeAll() -> Result<Void, KeyValueStorageError>
}
