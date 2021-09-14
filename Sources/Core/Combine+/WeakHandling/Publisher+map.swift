//
//  Publisher+map.swift
//  
//
//  Created by Martin Troup on 10.09.2021.
//

import Combine

public extension Publisher where Self.Output == Bool, Self.Failure == Never {
    func map<Output, Failure: Error>(onTrue value: Output, onFalse error: Failure) -> AnyPublisher<Output, Failure> {
        self.flatMap { isTrue in
            isTrue
                ? Just(value).setFailureType(to: Failure.self).eraseToAnyPublisher()
                : Fail(error: error).eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
}
