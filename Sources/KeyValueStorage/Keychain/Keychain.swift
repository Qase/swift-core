import Foundation
import Security

struct KeychainErrorMessage: Error, CustomDebugStringConvertible {
  let value: String?

  var localizedDescription: String { debugDescription }
  var debugDescription: String { value ?? "" }
}

public final class Keychain {
  private let identifier: String
  private let accessGroup: String?

  public init(identifier: String, accessGroup: String? = nil) {
    self.identifier = identifier
    self.accessGroup = accessGroup
  }

  func store(
    _ data: Data,
    forKey key: String
  ) -> Result<Void, KeyValueStorageError> {
    let query = KeychainQuery(initialQuery: baseQuery) {
      KeychainQueryComponent.key(key)
      KeychainQueryComponent.value(data)
    }

    let status = SecItemAdd(query.cfDictionary, nil)

    if status == errSecDuplicateItem {
      return update(data, forKey: key)
    }

    guard status == noErr else {
      return .failure(.storeFailed(status.errorMessage))
    }

    return .success(())
  }

  func load(forKey key: String) -> Result<Data?, KeyValueStorageError> {
    let query = KeychainQuery(initialQuery: baseQuery) {
      KeychainQueryComponent.key(key)
      KeychainQueryComponent.returnData(true)
      KeychainQueryComponent.matchLimit(.one)
    }

    var dataTypeRef: AnyObject?

    let status: OSStatus = SecItemCopyMatching(query.cfDictionary, &dataTypeRef)

    if status == errSecItemNotFound {
      return .success(nil)
    }

    guard status == noErr else {
      return .failure(.loadFailed(status.errorMessage))
    }

    guard let data = dataTypeRef as? Data else {
      return .success(nil)
    }

    return .success(data)
  }

  func delete(key: String) -> Result<Void, KeyValueStorageError> {
    let query = KeychainQuery(initialQuery: baseQuery) {
      KeychainQueryComponent.key(key)
    }

    return delete(byQuery: query)
  }

  func deleteAll() -> Result<Void, KeyValueStorageError> {
    delete(byQuery: baseQuery)
  }
}

// MARK: - Private helpers

private extension Keychain {
  var baseQuery: KeychainQuery {
    KeychainQuery {
      KeychainQueryComponent.class(.genericPassword)
      KeychainQueryComponent.service(self.identifier)

      if let accessGroup = self.accessGroup {
        KeychainQueryComponent.accessGroup(accessGroup)
      }
    }
  }

  func update(_ data: Data, forKey key: String) -> Result<Void, KeyValueStorageError> {
    let updateQuery = KeychainQuery(initialQuery: baseQuery) {
      KeychainQueryComponent.key(key)
      KeychainQueryComponent.value(data)
    }

    let attributesToUpdateQuery = KeychainQuery {
      KeychainQueryComponent.value(data)
    }

    let status = SecItemUpdate(updateQuery.cfDictionary, attributesToUpdateQuery.cfDictionary)

    guard status == noErr else {
      return .failure(.storeFailed(status.errorMessage))
    }

    return .success(())
  }

  func delete(byQuery query: KeychainQuery) -> Result<Void, KeyValueStorageError> {
    let status = SecItemDelete(query.cfDictionary)

    guard status == noErr else {
      return .failure(.removeFailed(status.errorMessage))
    }

    return .success(())
  }
}

private extension OSStatus {
  var errorMessage: KeychainErrorMessage {
    KeychainErrorMessage(
      value: SecCopyErrorMessageString(self, nil)
        .map { $0 as NSString }
        .map(String.init)
    )
  }
}

extension Keychain {
  func getAllStoredKeys() -> [String] {
    let allItemsQuery = makeAllQuery()
    var dataTypeRef: AnyObject?

    guard SecItemCopyMatching(allItemsQuery, &dataTypeRef) == noErr else { return [] }

    return (dataTypeRef as? [[String: AnyObject]])?
      .compactMap { $0[kSecAttrAccount as String] as? String } ?? []
  }

  private func makeAllQuery() -> CFDictionary {
    KeychainQuery(initialQuery: baseQuery) {
      KeychainQueryComponent.matchLimit(.all)
      KeychainQueryComponent.returnAttributes(true)
      KeychainQueryComponent.returnReferrence(true)
    }
    .cfDictionary
  }
}
