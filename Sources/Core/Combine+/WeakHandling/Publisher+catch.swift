//
//  Publisher+catch.swift
//  Core
//
//  Created by Martin Troup on 05.06.2021.
//

import Foundation
import Combine

public extension Publisher {
    func `catch`<A: AnyObject, P: Publisher>(
        weak obj: A,
        logger: @escaping (String) -> Void = { Swift.print($0) },
        in file: String = #file,
        on line: Int = #line,
        onNil: P,
        _ handler: @escaping (A, Self.Failure) -> P
    ) -> Publishers.Catch<Self, P> where Self.Output == P.Output {
        `catch` { [weak obj] error -> P in
            guard let obj = obj else {
                logger("Self is nil in file: \(file), on line: \(line)!")
                return onNil
            }

            return handler(obj, error)
        }
    }

    func `catch`<A: AnyObject, Failure: Error>(
        weak obj: A,
        logger: @escaping (String) -> Void = { Swift.print($0) },
        in file: String = #file,
        on line: Int = #line,
        onNil: Failure,
        _ handler: @escaping (A, Self.Failure) -> AnyPublisher<Self.Output, Failure>
    ) -> AnyPublisher<Self.Output, Failure> {
        `catch`(
            weak: obj,
            logger: logger,
            in: file,
            on: line,
            onNil: Fail<Self.Output, Failure>(error: onNil).eraseToAnyPublisher(),
            handler
        )
            .eraseToAnyPublisher()
    }
}

