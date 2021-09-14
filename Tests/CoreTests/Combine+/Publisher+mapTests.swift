//
//  Publisher+mapTests.swift
//  
//
//  Created by Martin Troup on 10.09.2021.
//

import Combine
import XCTest

final class Publisher_mapTests: XCTestCase {
    struct TestError: Error, Equatable {}

    var subscriptions = Set<AnyCancellable>()

    func test_map_true() {
        let testValue = "Success"

        var valueReceived = false
        var finishedReceived = false

        Just(true).setFailureType(to: Never.self)
            .map(onTrue: testValue, onFalse: TestError())
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case let .failure(error):
                        XCTFail("Unexpected event received - error: (\(error).")
                    case .finished:
                        finishedReceived = true
                    }
                },
                receiveValue: { value in
                    XCTAssertEqual(value, testValue)
                    valueReceived = true
                }
            )
            .store(in: &subscriptions)

        XCTAssertTrue(valueReceived)
        XCTAssertTrue(finishedReceived)
    }

    func test_map_false() {
        let testError = TestError()

        var errorReceived = false

        Just(false).setFailureType(to: Never.self)
            .map(onTrue: "Failure", onFalse: testError)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case let .failure(error):
                        XCTAssertEqual(error, error)
                        errorReceived = true
                    case .finished:
                        XCTFail("Unexpected event received - finised.")
                    }
                },
                receiveValue: { value in
                    XCTFail("Unexpected event received - value: (\(value).")
                }
            )
            .store(in: &subscriptions)

        XCTAssertTrue(errorReceived)
    }
}
