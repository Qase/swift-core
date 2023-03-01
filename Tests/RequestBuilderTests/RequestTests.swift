@testable import RequestBuilder
import Utils
import XCTest

class RequestTests: XCTestCase {

  func test_urlRequest_compose_endpoint_with_no_parameters() {
    let sut = Request(endpoint: "https://www.google.com")

    switch sut.urlRequest {
    case .failure:
      XCTFail("Unexpected Result failure.")
    case let .success(urlRequest):
      XCTAssertEqual(urlRequest.url, URL(string: "https://www.google.com"))
      XCTAssertEqual(urlRequest.httpMethod, "GET")
    }
  }

  func test_urlRequest_compose_invalid_endpoint_still_succeeding() {
    let sut = Request(endpoint: "_")

    switch sut.urlRequest {
    case .failure:
      XCTFail("Unexpected Result failure.")
    case let .success(urlRequest):
      XCTAssertEqual(urlRequest.url?.absoluteString, "_")
      XCTAssertEqual(urlRequest.httpMethod, "GET")
    }
  }

  func test_urlRequest_compose_endpoint_with_parameters() {
    let sut = Request(endpoint: "https://www.google.com?param1=value1&param2=value2")

    switch sut.urlRequest {
    case .failure:
      XCTFail("Unexpected Result failure.")
    case let .success(urlRequest):
      XCTAssertEqual(urlRequest.url, URL(string: "https://www.google.com?param1=value1&param2=value2"))
      XCTAssertEqual(urlRequest.httpMethod, "GET")
    }
  }

  func test_urlRequest_compose_endpoint_with_argument_parameters() {
    let sut = Request(endpoint: "https://www.google.com") {
      ComponentArray(
        QueryParameter("param1", parameterValue: "value1"),
        QueryParameter("param2", parameterValue: "value2")
      )
    }

    switch sut.urlRequest {
    case .failure:
      XCTFail("Unexpected Result failure.")
    case let .success(urlRequest):
      let possibleExpectedURLs = [
        URL(string: "https://www.google.com?param1=value1&param2=value2"),
        URL(string: "https://www.google.com?param2=value2&param1=value1")
      ]

      XCTAssertTrue(possibleExpectedURLs.contains(urlRequest.url))
      XCTAssertEqual(urlRequest.httpMethod, "GET")
    }
  }

  func test_urlRequest_compose_endpoint_with_parameters_and_argument_parameters() {
    let sut = Request(endpoint: "https://www.google.com?param1=value1") {
      QueryParameter("param2", parameterValue: "value2")
    }

    switch sut.urlRequest {
    case .failure:
      XCTFail("Unexpected Result failure.")
    case let .success(urlRequest):
      let possibleExpectedURLs = [
        URL(string: "https://www.google.com?param1=value1&param2=value2"),
        URL(string: "https://www.google.com?param2=value2&param1=value1")
      ]

      XCTAssertTrue(possibleExpectedURLs.contains(urlRequest.url))
      XCTAssertEqual(urlRequest.httpMethod, "GET")
    }
  }

  func test_setting_method() {
    var sut = Request(endpoint: "https://www.google.com").urlRequest

    sut = URLRequest.with(method: .delete)(sut)

    switch sut {
    case let .success(urlRequest) where urlRequest.httpMethod == "DELETE":
      ()
    default:
      XCTFail("Unexpected result!")
    }

    sut = URLRequest.with(method: .post)(sut)

    switch sut {
    case let .success(urlRequest) where urlRequest.httpMethod == "POST":
      ()
    default:
      XCTFail("Unexpected result!")
    }
  }

  func test_setting_headers_to_empty_allHTTPHeaderFields() {
    let sut = Request(endpoint: "https://www.google.com") {
      ComponentArray(
        Header(.accept(.json)),
        Header(.contentType(.json))
      )
    }

    switch sut.urlRequest {
    case let .success(urlRequest):
      XCTAssertEqual(urlRequest.allHTTPHeaderFields, ["Content-Type": "application/json", "Accept": "application/json"])
    default:
      XCTFail("Unexpected result!")
    }

  }

  func test_setting_headers_to_non_empty_allHTTPHeaderFields() {
    var sut = URLRequest(url: URL(string: "https://www.google.com")!)
    sut.allHTTPHeaderFields = ["Content-Type": "application/json"]

    sut = URLRequest.with(headers: [.accept(.json)])(sut)

    XCTAssertEqual(sut.allHTTPHeaderFields, ["Content-Type": "application/json", "Accept": "application/json"])
  }

  func test_data_body_success() {
    let testBody = "test-body"

    let sut = Request(endpoint: "https://www.google.com") {
      Body(data: testBody.data(using: .utf8)!)
    }

    switch sut.urlRequest {
    case .failure:
      XCTFail("Unexpected Result failure.")
    case let .success(urlRequest):
      let httpBody = urlRequest.httpBody!

      XCTAssertEqual(String(decoding: httpBody, as: UTF8.self), testBody)
    }
  }

  func test_encodable_body_success() {
    struct User: Codable, Equatable {
      let name: String
      let surname: String
    }

    let user = User(name: "John", surname: "Doe")

    let sut = Request(endpoint: "https://www.google.com") {
      Body(encodable: user)
    }

    switch sut.urlRequest {
    case .failure:
      XCTFail("Unexpected Result failure.")
    case let .success(urlRequest):
      let httpBody = urlRequest.httpBody!
      let decodedUser = try! JSONDecoder().decode(User.self, from: httpBody)

      XCTAssertEqual(decodedUser, user)
    }
  }

  func test_encodable_body_failure() {
    struct EmptyError: Error {}

    struct User: Encodable {
      let name: String
      let surname: String

      func encode(to encoder: Encoder) throws {
        throw EmptyError()
      }
    }

    let user = User(name: "John", surname: "Doe")

    let sut = Request(endpoint: "https://www.google.com") {
      Body(encodable: user)
    }

    switch sut.urlRequest {
    case let .failure(error):
      switch error.cause {
      case let .bodyEncodingError(innerError) where innerError is EmptyError:
        ()
      default:
        XCTFail("Unexpected Result failure.")
      }
    case .success:
      XCTFail("Unexpected Result success.")
    }
  }

  func test_build_optional_for_request() {
    var isPresent: Bool?

    var sut = Request(endpoint: "https://www.google.com") {
      if isPresent != nil {
        Body(data: Data())
      }
    }

    XCTAssertNotNil(sut.urlRequest.success)
    XCTAssertNil(sut.urlRequest.success?.httpBody)

    isPresent = true

    sut = Request(initialRequest: sut) {
      if let isPresent = isPresent, isPresent {
        Body(data: Data())
      }
    }

    XCTAssertNotNil(sut.urlRequest.success)
    XCTAssertEqual(sut.urlRequest.success?.httpBody, Data())
  }

  func test_build_either_for_request() {
    let isPresent = false

    let sut = Request(endpoint: "https://www.google.com") {
      if isPresent {
        Body(data: Data(count: 3))
      } else {
        Body(data: Data(count: 4))
      }
    }

    XCTAssertNotNil(sut.urlRequest.success)
    XCTAssertEqual(sut.urlRequest.success?.httpBody, Data(count: 4))
  }

  func test_percent_encoded_query_parameter_added() {
    let email = "martin.kolomaznik+100@etnetera.cz"
    var validQueryCharacters = CharacterSet.urlQueryAllowed
    validQueryCharacters.remove("+")

    guard let safeEmail = email.addingPercentEncoding(withAllowedCharacters: validQueryCharacters) else {
      XCTFail()
      return
    }

    let sut = Request(endpoint: "https://www.google.com") {
      PercentEncodedQueryParameter("login_hint", encodedValue: safeEmail)
    }

    XCTAssertNotNil(sut.urlRequest.success?.url?.query)
    XCTAssertTrue(sut.urlRequest.success!.url!.query!.contains("martin.kolomaznik%2B100@etnetera.cz"))
  }
}
