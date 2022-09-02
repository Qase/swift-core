#if !os(watchOS)
import Combine
import CombineExtensions
import XCTest

// Source: https://github.com/CombineCommunity/CombineExt

class MaterializeTests: XCTestCase {
  var subscription: AnyCancellable?
  var values = [Event<String, MyError>]()
  var completed = false

  override func setUp() {
    values = []
    completed = false
  }

  override func tearDown() {
    subscription?.cancel()
  }

  enum MyError: Swift.Error {
    case someError
  }

  func testEmpty() {
    subscription = Empty<String, MyError>()
      .materialize()
      .sink(receiveCompletion: { _ in self.completed = true },
            receiveValue: { self.values.append($0) })

    XCTAssertEqual(values, [.finished])
    XCTAssertTrue(completed)
  }

  func testFail() {
    subscription = Fail<String, MyError>(error: .someError)
      .materialize()
      .sink(receiveCompletion: { _ in self.completed = true },
            receiveValue: { self.values.append($0) })

    XCTAssertEqual(values, [.failure(.someError)])
    XCTAssertTrue(completed)
  }

  func testFinished() {
    let subject = PassthroughSubject<String, MyError>()

    subscription = subject
      .materialize()
      .sink(receiveCompletion: { _ in self.completed = true },
            receiveValue: { self.values.append($0) })

    subject.send("Hello")
    subject.send("There")
    subject.send("World!")
    subject.send(completion: .finished)

    XCTAssertEqual(values, [
      .value("Hello"),
      .value("There"),
      .value("World!"),
      .finished
    ])

    XCTAssertTrue(completed)
  }

  func testValuesFinished() {
    let subject = PassthroughSubject<String, MyError>()
    var strings = [String]()

    subscription = subject
      .materialize()
      .values()
      .sink(receiveCompletion: { _ in self.completed = true },
            receiveValue: { strings.append($0) })

    subject.send("Hello")
    subject.send("There")
    subject.send("World!")
    subject.send(completion: .finished)

    XCTAssertEqual(strings, ["Hello", "There", "World!"])
    XCTAssertTrue(completed)
  }

  func testFailuresFinished() {
    let subject = PassthroughSubject<String, MyError>()
    var errors = [MyError]()

    subscription = subject
      .materialize()
      .failures()
      .sink(receiveCompletion: { _ in self.completed = true },
            receiveValue: { errors.append($0) })

    subject.send("Hello")
    subject.send("There")
    subject.send("World!")
    subject.send(completion: .finished)

    XCTAssertTrue(errors.isEmpty)
    XCTAssertTrue(completed)
  }

  func testError() {
    let subject = PassthroughSubject<String, MyError>()

    subscription = subject
      .materialize()
      .sink(receiveCompletion: { _ in self.completed = true },
            receiveValue: { self.values.append($0) })

    subject.send("Hello")
    subject.send("There")
    subject.send("World!")
    subject.send(completion: .failure(.someError))
    subject.send("Meh!")

    XCTAssertEqual(values, [
      .value("Hello"),
      .value("There"),
      .value("World!"),
      .failure(.someError)
    ])

    XCTAssertTrue(completed)
  }

  func testFailureesFinished() {
    let subject = PassthroughSubject<String, MyError>()
    var errors = [MyError]()

    subscription = subject
      .materialize()
      .failures()
      .sink(receiveCompletion: { _ in self.completed = true },
            receiveValue: { errors.append($0) })

    subject.send("Hello")
    subject.send("There")
    subject.send("World!")
    subject.send(completion: .finished)

    XCTAssertTrue(errors.isEmpty)
    XCTAssertTrue(completed)
  }

  func testFailuresFailure() {
    let subject = PassthroughSubject<String, MyError>()
    var errors = [MyError]()

    subscription = subject
      .materialize()
      .failures()
      .sink(receiveCompletion: { _ in self.completed = true },
            receiveValue: { errors.append($0) })

    subject.send("Hello")
    subject.send("There")
    subject.send("World!")
    subject.send(completion: .failure(.someError))

    XCTAssertEqual(errors, [.someError])
    XCTAssertTrue(completed)
  }
}
#endif
