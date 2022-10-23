public enum HTTPMethod: String, CaseIterable {
  case head = "HEAD"
  case get = "GET"
  case patch = "PATCH"
  case post = "POST"
  case put = "PUT"
  case delete = "DELETE"
  case options = "OPTIONS"
  case trace = "TRACE"
  case connect = "CONNECT"
}
