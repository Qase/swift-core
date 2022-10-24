#if DEBUG
import Combine
import Foundation
import XCTestDynamicOverlay

extension TokenClient {
  static func mock(
    currentToken: AnyPublisher<AnyToken, TokenError> = AnyPublisher.fatalError,
    refreshToken: @escaping () -> AnyPublisher<Void, TokenError> = XCTUnimplemented("\(Self.self).refreshToken"),
    authorizedRequestBuilder: @escaping (URLRequest, AnyToken) -> URLRequest = XCTUnimplemented("\(Self.self).authorizedRequestBuilder")
  ) -> Self {
    .init(
      currentToken: currentToken,
      refreshToken: refreshToken,
      authorizedRequestBuilder: authorizedRequestBuilder
    )
  }
}
#endif
