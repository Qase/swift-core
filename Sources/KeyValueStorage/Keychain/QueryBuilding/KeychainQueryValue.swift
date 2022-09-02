import Foundation

typealias KeychainQueryValue = [String: Any]

extension KeychainQueryValue {
  var cfDictionary: CFDictionary { self as CFDictionary }
}
