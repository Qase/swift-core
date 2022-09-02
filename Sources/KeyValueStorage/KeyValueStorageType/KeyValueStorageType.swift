import Foundation

/// Storage type for storing key-value data types.
///
/// Data is stored in key boxes. If `String` is saved with the same key as `Float`, `Float` value will be removed.
///
public protocol KeyValueStorageType: KeyValueStorageRemoving {

  /// Store data into the key-value storage.
  ///
  /// You can store either values (such as `String`, `Double`, `Int`,...) or objects that conform to `Encodable`.
  ///
  /// - Parameters:
  ///   - object: Object or value to store.
  ///   - forKey: Key to identify the stored data in the storage.
  ///   - jsonEncoder: JSON encoder.
  ///
  /// - Returns: `Void`, if the operation is successfull. `KeyValueStorageError`, if the operation is unsuccessfull.
  ///
  func store<T: Encodable>(
    _ object: T,
    forKey key: KeyProviding,
    jsonEncoder: JSONEncoder
  ) -> Result<Void, KeyValueStorageError>

  /// Load data from the key-value storage.
  ///
  /// You can load either values (such as `String`, `Double`, `Int`,...) or objects that conform to `Decodable`.
  ///
  /// - Parameters:
  ///   - forKey: Key to identify the data in the storage.
  ///   - jsonDecoder: JSON decoder.
  ///
  /// - Returns:
  ///   - Object or value, if the operation is successfull.
  ///   - `Nil` if value does not exist under given key.
  ///   - `KeyValueStorageError`, if the operation is unsuccessfull.
  ///
  func load<T: Decodable>(
    forKey key: KeyProviding,
    jsonDecoder: JSONDecoder
  ) -> Result<T?, KeyValueStorageError>
}

public extension KeyValueStorageType {
  func store<T: Encodable>(
    _ object: T,
    forKey key: KeyProviding,
    jsonEncoder: JSONEncoder = JSONEncoder()
  ) -> Result<Void, KeyValueStorageError> {
    store(object, forKey: key, jsonEncoder: jsonEncoder)
  }

  func load<T: Decodable>(
    forKey key: KeyProviding
  ) -> Result<T?, KeyValueStorageError> {
    load(forKey: key, jsonDecoder: JSONDecoder())
  }

  func load<T: Decodable>(
    forKey key: KeyProviding,
    ofType: T.Type,
    jsonDecoder: JSONDecoder = JSONDecoder()
  ) -> Result<T?, KeyValueStorageError> {
    load(forKey: key, jsonDecoder: jsonDecoder)
  }
}
