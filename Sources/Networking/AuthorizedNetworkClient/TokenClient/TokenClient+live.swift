import Combine
import ErrorReporting
import Foundation

extension TokenClient {
  static func live(
    loadToken: @escaping () -> AnyPublisher<AnyToken, TokenPersistenceError>,
    isTokenValid: @escaping (AnyToken) -> AnyPublisher<Bool, Never>,
    storeToken: @escaping (AnyToken) -> AnyPublisher<Void, TokenPersistenceError>,
    refreshTokenRequest: @escaping (AnyToken) -> AnyPublisher<AnyToken, TokenError>,
    authorizedRequestBuilder: @escaping (URLRequest, AnyToken) -> URLRequest
  ) -> Self {
    let refreshTokenClientLive = TokenClientLive(
      loadToken: loadToken,
      isTokenValid: isTokenValid,
      storeToken: storeToken,
      refreshTokenRequest: refreshTokenRequest
    )

    return .init(
      currentToken: refreshTokenClientLive.currentToken,
      refreshToken: refreshTokenClientLive.refresh,
      authorizedRequestBuilder: authorizedRequestBuilder
    )
  }
}

// MARK: - TokenClientLive

public class TokenClientLive<AnyToken: TokenRepresenting> {
  private let loadToken: () -> AnyPublisher<AnyToken, TokenPersistenceError>
  private let isTokenValid: (AnyToken) -> AnyPublisher<Bool, Never>

  private let lock = NSRecursiveLock()
  private let refreshTokenRequestTrigger = PassthroughSubject<AnyToken, Never>()

  private let currentRefreshTokenSuccess = PassthroughSubject<AnyToken, Never>()
  private let currentRefreshTokenFailure = PassthroughSubject<TokenError, Never>()
  private let currentlyRefreshing = CurrentValueSubject<Bool, Never>(false)

  private var subscriptions = Set<AnyCancellable>()

  public init(
    loadToken: @escaping () -> AnyPublisher<AnyToken, TokenPersistenceError>,
    isTokenValid: @escaping (AnyToken) -> AnyPublisher<Bool, Never> = { _ in Just(true).eraseToAnyPublisher() },
    storeToken: @escaping (AnyToken) -> AnyPublisher<Void, TokenPersistenceError>,
    refreshTokenRequest: @escaping (AnyToken) -> AnyPublisher<AnyToken, TokenError>
  ) {
    self.loadToken = loadToken
    self.isTokenValid = isTokenValid

    let refreshTokenJob: (AnyToken) -> AnyPublisher<AnyToken, TokenError> = { [weak self] invalidToken in
      guard let self = self else {
        return Fail(error: GeneralError.weakNil(file: #file, line: #line))
          .mapErrorReporting(to: .refreshError)
          .eraseToAnyPublisher()
      }

      return refreshTokenRequest(invalidToken)
        .flatMap { newToken in
          storeToken(newToken)
            .map { _ in newToken }
            .mapErrorReporting(to: .localTokenError)
            .eraseToAnyPublisher()
        }
        .feedIsRunning(to: self.currentlyRefreshing)
        .eraseToAnyPublisher()
    }

    refreshTokenRequestTrigger
      .flatMapFirst { token in
        refreshTokenJob(token)
          .materialize()
          .eraseToAnyPublisher()
      }
      .sink(
        weak: self,
        receiveValue: { unwrappedSelf, value in
          switch value {
          case let .value(token):
            unwrappedSelf.currentRefreshTokenSuccess.send(token)
          case let .failure(error):
            unwrappedSelf.currentRefreshTokenFailure.send(error)
          case .finished:
            ()
          }
        }
      )
      .store(in: &subscriptions)
  }

  public var currentToken: AnyPublisher<AnyToken, TokenError> {
    currentlyRefreshing
      .filter(!)
      .prefix(1)
      .flatMap(weak: self, onWeakNil: .loadTokenError) { unwrappedSelf, _ in
        unwrappedSelf.loadToken()
          .eraseToAnyPublisher()
      }
      .mapErrorReporting(to: .localTokenError)
      .flatMap(weak: self, onWeakNil: .localTokenError) { unwrappedSelf, token in
        unwrappedSelf.isTokenValid(token)
          .map { (token: token, isValid: $0) }
          .eraseToAnyPublisher()
      }
      .flatMap { token, isTokenValid in
        isTokenValid
        ? Just(token).setFailureType(to: TokenError.self).eraseToAnyPublisher()
        : Fail(error: .tokenLocallyInvalid).eraseToAnyPublisher()
      }
      .eraseToAnyPublisher()
  }

  public func refresh() -> AnyPublisher<Void, TokenError> {
    let refreshTokenRequest = loadToken()
      .mapErrorReporting(to: TokenError.localTokenError)
      .map(weak: self, onWeakNil: .localTokenError) { unwrappedSelf, token -> AnyToken in
        unwrappedSelf.lock.lock()
        unwrappedSelf.refreshTokenRequestTrigger.send(token)
        unwrappedSelf.lock.unlock()

        return token
      }
      .map { _ in }
      .eraseToAnyPublisher()

    let refreshedToken = currentRefreshTokenSuccess
      .prefix(1)
      .setFailureType(to: TokenError.self)
      .eraseToAnyPublisher()

    let refreshTokenFailure = currentRefreshTokenFailure
      .flatMap { error -> AnyPublisher<AnyToken, TokenError> in
        Fail(error: error).eraseToAnyPublisher()
      }

    let refreshTokenResponse = Publishers.Amb(first: refreshedToken, second: refreshTokenFailure)

    return Publishers.Zip(refreshTokenRequest, refreshTokenResponse)
      .map { _ in }
      .eraseToAnyPublisher()
  }
}

// MARK: - Publisher + feedIsRunning

private extension Publisher {
  func feedIsRunning<S: Subject>(to subject: S) -> Publishers.HandleEvents<Self> where S.Output == Bool {
    self.handleEvents(
      receiveSubscription: { _ in subject.send(true) },
      receiveCompletion: { _ in subject.send(false) },
      receiveCancel: { subject.send(false) }
    )
  }
}
