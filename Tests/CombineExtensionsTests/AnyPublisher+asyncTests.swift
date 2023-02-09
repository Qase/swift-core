import Combine
import CombineExtensions
import XCTest

class AnyPublisherAsyncTests: XCTestCase {
  enum MyError: Swift.Error {
    case failure
  }

  private var values = [String]()
  private let allValues = ["Hello", "World", "What's", "Up?"]

  func testAsyncPublisher() async throws {
    let publisher = Just(allValues)
      .setFailureType(to: MyError.self)
      .eraseToAnyPublisher()
    
    values = try await publisher.async()
    XCTAssertEqual(values, allValues)
  }

  func testAsyncPublisherFinishedWithouValue() async throws {
    let subject = PassthroughSubject<Int, MyError>()
    subject.send(completion: .finished)

    let publisher = subject.eraseToAnyPublisher()

    do {
      _ = try await publisher.async()
      XCTFail("Expected to throw while awaiting, but succeeded")
    } catch {
      XCTAssertEqual(error as? AsyncError, .finishedWithoutValue)
    }
  }

  func testAsyncPublisherFailed() async throws {
    let subject = PassthroughSubject<Int, MyError>()
    subject.send(completion: .failure(.failure))

    let publisher = subject.eraseToAnyPublisher()

    do {
      _ = try await publisher.async()
      XCTFail("Expected to throw while awaiting, but succeeded")
    } catch {
      XCTAssertEqual(error as? MyError, .failure)
    }
  }
}
