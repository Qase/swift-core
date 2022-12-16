import Combine
import Foundation

public struct TokenClient<AnyToken: TokenRepresenting> {
  let currentToken: AnyPublisher<AnyToken, TokenError>
  let refreshToken: () -> AnyPublisher<Void, TokenError>
  let authorizedRequestBuilder: (URLRequest, AnyToken) -> URLRequest

  public init(
    currentToken: AnyPublisher<AnyToken, TokenError>,
    refreshToken: @escaping () -> AnyPublisher<Void, TokenError>,
    authorizedRequestBuilder: @escaping (URLRequest, AnyToken) -> URLRequest
  ) {
    self.currentToken = currentToken
    self.refreshToken = refreshToken
    self.authorizedRequestBuilder = authorizedRequestBuilder
  }
}
