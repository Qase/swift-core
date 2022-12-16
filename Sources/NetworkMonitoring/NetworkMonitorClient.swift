import Combine

public struct NetworkMonitorClient {
  public let isNetworkAvailable: AnyPublisher<Bool, Never>
}
