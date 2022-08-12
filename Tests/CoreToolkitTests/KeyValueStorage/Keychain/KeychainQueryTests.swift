//
//  KeychainQueryTests.swift
//  
//
//  Created by Martin Troup on 05.09.2021.
//

@testable import CoreToolkit
import OvertureOperators
import XCTest

class KeychainQueryTests: XCTestCase {
    func test_keychain_query() {
        let data = Data(repeating: 5, count: 10)

        let query: [String: Any] = [
            String(kSecClass): kSecClassGenericPassword,
            String(kSecAttrAccount): "prefix_key",
            String(kSecAttrAccessGroup): "access_group",
            String(kSecValueData): data,
            String(kSecMatchLimit): kSecMatchLimitOne,
            String(kSecReturnData): kCFBooleanTrue!,
            String(kSecAttrAccessible): kSecAttrAccessibleWhenUnlocked
        ]

        let builtQuery = KeychainQuery {
            KeychainQueryComponent.class(.genericPassword)
            KeychainQueryComponent.key("key", prefix: "prefix")
            KeychainQueryComponent.accessGroup("access_group")
            KeychainQueryComponent.value(data)
            KeychainQueryComponent.matchLimit(.one)
            KeychainQueryComponent.returnData(true)
            KeychainQueryComponent.accessibility(.accessibleWhenUnlocked)
        }


        XCTAssertEqual(query.cfDictionary, builtQuery.cfDictionary)
    }
}
