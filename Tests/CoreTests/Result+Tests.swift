//
//  Result+Tests.swift
//  
//
//  Created by Martin Troup on 09.04.2021.
//

import XCTest

class Result_Tests: XCTestCase {

    struct EmptyError: Error, Equatable {}

    func test_execute_non_throwing() {
        let numberIdentity: (Int) -> Int = { $0 }

        let sut = Result<Int, EmptyError>.execute( { numberIdentity(5) }, onThrows: { _ in EmptyError() })

        XCTAssertEqual(sut, .success(5))
    }

    func test_execute_throwing() {
        let throwing: () throws -> Int = { throw EmptyError() }

        let sut = Result<Int, EmptyError>.execute( { try throwing() }, onThrows: { _ in EmptyError() })

        XCTAssertEqual(sut, .failure(EmptyError()))
    }

    func test_from_optional_not_nil() {
        let sut = Result<Int, EmptyError>.from(optional: Optional<Int>.some(5), onNil: EmptyError())

        XCTAssertEqual(sut, .success(5))
    }

    func test_from_optional_nil() {
        let sut = Result<Int, EmptyError>.from(optional: Optional<Int>.none, onNil: EmptyError())

        XCTAssertEqual(sut, .failure(EmptyError()))
    }
}
