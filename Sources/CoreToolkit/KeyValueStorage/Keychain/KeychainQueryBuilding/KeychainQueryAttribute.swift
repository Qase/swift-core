//
//  KeychainQueryAttribute.swift
//  
//
//  Created by Martin Troup on 12.09.2021.
//

import Foundation

enum KeychainQueryAttribute {
    enum Limit {
        case one
        case all

        var queryValue: CFString {
            switch self {
            case .one:
                return kSecMatchLimitOne
            case .all:
                return kSecMatchLimitAll
            }
        }
    }

    enum Accessibility {
        case accessibleWhenUnlocked
        case accessibleWhenUnlockedThisDeviceOnly
        case accessibleWhenPasscodeSetThisDeviceOnly
        case accessibleAfterFirstUnlock
        case accessibleAfterFirstUnlockThisDeviceOnly

        var queryValue: CFString {
            switch self {
            case .accessibleWhenUnlocked:
                return kSecAttrAccessibleWhenUnlocked
            case .accessibleWhenUnlockedThisDeviceOnly:
                return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            case .accessibleWhenPasscodeSetThisDeviceOnly:
                return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
            case .accessibleAfterFirstUnlock:
                return kSecAttrAccessibleAfterFirstUnlock
            case .accessibleAfterFirstUnlockThisDeviceOnly:
                return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            }
        }
    }

    enum Class {
        case genericPassword

        var queryValue: CFString {
            switch self {
            case .genericPassword:
                return kSecClassGenericPassword
            }
        }
    }

    case `class`(Class)
    case key(String, prefix: String?)
    case accessGroup(String)
    case value(Data)
    case matchLimit(Limit)
    case returnData(Bool)
    case accessibility(Accessibility)

    var queryItem: (String, Any) {
        switch self {
        case let .class(value):
            return (kSecClass.string, value.queryValue)
        case let .key(value, prefix: prefix):
            return (kSecAttrAccount.string, prefix.map{ "\($0)_\(value)" } ?? "\(value)")
        case let .accessGroup(value):
            return (kSecAttrAccessGroup.string, value)
        case let .value(value):
            return (String(kSecValueData), value)
        case let .matchLimit(value):
            return (kSecMatchLimit.string, value.queryValue)
        case let .returnData(value):
            return (kSecReturnData.string, value ? kCFBooleanTrue! : kCFBooleanFalse!)
        case let .accessibility(value):
            return (kSecAttrAccessible.string, value.queryValue)
        }

    }
}

// MARK: - CFString + string

private extension CFString {
    var string: String { String(self) }
}
