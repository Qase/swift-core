import Combine

// Source: https://github.com/CombineCommunity/CombineExt

public extension Publisher {
  /// A variation on [share()](https://developer.apple.com/documentation/combine/publisher/3204754-share)
  /// that allows for buffering and replaying a `replay` amount of value events to future subscribers.
  ///
  /// - Parameter count: The number of value events to buffer in a first-in-first-out manner.
  /// - Returns: A publisher that replays the specified number of value events to future subscribers.
  func share(replay count: Int) -> Publishers.Autoconnect<Publishers.Multicast<Self, ReplaySubject<Output, Failure>>> {
    multicast { ReplaySubject(bufferSize: count) }
    .autoconnect()
  }
}
