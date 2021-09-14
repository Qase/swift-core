//
//  Publisher_retryWhenTests.swift
//  
//
//  Created by Martin Troup on 22.08.2021.
//

import Combine
import CombineExt
import CombineSchedulers
import XCTest

class Publisher_retryWhenTests: XCTestCase {
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()

        cancellables = []
    }

    enum TestError: Error, Equatable {
        case errorNum1
        case errorNum2
    }

    func test_retryWhen_immediate_success_skipping_retry() {
        let testScheduler = DispatchQueue.test

        let source: AnyPublisher<String, TestError> = Just("Success!").setFailureType(to: TestError.self)
            .delay(for: 1, scheduler: testScheduler)
            .eraseToAnyPublisher()

        var valueReceived = false
        var finishedReceived = false

        source
            .retryWhen { errorSignal -> AnyPublisher<Void, TestError> in
                errorSignal
                    .flatMap { error -> AnyPublisher<Void, TestError> in
                        Fail(error: TestError.errorNum2)
                            .eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case let .failure(error):
                        XCTFail("Unexpected event received - error: \(error).")
                    case .finished:
                        finishedReceived = true
                    }
                }, receiveValue: { value in
                    XCTAssertEqual(value, "Success!")
                    valueReceived = true
                }
            )
            .store(in: &cancellables)

        testScheduler.advance(by: 1)

        XCTAssertTrue(valueReceived)
        XCTAssertTrue(finishedReceived)
    }

    func test_retryWhen_failing_retry() {
        let testScheduler = DispatchQueue.test

        let source: AnyPublisher<String, TestError> = Fail(error: .errorNum1)
            .delay(for: 1, scheduler: testScheduler)
            .eraseToAnyPublisher()

        var errorReceived = false

        source
            .retryWhen { errorSignal -> AnyPublisher<Void, TestError> in
                errorSignal
                    .flatMap { _ -> AnyPublisher<Void, TestError> in
                        Fail(error: TestError.errorNum2)
                            .delay(for: 1, scheduler: testScheduler)
                            .eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case let .failure(error):
                        XCTAssertEqual(error, .errorNum2)
                        errorReceived = true
                    case .finished:
                        XCTFail("Unexpected event received - finished.")
                    }
                }, receiveValue: { value in
                    XCTFail("Unexpected event received - value: \(value).")
                }
            )
            .store(in: &cancellables)

        testScheduler.advance(by: 2)

        XCTAssertTrue(errorReceived)
    }

    func test_retryWhen_multiple_events_cause_multiple_retries() {
        let testScheduler = DispatchQueue.test

        var emitCount = 0

        let source = Publishers.Create<String, TestError> { factory in
            let emit = {
                defer { emitCount += 1 }

                if emitCount == 2 {
                    factory.send("Success!")
                    factory.send(completion: .finished)
                } else {
                    factory.send(completion: .failure(.errorNum1))
                }
            }

            emit()

            return AnyCancellable {}
        }

        var valueReceived = false
        var finishedReceived = false

        source
            .delay(for: 1, scheduler: testScheduler)
            .retryWhen { errorSignal -> AnyPublisher<Void, TestError> in
                errorSignal
                    .flatMap { error -> AnyPublisher<Void, TestError> in
                        return Publishers.Create<Void, TestError> { factory in
                            factory.send(())
                            factory.send(())
                            factory.send(completion: .finished)

                            return AnyCancellable { }
                        }
                        .eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case let .failure(error):
                        XCTFail("Unexpected event received - error: \(error).")
                    case .finished:
                        finishedReceived = true
                    }
                }, receiveValue: { value in
                    XCTAssertEqual(value, "Success!")
                    valueReceived = true
                }
            )
            .store(in: &cancellables)

        testScheduler.advance(by: 3)

        XCTAssertTrue(valueReceived)
        XCTAssertTrue(finishedReceived)
    }

    func test_retryWhen_3_failing_retries_then_success() {
        let testScheduler = DispatchQueue.test

        var emitCount = 0

        let source = Publishers.Create<String, TestError> { factory in
            let emit = {
                defer { emitCount += 1 }

                if emitCount == 2 {
                    factory.send("Success!")
                    factory.send(completion: .finished)
                } else {
                    factory.send(completion: .failure(.errorNum1))
                }
            }

            emit()

            return AnyCancellable {}
        }
        .delay(for: 1, scheduler: testScheduler)

        var valueReceived = false
        var finishedReceived = false

        source
            .retryWhen { errorSignal -> AnyPublisher<Void, TestError> in
                errorSignal
                    .flatMap { _ -> AnyPublisher<Void, TestError> in
                        Just(()).setFailureType(to: TestError.self)
                            .delay(for: 1, scheduler: testScheduler)
                            .eraseToAnyPublisher()

                    }
                    .eraseToAnyPublisher()
            }
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case let .failure(error):
                        XCTFail("Unexpected event received - error: \(error).")
                    case .finished:
                        finishedReceived = true
                    }
                }, receiveValue: { value in
                    XCTAssertEqual(value, "Success!")
                    valueReceived = true
                }
            )
            .store(in: &cancellables)

        testScheduler.advance(by: 5)

        XCTAssertTrue(valueReceived)
        XCTAssertTrue(finishedReceived)
    }

    func test_retryWhen_3_failing_retries_then_failure() {
        let testScheduler = DispatchQueue.test

        let source: AnyPublisher<String, TestError> = Fail(error: .errorNum1)
            .delay(for: 1, scheduler: testScheduler)
            .eraseToAnyPublisher()

        var errorReceived = false

        source
            .retryWhen { errorSignal -> AnyPublisher<Void, TestError> in
                errorSignal
                    .scan([]) { $0 + [$1] }
                    .flatMap { errors -> AnyPublisher<Void, TestError> in
                        if errors.count == 3 {
                            return Fail(error: TestError.errorNum2)
                                .delay(for: 1, scheduler: testScheduler)
                                .eraseToAnyPublisher()
                        }

                        return Just(()).setFailureType(to: TestError.self)
                            .delay(for: 1, scheduler: testScheduler)
                            .eraseToAnyPublisher()

                    }
                    .eraseToAnyPublisher()
            }
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case let .failure(error):
                        XCTAssertEqual(error, .errorNum2)
                        errorReceived = true
                    case .finished:
                        XCTFail("Unexpected event received - finished.")
                    }
                }, receiveValue: { value in
                    XCTFail("Unexpected event received - value: \(value).")
                }
            )
            .store(in: &cancellables)

        testScheduler.advance(by: 6)

        XCTAssertTrue(errorReceived)
    }
}
