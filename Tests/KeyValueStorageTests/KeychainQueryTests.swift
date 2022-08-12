@testable import KeyValueStorage
import LocalAuthentication
import XCTest

class KeychainQueryTests: XCTestCase {
  func test_keychain_query() {
    let data = Data(repeating: 5, count: 10)
    let context = LAContext()

    let query: [String: Any] = [
      String(kSecClass): kSecClassGenericPassword,
      String(kSecAttrService): "service",
      String(kSecAttrAccount): "key",
      String(kSecAttrAccessGroup): "access_group",
      String(kSecValueData): data,
      String(kSecMatchLimit): kSecMatchLimitOne,
      String(kSecReturnData): kCFBooleanTrue!,
      String(kSecUseAuthenticationContext): context,
      String(kSecAttrAccessControl): SecAccessControlCreateWithFlags(
        nil,
        kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
        .biometryCurrentSet,
        nil
      ) as Any
    ]

    let builtQuery = KeychainQuery {
      KeychainQueryComponent.class(.genericPassword)
      KeychainQueryComponent.service("service")
      KeychainQueryComponent.key("key")
      KeychainQueryComponent.accessGroup("access_group")
      KeychainQueryComponent.value(data)
      KeychainQueryComponent.matchLimit(.one)
      KeychainQueryComponent.returnData(true)
      KeychainQueryComponent.authenticationContext(context)
      KeychainQueryComponent.accessControl(
        protection: .accessibleWhenPasscodeSetThisDeviceOnly,
        flag: .biometryCurrentSet
      )
    }

    XCTAssertEqual(query.cfDictionary, builtQuery.cfDictionary)
  }
}
