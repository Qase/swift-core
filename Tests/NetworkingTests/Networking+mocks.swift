import Foundation
import Networking

extension URL {
  static let mock = URL(string: "https://reqres.in/api/users/1")!
}

extension URLRequest {
  static var mock = URLRequest(url: URL.mock)
}

struct User: Codable, Equatable {
  let id: Int
  let firstName: String
  let lastName: String

  // mock:
  static let mock = User(id: 175_442, firstName: "John", lastName: "Doe")
}
