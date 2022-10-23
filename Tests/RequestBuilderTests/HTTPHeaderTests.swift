import RequestBuilder
import XCTest

class HTTPHeaderTests: XCTestCase {

  func test_init() {
    let sut = HTTPHeader(name: "name", value: "value")

    XCTAssertEqual(sut.name, "name")
    XCTAssertEqual(sut.value, "value")
  }

  func test_header_name_init() {
    let sut = HTTPHeader(name: .acceptType, value: "value")

    XCTAssertEqual(sut.name, HTTPHeaderName.acceptType.rawValue)
    XCTAssertEqual(sut.value, "value")
  }

  func test_accept_type_header() {
    let sut = HTTPHeader.accept(.json)

    XCTAssertEqual(sut.name, HTTPHeaderName.acceptType.rawValue)
    XCTAssertEqual(sut.value, AcceptTypeValue.json.rawValue)
  }

  func test_content_type_header() {
    let sut = HTTPHeader.contentType(.json)

    XCTAssertEqual(sut.name, HTTPHeaderName.contentType.rawValue)
    XCTAssertEqual(sut.value, ContentTypeValue.json.rawValue)
  }

  func test_valid_httpResponseHeaders_property() {
    let sut: HTTPResponseHeaders = [
      "name1": "value1",
      "name2": "value2",
      "name3": "value3"
    ]

    let expectedHeaders: [HTTPHeader] = [
      .init(name: "name1", value: "value1"),
      .init(name: "name2", value: "value2"),
      .init(name: "name3", value: "value3")
    ]

    let order: (HTTPHeader, HTTPHeader) -> Bool = { $0.name < $1.name }

    XCTAssertEqual(sut.httpHeaders.sorted(by: order), expectedHeaders.sorted(by: order))
  }

  func test_httpHeader_array_subscript() {
    let sut: [HTTPHeader] = [
      .init(name: "name1", value: "value1"),
      .accept(.json),
      .init(name: "name3", value: "value3")
    ]

    XCTAssertEqual(sut["name1"], "value1")
  }

  func test_httpHeader_array_httpHeaderName_subscript() {
    let sut: [HTTPHeader] = [
      .init(name: "name1", value: "value1"),
      .accept(.json),
      .init(name: "name3", value: "value3")
    ]

    XCTAssertEqual(sut[.acceptType], AcceptTypeValue.json.rawValue)
  }
}
