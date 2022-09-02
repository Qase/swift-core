import Combine

public enum LoadingState<LoadingValue, LoadingError: Error> {
  case loading
  case loaded(LoadingValue)
  case failure(LoadingError)

}

public extension Publisher {
  func asLoadingPublisher() -> AnyPublisher<LoadingState<Output, Failure>, Never> {
    map { .loaded($0) }
      .catch { Just(.failure($0)) }
      .prepend(.loading)
      .eraseToAnyPublisher()
  }
}
