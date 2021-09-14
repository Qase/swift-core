//
//  Publisher+flatMapResult.swift
//  Core
//
//  Created by Martin Troup on 20.08.2021.
//

import Combine

public extension Publisher {
    func flatMapResult<T>(
        _ transform: @escaping (Self.Output) -> Result<T, Self.Failure>
    ) -> Publishers.FlatMap<Result<T, Self.Failure>.Publisher, Self> {
        flatMap { .init(transform($0)) }
    }
}
