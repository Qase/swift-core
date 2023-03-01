import KeyValueStorage
import Utils

public protocol TokenRepresenting: Codable, Equatable, CustomStringConvertible {
  associatedtype TokenType: KeyProviding, Hashable, Codable, CaseIterable

  var type: TokenType { get }
}
