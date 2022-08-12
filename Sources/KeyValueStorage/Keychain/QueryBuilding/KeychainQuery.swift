import Foundation

struct KeychainQuery {
  private let initialQuery: KeychainQueryValue
  private let builder: () -> KeychainQueryComponent

  var keychainQueryValue: [String: Any] { builder().build(initialQuery) }
  var cfDictionary: CFDictionary { keychainQueryValue as CFDictionary }

  init(@KeychainQueryBuilder builder: @escaping () -> KeychainQueryComponent) {
    self.initialQuery = [:]
    self.builder = builder
  }

  init(initialQuery: KeychainQueryValue = [:], @KeychainQueryBuilder builder: @escaping () -> KeychainQueryComponent) {
    self.initialQuery = initialQuery
    self.builder = builder
  }

  init(initialQuery: KeychainQuery, @KeychainQueryBuilder builder: @escaping () -> KeychainQueryComponent) {
    self.initialQuery = initialQuery.keychainQueryValue
    self.builder = builder
  }
}
