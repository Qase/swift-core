import Foundation

public struct NetworkLoggerClient {
  public let logRequest: (UUID, URLRequest) -> Void
  public let logURLResponse: (UUID, URLResponse, Data?) -> Void
  public let logHTTPURLResponse: (UUID, HTTPURLResponse, Data?) -> Void
}
