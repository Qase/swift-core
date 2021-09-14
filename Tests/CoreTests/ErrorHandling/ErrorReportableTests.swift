//
//  ErrorReportableTests.swift
//  
//
//  Created by Martin Troup on 09.04.2021.
//

import Core
import Combine
import XCTest

final class ErrorReportableTests: XCTestCase {
    struct TestError1: ErrorReportable, Equatable {
        let catalogueID = ErrorCatalogueID.unassigned
        var stackID: UUID?
        var underlyingError: ErrorReportable?

        var causeDescription: CustomDebugStringConvertible? { "" }

        init(stackID: UUID? = nil) {
            self.stackID = stackID
        }

        static func == (lhs: ErrorReportableTests.TestError1, rhs: ErrorReportableTests.TestError1) -> Bool {
            lhs.catalogueID == rhs.catalogueID && lhs.stackID == rhs.stackID
        }

    }

    struct TestError2: ErrorReportable {
        let catalogueID = ErrorCatalogueID.unassigned
        var stackID: UUID?
        var underlyingError: ErrorReportable?

        var causeDescription: CustomDebugStringConvertible? { "" }

        init() {}
    }

    var subscriptions = Set<AnyCancellable>()

    override func tearDown() {
        subscriptions = []

        super.tearDown()
    }

    func test_setChaingedProperties_method() {
        let error1 = TestError1(stackID: UUID(uuidString: "ffeac012-9911-11eb-a8b3-0242ac130003"))
        var error2 = TestError2()

        error2.setChainedProperties(from: error1)

        XCTAssertEqual(error1.stackID, error2.stackID)
        XCTAssertNotNil(error2.underlyingError as? TestError1)

        XCTAssertEqual(error2.underlyingError as! TestError1, error1)
    }

    func test_mapErrorReportable_simple_Publisher_extension() {
        let expectation = self.expectation(description: "")

        let error1 = TestError1(stackID: UUID(uuidString: "ffeac012-9911-11eb-a8b3-0242ac130003"))

        Fail<Void, TestError1>(error: error1)
            .mapErrorReportable(to: TestError2())
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case let .failure(error2):
                        XCTAssertEqual(error1.stackID, error2.stackID)
                        XCTAssertNotNil(error2.underlyingError as? TestError1)
                        XCTAssertEqual(error2.underlyingError as! TestError1, error1)
                        expectation.fulfill()
                    case .finished:
                        XCTFail("Unexpected event received.")
                    }
                },
                receiveValue: { _ in
                    XCTFail("Unexpected event received.")
                }
            )
            .store(in: &subscriptions)

        waitForExpectations(timeout: 0.1)
    }
}
