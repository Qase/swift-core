//
//  Keychain+KeyValueStorageType.swift
//  
//
//  Created by Martin Troup on 05.09.2021.
//

import Foundation
import OvertureOperators

extension Keychain: KeyValueStorageType {
    public func decodable<Object: Decodable>(
        forKey key: String,
        jsonDecoder: JSONDecoder = JSONDecoder()
    ) -> Result<Object, KeyValueStorageError> {
        load(forKey: key)
            .flatMap { data in
                .execute({ try jsonDecoder.decode(Object.self, from: data) }, onThrows: KeyValueStorageError.loadError)
            }
    }

    public func store<Object: Encodable>(
        encodable object: Object,
        forKey key: String,
        jsonEncoder: JSONEncoder = JSONEncoder()
    ) -> Result<Void, KeyValueStorageError> {
        do {
            let encoded: Data = try jsonEncoder.encode(object)

            return store(encoded, forKey: key)
        } catch let error {
            return .failure(.storeError(error))
        }
    }

    public func delete(forKey key: String) -> Result<Void, KeyValueStorageError> {
        let query = KeychainQuery(initialQuery: baseQuery) {
            KeychainQueryComponent.key(key, prefix: self.keyPrefix)
        }

        return delete(byQuery: query)
    }
}
