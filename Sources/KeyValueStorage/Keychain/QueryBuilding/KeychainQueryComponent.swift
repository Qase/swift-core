import Foundation
import LocalAuthentication

struct KeychainQueryComponent {
  let build: (KeychainQueryValue) -> KeychainQueryValue

  init(_ build: @escaping (KeychainQueryValue) -> KeychainQueryValue) {
    self.build = build
  }
}

// MARK: - Instances

extension KeychainQueryComponent {
  static var identity: Self = KeychainQueryComponent { $0 }

  static func matchLimit(_ limit: KeychainQueryAttribute.Limit) -> Self {
    .attribute(.matchLimit(limit))
  }

  static func `class`(_ class: KeychainQueryAttribute.Class) -> Self {
    .attribute(.class(`class`))
  }

  static func service(_ service: String) -> Self {
    .attribute(.service(service))
  }

  static func key(_ key: String) -> Self {
    .attribute(.key(key))
  }

  static func accessGroup(_ group: String) -> Self {
    .attribute(.accessGroup(group))
  }

  static func value(_ data: Data) -> Self {
    .attribute(.value(data))
  }

  static func returnData(_ value: Bool) -> Self {
    .attribute(.returnData(value))
  }

  static func authenticationContext(_ context: LAContext) -> Self {
    .attribute(.authenticationContext(context))
  }

  static func accessControl(
    protection: KeychainQueryAttribute.Protection,
    flag: KeychainQueryAttribute.Flag
  ) -> Self {
    .attribute(.accessControl(protection, flag))
  }

  static func returnAttributes(_ value: Bool) -> Self {
    .attribute(.returnAttributes(value))
  }

  static func returnReferrence(_ value: Bool) -> Self {
    .attribute(.returnRefference(value))
  }
}

// MARK: - Helper instances

extension KeychainQueryComponent {
  private static func attribute(_ keychainAttribute: KeychainQueryAttribute) -> Self {
    KeychainQueryComponent { query in
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

    return KeychainQueryComponent { query in
      let combined = keychainAttributes.reduce(KeychainQueryComponent.identity, combine)

      return combined.build(query)
    }
  }

  static func array(_ keychainAttributes: KeychainQueryComponent...) -> Self {
    array(keychainAttributes)
  }
}
