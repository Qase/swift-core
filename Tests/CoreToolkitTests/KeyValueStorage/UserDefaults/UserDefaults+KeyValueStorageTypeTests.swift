//
//  UserDefaults+KeyValueStorageTypeTests.swift
//  
//
//  Created by Martin Troup on 04.09.2021.
//

import CoreToolkit
import XCTest

class UserDefaults_KeyValueStorageTypeTests: XCTestCase {
    struct User: Codable, Equatable {
        let name: String
        let surname: String
    }

    var keyValueStorage: KeyValueStorageType!

    let suitName = "testSuite"

    override func setUp() {
        super.setUp()

        keyValueStorage = UserDefaults(suiteName: suitName)
    }

    override func tearDown() {
        UserDefaults().removePersistentDomain(forName: suitName)
        keyValueStorage = nil

        super.tearDown()
    }

    func test_load_empty_store_load_update_load_delete_load_empty() {
        let testKey = "testKey"

        // Load empty
        var loaded: Result<User, KeyValueStorageError> = keyValueStorage.decodable(forKey: testKey)

        switch loaded {
        case let .success(data):
            XCTFail("Unexpected data loaded: \(data).")
        case let .failure(error):
            switch error.cause {
            case .noData:
                ()
            default:
                XCTFail("Unexpected error received: \(error).")
            }
        }

        // Store data
        let user = User(name: "John", surname: "Doe")

        let stored = keyValueStorage.store(encodable: user, forKey: testKey)

        switch stored {
        case .success:
            ()
        case let .failure(error):
            XCTFail("Unexpected error received: \(error).")
        }

        // Load data
        loaded = keyValueStorage.decodable(forKey: testKey)

        switch loaded {
        case let .success(loadedUser):
            XCTAssertEqual(loadedUser, user)
        case let .failure(error):
            XCTFail("Unexpected error received: \(error).")
        }

        // Update data
        let user2 = User(name: "John2", surname: "Doe2")

        let updated = keyValueStorage.store(encodable: user2, forKey: testKey)

        switch updated {
        case .success:
            ()
        case let .failure(error):
            XCTFail("Unexpected error received: \(error).")
        }

        // Load data
        loaded = keyValueStorage.decodable(forKey: testKey)

        switch loaded {
        case let .success(loadedUser):
            XCTAssertEqual(loadedUser, user2)
        case let .failure(error):
            XCTFail("Unexpected error received: \(error).")
        }

        // Delete data
        let deleted = keyValueStorage.delete(forKey: testKey)

        switch deleted {
        case .success:
            ()
        case let .failure(error):
            XCTFail("Unexpected error received: \(error).")
        }

        // Load empty
        loaded = keyValueStorage.decodable(forKey: testKey)

        switch loaded {
        case let .success(data):
            XCTFail("Unexpected data loaded: \(data).")
        case let .failure(error):
            switch error.cause {
            case .noData:
                ()
            default:
                XCTFail("Unexpected error received: \(error).")
            }
        }
    }
}
