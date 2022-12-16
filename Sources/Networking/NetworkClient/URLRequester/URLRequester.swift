import Combine
import Foundation

public struct URLRequester {
  public typealias RequestFunction = (URLSessionConfiguration)
  -> (URLRequest)
  -> AnyPublisher<(data: Data, response: URLResponse), URLError>

  var request: RequestFunction

  init(request: @escaping RequestFunction) {
    self.request = request
  }
}
