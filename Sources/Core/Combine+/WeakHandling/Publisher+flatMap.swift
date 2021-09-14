//
//  Publisher+flatMap.swift
//  Core
//
//  Created by Martin Troup on 05.06.2021.
//

import Combine

public extension Publisher {
    func flatMap<A: AnyObject, P: Publisher>(
        weak obj: A,
        logger: @escaping (String) -> Void = { Swift.print($0) },
        in file: String = #file,
        on line: Int = #line,
        onNil: P,
        _ transform: @escaping (A, Self.Output) -> P
    ) -> Publishers.FlatMap<P, Self> where Self.Failure == P.Failure {
        flatMap { [weak obj] element -> P in
            guard let obj = obj else {
                logger("Self is nil in file: \(file), on line: \(line)!")
                return onNil
            }

            return transform(obj, element)
        }
    }

    func flatMap<A: AnyObject, Output>(
        weak obj: A,
        logger: @escaping (String) -> Void = { Swift.print($0) },
        in file: String = #file,
        on line: Int = #line,
        onNil error: Self.Failure,
        _ transform: @escaping (A, Self.Output) -> AnyPublisher<Output, Self.Failure>
    ) -> AnyPublisher<Output, Failure> {
        flatMap(
            weak: obj,
            logger: logger,
            in: file,
            on: line,
            onNil: Fail<Output, Self.Failure>(error: error).eraseToAnyPublisher(),
            transform
        )
            .eraseToAnyPublisher()
    }
}
