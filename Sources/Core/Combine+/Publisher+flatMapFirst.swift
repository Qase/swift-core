//
//  Publisher+flatMapFirst.swift
//  Core
//
//  Created by Martin Troup on 20.08.2021.
//

import Combine
import Foundation

public extension Publisher {
    func flatMapFirst<P: Publisher>(
        _ transform: @escaping (Output) -> P
    ) -> Publishers.FlatMap<Publishers.HandleEvents<P>, Publishers.Filter<Self>>
    where Self.Failure == P.Failure {
        var isRunning = false
        let lock = NSRecursiveLock()

        func set(isRunning newValue: Bool) {
            defer { lock.unlock() }
            lock.lock()

            isRunning = newValue
        }

        return self
            .filter { _ in !isRunning }
            .flatMap { output in
                transform(output)
                    .handleEvents(
                        receiveSubscription: { _ in
                            set(isRunning: true)
                        },
                        receiveCompletion: { _ in
                            set(isRunning: false)
                        },
                        receiveCancel: {
                            set(isRunning: false)
                        }
                    )
            }
    }
}
