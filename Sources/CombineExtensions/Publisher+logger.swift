import Combine

public extension Publisher {
  func log(
    logger log: @escaping (String) -> Void = { Swift.print($0) },
    loggingLifecycle: Bool = true,
    loggingCompletion: Bool = true,
    loggingValues: Bool = true,
    inFile file: String = #file,
    inFunction function: String = #function,
    onLine line: Int = #line
  ) -> Publishers.HandleEvents<Self> {
    handleEvents { subscription in
      guard loggingLifecycle else { return }

      log("receive subscription: (\(subscription))")
    } receiveOutput: { output in
      guard loggingValues else { return }

      log("receive value: (\(output))")
    } receiveCompletion: { completion in
      guard loggingCompletion else { return }

      log("receive completion: \(completion)")
    } receiveCancel: {
      guard loggingLifecycle else { return }

      log("receive cancel")
    } receiveRequest: { request in
      guard loggingLifecycle else { return }

      log("receive request: (\(request))")
    }
  }
}
