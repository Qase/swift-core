//
//  UserDefaults+KeyValueStorageType.swift
//  
//
//  Created by Martin Troup on 05.09.2021.
//

import Foundation

extension UserDefaults: KeyValueStorageType {
    public func decodable<Object: Decodable>(forKey key: String, jsonDecoder: JSONDecoder = JSONDecoder()) -> Result<Object, KeyValueStorageError> {
        guard let data: Data = data(forKey: key) else {
            return .failure(.noData)
        }

        do {
            return try .success(jsonDecoder.decode(Object.self, from: data))
        } catch let error {
            return .failure(.loadError(error))
        }
    }

    public func store<Object: Encodable>(
        encodable object: Object,
        forKey key: String,
        jsonEncoder: JSONEncoder = JSONEncoder()
    ) -> Result<Void, KeyValueStorageError> {
        do {
            let encoded: Data = try jsonEncoder.encode(object)

            set(encoded, forKey: key)
            synchronize()

            return .success(())
        } catch let error {
            return .failure(.storeError(error))
        }
    }

    public func delete(forKey key: String) -> Result<Void, KeyValueStorageError> {
        .success(delete(forKey: key))
    }
}
