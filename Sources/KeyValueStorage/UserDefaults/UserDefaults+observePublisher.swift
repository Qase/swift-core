import Combine
import Foundation

public extension UserDefaults {
  struct Publisher<Value>: Combine.Publisher {
    private let userDefaults: UserDefaults
    private let key: String
    private let loadValue: () -> Value?

    init(
      userDefaults: UserDefaults,
      key: String,
      loadValue: @escaping () -> Value?
    ) {
      self.userDefaults = userDefaults
      self.key = key
      self.loadValue = loadValue
    }

    public func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
      let subscription = Subscription(subscriber: subscriber, userDefaults: userDefaults, key: key, loadValue: loadValue)
      subscriber.receive(subscription: subscription)
    }
  }
}

public extension UserDefaults.Publisher {
  typealias Output = Value?
  typealias Failure = Never
}

private extension UserDefaults {
  final class Subscription<S: Subscriber>: NSObject, Combine.Subscription {
    private var subscriber: S?
    private let userDefaults: UserDefaults
    private let key: String
    private var requestedDemand: Subscribers.Demand = .none
    private var loadValue: (() -> Value)?
    private var isRunning: Bool = false

    init(
      subscriber: S,
      userDefaults: UserDefaults,
      key: String,
      loadValue: @escaping () -> Value
    ) {
      self.subscriber = subscriber
      self.userDefaults = userDefaults
      self.key = key
      self.loadValue = loadValue

      super.init()
    }

    /// Publishes the current value to the subscriber.
    private func publish() {
      guard let subscriber = subscriber, let loadValue = loadValue, requestedDemand > .none else { return }

      requestedDemand -= .max(1)

      let newDemand = subscriber.receive(loadValue())

      if newDemand != .none {
        requestedDemand += newDemand
      }
    }

    // NOTE: We cannot use block based KVO since it leverages KeyPaths for observing.
    // For using KeyPaths it is required to know the observed attributes at compile time.
    // KeyValueStorageObserving enables to observe based on given key which is unknown at the compile time.
    // The recommended block based KVO does not fit well with the architecture of the app and thus cannot be used.
    // swiftlint:disable:next block_based_kvo
    override func observeValue(
      forKeyPath keyPath: String?,
      of object: Any?,
      change: [NSKeyValueChangeKey: Any]?,
      context: UnsafeMutableRawPointer?
    ) {
      guard keyPath == key else { return }

      publish()
    }

    func request(_ demand: Subscribers.Demand) {
      if demand != .none {
        requestedDemand += demand
      }

      guard !isRunning else { return }

      isRunning = true

      userDefaults.addObserver(self, forKeyPath: key, options: [], context: nil)
      publish()
    }

    func cancel() {
      userDefaults.removeObserver(self, forKeyPath: key)
      subscriber = nil
      loadValue = nil
    }
  }
}

private extension UserDefaults.Subscription {
  typealias Value = S.Input
}

public extension UserDefaults {
  func dataObservingPublisher(forKey key: String) -> UserDefaults.Publisher<Data> {
    Publisher<Data>(userDefaults: self, key: key) { self.data(forKey: key) }
  }
}
