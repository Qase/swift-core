import Combine
import CoreToolkit
import Foundation
import KeyValueStorage

public extension KeyValueStorageType {
  func store<Token: TokenRepresenting>(
    token: Token,
    jsonEncoder: JSONEncoder = JSONEncoder()
  ) ->Result<Void, TokenPersistenceError> {
    store(token, forKey: token.type, jsonEncoder: jsonEncoder)
      .mapErrorReporting(to: .storeTokenError)
  }

  func load<Token: TokenRepresenting>(
    forTokenType key: Token.TokenType,
    jsonDecoder: JSONDecoder = JSONDecoder()
  ) -> Result<Token, TokenPersistenceError> {
    load(forKey: key, jsonDecoder: jsonDecoder)
      .flatMap { (token: Token?) -> Result<Token, KeyValueStorageError> in
        guard let token = token else {
          return .failure(.loadFailed(nil))
        }

        return .success(token)
      }
      .mapErrorReporting(to: .loadTokenError)
  }

  func remove<Token: TokenRepresenting>(
    forTokenType key: Token.TokenType,
    ofType: Token.Type
  ) -> Result<Void, TokenPersistenceError> {
    remove(forKey: key)
      .mapErrorReporting(to: .deleteTokenError)
  }
}
