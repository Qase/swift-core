import CoreToolkit
import KeyValueStorage

public protocol TokenRepresenting: Codable, Equatable, CustomStringConvertible {
  associatedtype TokenType: KeyProviding, Hashable, Codable, CaseIterable

  var type: TokenType { get }
}
