//
//  KeyValueStorageClient.swift
//  
//
//  Created by Martin Troup on 04.09.2021.
//

import Foundation

public protocol KeyValueStorageType {
    func store<Object: Encodable>(
        encodable object: Object,
        forKey key: String,
        jsonEncoder: JSONEncoder
    ) -> Result<Void, KeyValueStorageError>

    func decodable<Object: Decodable>(
        forKey key: String,
        jsonDecoder: JSONDecoder
    ) -> Result<Object, KeyValueStorageError>

    func delete(forKey key: String) -> Result<Void, KeyValueStorageError>
}

public extension KeyValueStorageType {
    func store<Object: Encodable>(
        encodable object: Object,
        forKey key: String
    ) -> Result<Void, KeyValueStorageError> {
        store(encodable: object, forKey: key, jsonEncoder: JSONEncoder())
    }

    func decodable<Object: Decodable>(
        forKey key: String
    ) -> Result<Object, KeyValueStorageError> {
        decodable(forKey: key, jsonDecoder: JSONDecoder())
    }
}
