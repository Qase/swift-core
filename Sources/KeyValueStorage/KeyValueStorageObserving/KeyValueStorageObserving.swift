import Combine
import Foundation

public protocol KeyValueStorageObservable {
  func observe<T: Decodable>(forKey: KeyProviding, jsonDecoder: JSONDecoder) -> AnyPublisher<T?, KeyValueStorageError>
}

public extension KeyValueStorageObservable {
  func observe<T: Decodable>(forKey key: KeyProviding) -> AnyPublisher<T?, KeyValueStorageError> {
    observe(forKey: key, jsonDecoder: JSONDecoder())
  }

  func observe<T: Decodable>(
    forKey key: KeyProviding,
    ofType: T.Type,
    jsonDecoder: JSONDecoder = JSONDecoder()
  ) -> AnyPublisher<T?, KeyValueStorageError> {
    observe(forKey: key, jsonDecoder: jsonDecoder)
  }
}
