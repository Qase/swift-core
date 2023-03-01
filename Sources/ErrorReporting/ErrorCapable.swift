public protocol URLRequestBuilderErrorCapable {
  static var urlRequestBuilderError: Self { get }
}

public protocol NetworkErrorCapable {
  static var networkError: Self { get }
}

public protocol ModelConvertibleErrorCapable {
  static var modelConvertibleError: Self { get }
}
