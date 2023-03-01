import Utils
import XCTest

class Optional_Tests: XCTestCase {
  
  func test_nil_value_found() {
    let optionalInt: Int? = nil
    
    do {
      _ = try optionalInt.orThrow()
      XCTFail("Received unexpected value")
    } catch {
      XCTAssertTrue(error is OptionalValueIsNil)
    }
  }
  
  func test_optional_unwrapped() {
    let optionalInt: Int? = 5
    
    do {
      let unwrappedInt = try optionalInt.orThrow()
      XCTAssertEqual(unwrappedInt, 5)
    } catch {
      XCTFail("Unexpected event - failure: \(error)")
    }
  }
}
