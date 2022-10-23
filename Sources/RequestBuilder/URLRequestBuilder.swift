import Foundation

@resultBuilder
public struct URLRequestBuilder {
  public static func buildBlock(_ param: URLRequestComponent) -> URLRequestComponent {
    param
  }

  public static func buildBlock(_ params: URLRequestComponent...) -> URLRequestComponent {
    URLRequestComponent.array(params)
  }

  public static func buildOptional(_ component: URLRequestComponent?) -> URLRequestComponent {
    component ?? URLRequestComponent.array([])
  }

  public static func buildEither(first component: URLRequestComponent) -> URLRequestComponent {
    component
  }

  public static func buildEither(second component: URLRequestComponent) -> URLRequestComponent {
    component
  }
}
