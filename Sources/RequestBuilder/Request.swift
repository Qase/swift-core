import Combine
import Foundation

public struct Request {
  private let initialURLRequestResult: Result<URLRequest, URLRequestError>
  private let builder: () -> URLRequestComponent

  public var urlRequest: Result<URLRequest, URLRequestError> {
    initialURLRequestResult
      .flatMap(builder().build)
  }

  public init(
    endpoint: String,
    @URLRequestBuilder builder: @escaping () -> URLRequestComponent = { URLRequestComponent.identity }
  ) {
    self.initialURLRequestResult = Result<URLRequest, URLRequestError>.from(
      optional: URL(string: endpoint),
      onNil: .endpointParsingError
    )
      .map { URLRequest(url: $0) }
    self.builder = builder
  }

  public init(
    initialRequest: Request,
    @URLRequestBuilder builder: @escaping () -> URLRequestComponent = { URLRequestComponent.identity }
  ) {
    self.initialURLRequestResult = initialRequest.urlRequest
    self.builder = builder
  }

  public init(
    initialURLRequest: URLRequest,
    @URLRequestBuilder builder: @escaping () -> URLRequestComponent = { URLRequestComponent.identity }
  ) {
    self.initialURLRequestResult = .success(initialURLRequest)
    self.builder = builder
  }
}
