import Foundation

@resultBuilder
struct KeychainQueryBuilder {
  static func buildBlock(_ params: KeychainQueryComponent...) -> KeychainQueryComponent {
    KeychainQueryComponent.array(params)
  }

  static func buildBlock(_ param: KeychainQueryComponent) -> KeychainQueryComponent {
    param
  }

  static func buildOptional(_ component: KeychainQueryComponent?) -> KeychainQueryComponent {
    component ?? .identity
  }
}
