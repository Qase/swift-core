import Combine
import CombineExtensions
import Network

public extension NetworkMonitorClient {
  static func live(onQueue queue: DispatchQueue) -> Self {
    .init(
      isNetworkAvailable: {
        .create { subscriber in
          var nwPathMonitor: NWPathMonitor? = NWPathMonitor()

          nwPathMonitor?.pathUpdateHandler = { path in
            subscriber.send(path.status == .satisfied)
          }

          nwPathMonitor?.start(queue: queue)

          return AnyCancellable {
            nwPathMonitor = nil
          }
        }
        .removeDuplicates()
        .eraseToAnyPublisher()
      }()
    )

  }
}
