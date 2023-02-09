import Combine
import Foundation
import RequestBuilder

// MARK: - AuthorizedNetworkClient

public struct AuthorizedNetworkClient<AnyToken: TokenRepresenting> {
  public let jsonDecoder: JSONDecoder
  let networkClient: NetworkClientType
  let tokenClient: TokenClient<AnyToken>
  let ignoreOutputOnError: (AuthorizedNetworkError) -> Bool

  private let errorSubject = PassthroughSubject<AuthorizedNetworkError, Never>()
  public var errorPublisher: AnyPublisher<AuthorizedNetworkError, Never> {
    errorSubject.eraseToAnyPublisher()
  }

  public init(
    jsonDecoder: JSONDecoder = JSONDecoder(),
    networkClient: NetworkClientType,
    tokenClient: TokenClient<AnyToken>,
    ignoreOutputOnError: @escaping (AuthorizedNetworkError) -> Bool = { _ in false }
  ) {
    self.jsonDecoder = jsonDecoder
    self.networkClient = networkClient
    self.tokenClient = tokenClient
    self.ignoreOutputOnError = ignoreOutputOnError
  }
}

// MARK: - AuthorizedNetworkClient + AuthorizedNetworkClientType

public extension AuthorizedNetworkClient {
  func authorizedRequest(
    _ urlRequest: URLRequest
  ) -> AnyPublisher<(headers: [HTTPHeader], body: Data), AuthorizedNetworkError> {
    Deferred<AnyPublisher<(headers: [HTTPHeader], body: Data), AuthorizedNetworkError>> {
      return tokenClient.currentToken
        .mapErrorReporting(to: .localTokenError)
        .map { tokenClient.authorizedRequestBuilder(urlRequest, $0) }
        .flatMap { urlRequest in
          networkClient.request(urlRequest)
            .mapErrorReporting(to: .networkError)
        }
        .whenUnauthorized(refresh: tokenClient.refreshToken)
        .handleEvents(receiveCompletion: { completion in
          if case let .failure(error) = completion {
            errorSubject.send(error)
          }
        })
        .catch { error -> AnyPublisher<(headers: [HTTPHeader], body: Data), AuthorizedNetworkError> in
          ignoreOutputOnError(error)
          ? Empty(completeImmediately: true).eraseToAnyPublisher()
          : Fail(error: error).eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    .eraseToAnyPublisher()
  }
}

// MARK: - Publisher + whenUnauthorized

private extension Publisher where Failure == AuthorizedNetworkError {
  func whenUnauthorized(
    refresh: @escaping () -> AnyPublisher<Void, TokenError>
  ) -> AnyPublisher<Self.Output, Self.Failure> {
    let retryingRefresh: () -> AnyPublisher<Void, AuthorizedNetworkError> = {
      refresh()
        .mapErrorReporting(to: .refreshTokenError)
        .retryWhen { errorPublisher in
          errorPublisher
            .scan([AuthorizedNetworkError]()) { $0 + [$1] }
            .flatMap { authorizedNetworkErrors -> AnyPublisher<Void, AuthorizedNetworkError> in
              // NOTE: Only retry 2x if refresh request fails with 4xx response code.
              guard
                authorizedNetworkErrors.count < 3,
                let currentError = authorizedNetworkErrors.last,
                !(currentError.containsUnauthorizedError || currentError.containsClientError)
              else {
                // NOTE: It is impossible for the errorPublisher not to emit any values, thus the force-unwrapping.
                return Fail<Void, AuthorizedNetworkError>(error: authorizedNetworkErrors.last!).eraseToAnyPublisher()
              }

              return Just(())
                .setFailureType(to: AuthorizedNetworkError.self)
                .eraseToAnyPublisher()
            }
        }
        .eraseToAnyPublisher()
    }

    return retryWhen { errorPublisher in
      errorPublisher
        .scan([AuthorizedNetworkError]()) { $0 + [$1] }
        .flatMap { authorizedNetworkErrors -> AnyPublisher<Void, Self.Failure> in
          guard
            // NOTE: First incoming 401 response runs token refreshing logic.
            // If the token refreshing logic succeeds, it runs the original request again.
            // If 401 response is received again, it will run the token refreshing logic once again.
            authorizedNetworkErrors.count < 3,
            let currentError = authorizedNetworkErrors.last,
            (currentError.containsUnauthorizedError || currentError.containsTokenLocallyInvalidError)
          else {
            // NOTE: It is impossible for the errorPublisher not to emit any values, thus the force-unwrapping.
            return Fail<Void, Self.Failure>(error: authorizedNetworkErrors.last!).eraseToAnyPublisher()
          }

          return retryingRefresh()
        }
    }
  }
}

// MARK: - AuthorizedNetworkClient + AuthorizedNetworkClientType

extension AuthorizedNetworkClient: AuthorizedNetworkClientType {}

// MARK: - AuthorizedNetworkClient + NetworkClientType

extension AuthorizedNetworkClient: NetworkClientType {
  public func request(_ urlRequest: URLRequest) -> AnyPublisher<(headers: [HTTPHeader], body: Data), NetworkError> {
    networkClient.request(urlRequest)
  }
}

// MARK: - AuthorizedNetworkError + computed

private extension AuthorizedNetworkError {
  var containsUnauthorizedError: Bool {
    contains(
      where: { innerError in
        guard case .unauthorized = (innerError as? NetworkError)?.cause else { return false }

        return true
      }
    )
  }

  var containsTokenLocallyInvalidError: Bool {
    contains(
      where: { innerError in
        guard case .tokenLocallyInvalid = (innerError as? TokenError)?.cause else { return false }

        return true
      }
    )
  }

  var containsClientError: Bool {
    contains(
      where: { innerError in
        guard case .clientError = (innerError as? NetworkError)?.cause else { return false }

        return true
      }
    )
  }
}
