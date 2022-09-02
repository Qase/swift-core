import Combine
import CombineExtensions
import Foundation

extension UserDefaults: KeyValueStorageObservable {
  public func observe<T: Decodable>(
    forKey keyProvider: KeyProviding,
    jsonDecoder: JSONDecoder
  ) -> AnyPublisher<T?, KeyValueStorageError> {
    dataObservingPublisher(forKey: keyProvider.key)
      .setFailureType(to: KeyValueStorageError.self)
      .flatMapResult { data -> Result<T?, KeyValueStorageError> in
        do {
          guard let data = data else {
            return .success(nil)
          }

          return try .success(jsonDecoder.decode(T.self, from: data))
        } catch let error {
          return .failure(.decodingFailed(error))
        }
      }
      .eraseToAnyPublisher()
  }
}
