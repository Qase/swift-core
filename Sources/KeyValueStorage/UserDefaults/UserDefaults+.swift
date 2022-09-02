import Foundation

extension UserDefaults {
  func store<Value>(_ value: Value, forKey key: String) {
    set(value, forKey: key)
  }

  func value<Value>(forKey key: String) -> Value? {
    object(forKey: key) as? Value
  }

  func delete(forKey key: String) {
    set(nil, forKey: key)
  }
}
