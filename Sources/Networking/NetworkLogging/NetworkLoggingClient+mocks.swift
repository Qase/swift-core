#if DEBUG
import Foundation

extension NetworkLoggerClient {
  static func mock(
    logRequest: @escaping (UUID, URLRequest) -> Void = { _, _ in },
    logURLResponse: @escaping (UUID, URLResponse, Data?) -> Void = { _, _, _ in },
    logHTTPURLResponse: @escaping (UUID, HTTPURLResponse, Data?) -> Void = { _, _, _ in }
  ) -> Self {
    .init(
      logRequest: logRequest,
      logURLResponse: logURLResponse,
      logHTTPURLResponse: logHTTPURLResponse
    )
  }
}
#endif
