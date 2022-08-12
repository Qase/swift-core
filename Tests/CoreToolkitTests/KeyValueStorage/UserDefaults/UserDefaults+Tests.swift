//
//  UserDefaults+Tests.swift
//  
//
//  Created by Martin Troup on 05.09.2021.
//

import XCTest

class UserDefaults_Tests: XCTestCase {
    struct User: Equatable {
        let name: String
        let surname: String
    }

    var userDefaults: UserDefaults!

    let suitName = "testSuite"

    override func setUp() {
        super.setUp()

        userDefaults = UserDefaults(suiteName: suitName)
    }

    override func tearDown() {
        UserDefaults().removePersistentDomain(forName: suitName)
        userDefaults = nil

        super.tearDown()
    }

    func test_String_load_empty_store_load_delete_load_empty() {
        let testValue = "testString"
        let testKey = "testKey"

        // Load empty
        var value: String? = userDefaults.value(forKey: testKey)
        XCTAssertNil(value)

        // Store data
        userDefaults.store(value: testValue, forKey: testKey)

        // Load data
        value = userDefaults.value(forKey: testKey)
        XCTAssertEqual(value, testValue)

        // Update data
        let testValue2 = "testString2"

        userDefaults.store(value: testValue2, forKey: testKey)

        // Load data
        value = userDefaults.value(forKey: testKey)
        XCTAssertEqual(value, testValue2)

        // Delete date
        let _: Void = userDefaults.delete(forKey: testKey)

        // Load empty
        value = userDefaults.value(forKey: testKey)
        XCTAssertNil(value)
    }

    func test_Int_load_empty_store_load_delete_load_empty() {
        let testValue = 25
        let testKey = "testKey"

        // Load empty
        var value: Int? = userDefaults.value(forKey: testKey)
        XCTAssertNil(value)

        // Store data
        userDefaults.store(value: testValue, forKey: testKey)

        // Load data
        value = userDefaults.value(forKey: testKey)
        XCTAssertEqual(value, testValue)

        // Update data
        let testValue2 = 5

        userDefaults.store(value: testValue2, forKey: testKey)

        // Load data
        value = userDefaults.value(forKey: testKey)
        XCTAssertEqual(value, testValue2)

        // Delete date
        let _: Void = userDefaults.delete(forKey: testKey)

        // Load empty
        value = userDefaults.value(forKey: testKey)
        XCTAssertNil(value)
    }

    func test_Dictionary_load_empty_store_load_delete_load_empty() {
        let testUser: [String: String] = ["name": "John", "surname": "Doe"]
        let testKey = "testKey"

        // Load empty
        var user: [String: String]? = userDefaults.value(forKey: testKey)
        XCTAssertNil(user)

        // Store data
        userDefaults.store(value: testUser, forKey: testKey)

        // Load data
        user = userDefaults.value(forKey: testKey)
        XCTAssertEqual(user, testUser)

        // Update data
        let testUser2 = ["name": "John2", "surname": "Doe2"]

        userDefaults.store(value: testUser2, forKey: testKey)

        // Load data
        user = userDefaults.value(forKey: testKey)
        XCTAssertEqual(user, testUser2)

        // Delete date
        let _: Void = userDefaults.delete(forKey: testKey)

        // Load empty
        user = userDefaults.value(forKey: testKey)
        XCTAssertNil(user)
    }
}
