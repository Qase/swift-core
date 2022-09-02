import Foundation
import LocalAuthentication

enum KeychainQueryAttribute {
  case `class`(Class)
  case service(String)
  case key(String)
  case accessGroup(String)
  case value(Data)
  case matchLimit(Limit)
  case returnData(Bool)
  case authenticationContext(LAContext)
  case accessControl(Protection, Flag)
  case returnAttributes(Bool)
  case returnRefference(Bool)

  var queryItem: (String, Any) {
    switch self {
    case let .class(value):
      return (kSecClass.string, value.queryValue)
    case let .service(value):
      return (kSecAttrService.string, value)
    case let .key(value):
      return (kSecAttrAccount.string, value)
    case let .accessGroup(value):
      return (kSecAttrAccessGroup.string, value)
    case let .value(value):
      return (String(kSecValueData), value)
    case let .matchLimit(value):
      return (kSecMatchLimit.string, value.queryValue)
    case let .returnData(value):
      return (kSecReturnData.string, value ? kCFBooleanTrue! : kCFBooleanFalse!)
    case let .authenticationContext(value):
      return (kSecUseAuthenticationContext.string, value)
    case let .accessControl(protection, flag):
      return (kSecAttrAccessControl.string, SecAccessControlCreateWithFlags(
        nil,
        protection.queryValue,
        flag.queryValue,
        nil
      ) as Any)
    case let .returnAttributes(value):
      return (kSecReturnAttributes.string, value ? kCFBooleanTrue! : kCFBooleanFalse!)
    case let .returnRefference(value):
      return (kSecReturnRef.string, value ? kCFBooleanTrue! : kCFBooleanFalse!)
    }
  }
}

extension KeychainQueryAttribute {
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

  enum Protection {
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

  enum Flag {
    case userPresence
    case biometryAny
    case biometryCurrentSet
    case devicePasscode
    case privateKeyUsage
    case applicationPassword

    var queryValue: SecAccessControlCreateFlags {
      switch self {
      case .userPresence:
        return .userPresence
      case .biometryAny:
        return .biometryAny
      case .biometryCurrentSet:
        return .biometryCurrentSet
      case .devicePasscode:
        return .devicePasscode
      case .privateKeyUsage:
        return .privateKeyUsage
      case .applicationPassword:
        return .applicationPassword
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
}

// MARK: - CFString + string

private extension CFString {
  var string: String { String(self) }
}
