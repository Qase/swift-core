//
//  Publisher+retryWhen.swift
//  Core
//
//  Created by Martin Troup on 22.08.2021.
//

import Foundation

import Foundation
import Combine
import CasePaths

extension Publisher {
    public func retryWhen<P>(
        _ handler: @escaping (AnyPublisher<Self.Failure, Never>) -> P
    ) -> AnyPublisher<Self.Output, Self.Failure>
    where P: Publisher, P.Failure == Self.Failure, P.Output == Void {
        let errorSubject = CurrentValueSubject<Optional<Self.Failure>, Never>(nil)

        let errorHandler: (Self.Failure) -> AnyPublisher<Self.Output, Self.Failure> = { error in
            errorSubject.send(error)

            return handler(errorSubject.compactMap { $0 }.eraseToAnyPublisher())
                .flatMap {
                    self
                        .handleEvents(
                            receiveCompletion: { completion in
                                if case .finished = completion {
                                    errorSubject.send(completion: .finished)
                                }
                            }, receiveCancel: {
                                errorSubject.send(completion: .finished)
                            }
                        )
                        .catch { upstreamError -> Empty<Self.Output, Self.Failure> in
                            errorSubject.send(error)
                            return Empty(completeImmediately: true)
                        }
                }
                .eraseToAnyPublisher()
        }


        return self
            .catch(errorHandler)
            .eraseToAnyPublisher()
    }
}
