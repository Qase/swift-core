import Foundation

extension UserDefaults: KeyValueStorageType {
  public func store<T: Encodable>(
    _ object: T,
    forKey keyProvider: KeyProviding,
    jsonEncoder: JSONEncoder
  ) -> Result<Void, KeyValueStorageError> {
    do {
      let encodedData = try jsonEncoder.encode(object)

      return .success(store(encodedData, forKey: keyProvider.key))
    } catch let error {
      return .failure(.decodingFailed(error))
    }
  }

  public func remove(
    forKey keyProvider: KeyProviding
  ) -> Result<Void, KeyValueStorageError> {
    .success(delete(forKey: keyProvider.key))
  }

  public func removeAll() -> Result<Void, KeyValueStorageError> {
    .success(
      dictionaryRepresentation().keys
        .forEach(delete)
    )
  }

  public func load<T: Decodable>(
    forKey keyProvider: KeyProviding,
    jsonDecoder: JSONDecoder
  ) -> Result<T?, KeyValueStorageError> {
    guard let data = data(forKey: keyProvider.key) else {
      return .success(nil)
    }

    do {
      return try .success(jsonDecoder.decode(T.self, from: data))
    } catch let error {
      return .failure(.decodingFailed(error))
    }
  }
}
