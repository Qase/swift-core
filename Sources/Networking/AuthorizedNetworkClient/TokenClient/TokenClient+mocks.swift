#if DEBUG
import Combine
import Foundation

extension TokenClient {
  static func mock(
    currentToken: AnyPublisher<AnyToken, TokenError> = .fatalError,
    refreshToken: @escaping () -> AnyPublisher<Void, TokenError> = { fatalError("Not implemented!") },
    authorizedRequestBuilder: @escaping (URLRequest, AnyToken) -> URLRequest = { _, _ in fatalError("Not implemented!") }
  ) -> Self {
    .init(
      currentToken: currentToken,
      refreshToken: refreshToken,
      authorizedRequestBuilder: authorizedRequestBuilder
    )
  }
}
#endif
