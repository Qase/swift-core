//
//  KeychainQueryComponent.swift
//  
//
//  Created by Martin Troup on 12.09.2021.
//

import Foundation

struct KeychainQueryComponent {
    let build: (KeychainQueryValue) -> KeychainQueryValue

    init(_ build: @escaping (KeychainQueryValue) -> KeychainQueryValue) {
        self.build = build
    }
}

// MARK: - Instances

extension KeychainQueryComponent {
    static var identity: Self = .init { $0 }

    static func matchLimit(_ limit: KeychainQueryAttribute.Limit) -> Self {
        KeychainQueryComponent.attribute(.matchLimit(limit))
    }

    static func accessibility(_ accessibility: KeychainQueryAttribute.Accessibility) -> Self {
        KeychainQueryComponent.attribute(.accessibility(accessibility))
    }

    static func `class`(_ class: KeychainQueryAttribute.Class) -> Self {
        KeychainQueryComponent.attribute(.class(`class`))
    }

    static func key(_ key: String, prefix: String?) -> Self {
        KeychainQueryComponent.attribute(.key(key, prefix: prefix))
    }

    static func accessGroup(_ group: String) -> Self {
        KeychainQueryComponent.attribute(.accessGroup(group))
    }

    static func value(_ data: Data) -> Self {
        KeychainQueryComponent.attribute(.value(data))
    }

    static func returnData(_ value: Bool) -> Self {
        KeychainQueryComponent.attribute(.returnData(value))
    }
}

// MARK: - Helper instances

extension KeychainQueryComponent {
    private static func attribute(_ keychainAttribute: KeychainQueryAttribute) -> Self {
        .init { query in
            let (key, value) = keychainAttribute.queryItem

            var newQuery = query
            newQuery[key] = value
            return newQuery
        }
    }

    static func array(_ keychainAttributes: [KeychainQueryComponent]) -> Self {
        let combine: (KeychainQueryComponent, KeychainQueryComponent) -> KeychainQueryComponent = { component1, component2 in
            KeychainQueryComponent { component1.build($0).merging(component2.build($0)) { _, new in new } }
        }

        return .init { query in
            let combined = keychainAttributes.reduce(KeychainQueryComponent.identity, combine)

            return combined.build(query)
        }
    }

    static func array(_ keychainAttributes: KeychainQueryComponent...) -> Self {
        array(keychainAttributes)
    }
}
