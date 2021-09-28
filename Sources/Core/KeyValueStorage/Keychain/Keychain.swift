//
//  Keychain.swift
//  
//
//  Created by Martin Troup on 04.09.2021.
//

import Foundation
import Overture
import OvertureOperators
import Security

public struct KeychainErrorMessage: Error, CustomDebugStringConvertible {
    public let value: String?

    public var localizedDescription: String { debugDescription }
    public var debugDescription: String { value ?? "" }
}

public class Keychain {
    let keyPrefix: String
    private let accessGroup: String?

    required public init(identifier: String, keyPrefix: String? = nil, accessGroup: String? = nil) {
        self.keyPrefix = keyPrefix ?? identifier
        self.accessGroup = accessGroup
    }

    var baseQuery: KeychainQuery {
        KeychainQuery {
            KeychainQueryComponent.class(.genericPassword)

            if let accessGroup = self.accessGroup {
                KeychainQueryComponent.accessGroup(accessGroup)
            }
        }
    }

    public func store(_ data: Data, forKey key: String) -> Result<Void, KeyValueStorageError> {
        let query = KeychainQuery(initialQuery: baseQuery) {
            KeychainQueryComponent.key(key, prefix: self.keyPrefix)
            KeychainQueryComponent.value(data)
        }

        let status = SecItemAdd(query.cfDictionary, nil)

        if status == errSecDuplicateItem {
            return update(data, forKey: key)
        }

        guard status == noErr else {
            return .failure(.storeError(status.errorMessage))
        }

        return .success(())
    }

    public func load(forKey key: String) -> Result<Data, KeyValueStorageError> {
        let query = KeychainQuery(initialQuery: baseQuery) {
            KeychainQueryComponent.key(key, prefix: self.keyPrefix)
            KeychainQueryComponent.returnData(true)
            KeychainQueryComponent.matchLimit(.one)
        }

        var dataTypeRef: AnyObject?

        let status: OSStatus = SecItemCopyMatching(query.cfDictionary, &dataTypeRef)

        if status == errSecItemNotFound {
            return .failure(.noData)
        }

        guard status == noErr else {
            return .failure(.loadError(status.errorMessage))
        }

        guard let data = dataTypeRef as? Data else {
            return .failure(.noData)
        }

        return .success(data)
    }

    private func update(_ data: Data, forKey key: String) -> Result<Void, KeyValueStorageError> {
        let updateQuery = KeychainQuery(initialQuery: baseQuery) {
            KeychainQueryComponent.value(data)
        }

        let attributesToUpdateQuery = KeychainQuery {
            KeychainQueryComponent.value(data)
        }

        let status = SecItemUpdate(updateQuery.cfDictionary, attributesToUpdateQuery.cfDictionary)

        guard status == noErr else {
            return .failure(.storeError(status.errorMessage))
        }

        return .success(())
    }

    func delete(byQuery query: KeychainQuery) -> Result<Void, KeyValueStorageError> {
        let status = SecItemDelete(query.cfDictionary)

        guard status == noErr else {
            return .failure(.deleteError(status.errorMessage))
        }

        return .success(())
    }

    public func deleteAll() -> Result<Void, KeyValueStorageError> {
        delete(byQuery: baseQuery)
    }

}

private extension OSStatus {
    var errorMessage: KeychainErrorMessage {
        SecCopyErrorMessageString(self, nil)
            .map { $0 as NSString }
            .map(String.init)
            |> KeychainErrorMessage.init(value:)
    }
}


