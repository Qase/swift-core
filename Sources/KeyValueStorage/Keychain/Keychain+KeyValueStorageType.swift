import Foundation

extension Keychain: KeyValueStorageType {
  public func store<T: Encodable>(
    _ object: T,
    forKey keyProvider: KeyProviding,
    jsonEncoder: JSONEncoder
  ) -> Result<Void, KeyValueStorageError> {
    do {
      let encodedData = try jsonEncoder.encode(object)
      return store(encodedData, forKey: keyProvider.key)
    } catch let error {
      return .failure(.decodingFailed(error))
    }
  }

  public func remove(forKey keyProvider: KeyProviding) -> Result<Void, KeyValueStorageError> {
    delete(key: keyProvider.key)
  }

  public func removeAll() -> Result<Void, KeyValueStorageError> {
    deleteAll()
  }

  public func load<T: Decodable>(
    forKey keyProvider: KeyProviding,
    jsonDecoder: JSONDecoder
  ) -> Result<T?, KeyValueStorageError> {
    load(forKey: keyProvider.key)
      .flatMap { data in
        do {
          guard let data = data else {
            return .success(nil)
          }

          return try .success(jsonDecoder.decode(T.self, from: data))
        } catch let error {
          return .failure(.decodingFailed(error))
        }
      }
  }
}
