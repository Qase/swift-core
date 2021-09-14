//
//  Publishers+sink.swift
//  Core
//
//  Created by Martin Troup on 27.08.2021.
//

import Combine

public extension Publisher where Self.Failure: Error {
    func sink<A: AnyObject>(
        weak obj: A,
        logger: @escaping (String) -> Void = { Swift.print($0) },
        in file: String = #file,
        on line: Int = #line,
        shouldAssertOnNil: Bool = true,
        receiveCompletion: @escaping (A, Subscribers.Completion<Self.Failure>) -> Void,
        receiveValue: @escaping (A, Self.Output) -> Void
    ) -> AnyCancellable {
        sink(
            receiveCompletion: { [weak obj] completion in
                guard let obj = obj else {
                    let logMessage = "Self is nil in file: \(file), on line: \(line)!"
                    logger(logMessage)
                    if shouldAssertOnNil { Swift.assertionFailure(logMessage) }

                    return
                }

                receiveCompletion(obj, completion)
            },
            receiveValue: { [ weak obj] value in
                guard let obj = obj else {
                    let logMessage = "Self is nil in file: \(file), on line: \(line)!"
                    logger(logMessage)
                    if shouldAssertOnNil { Swift.assertionFailure(logMessage) }

                    return
                }

                receiveValue(obj, value)
            }
        )
    }
}

public extension Publisher where Self.Failure == Never {
    func sink<A: AnyObject>(
        weak obj: A,
        logger: @escaping (String) -> Void = { Swift.print($0) },
        in file: String = #file,
        on line: Int = #line,
        shouldAssertOnNil: Bool = true,
        receiveCompletion: ((A, Subscribers.Completion<Self.Failure>) -> Void)? = nil,
        receiveValue: @escaping (A, Self.Output) -> Void
    ) -> AnyCancellable {
        sink(
            receiveCompletion: { [weak obj] completion in
                guard let obj = obj else {
                    let logMessage = "Self is nil in file: \(file), on line: \(line)!"
                    logger(logMessage)
                    if shouldAssertOnNil { Swift.assertionFailure(logMessage) }

                    return
                }

                receiveCompletion?(obj, completion)
            },
            receiveValue: { [ weak obj] value in
                guard let obj = obj else {
                    let logMessage = "Self is nil in file: \(file), on line: \(line)!"
                    logger(logMessage)
                    if shouldAssertOnNil { Swift.assertionFailure(logMessage) }
                    
                    return
                }

                receiveValue(obj, value)
            }
        )
    }
}
