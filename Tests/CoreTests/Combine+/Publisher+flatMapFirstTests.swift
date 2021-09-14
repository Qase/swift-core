//
//  Publisher_flatMapFirstTests.swift
//  
//
//  Created by Martin Troup on 22.08.2021.
//

import Combine
import CombineSchedulers
import XCTest

class Publisher_flatMapFirstTests: XCTestCase {
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()

        cancellables = []
    }

    struct TestError: Error {}

    func test_flatMapFirst_single_upstream_single_flatMap() {
        let testScheduler = DispatchQueue.test

        var innerPublisherSubscriptionCount = 0
        var innerPublisherCompletionCount = 0

        Just("").setFailureType(to: Never.self)
            .delay(for: 1, scheduler: testScheduler)
            .flatMapFirst { _ -> AnyPublisher<Date, Never> in
                return Just(Date())
                    .delay(for: 1, scheduler: testScheduler)
                    .handleEvents(
                        receiveSubscription: { _ in innerPublisherSubscriptionCount += 1 },
                        receiveCompletion: { _ in innerPublisherCompletionCount += 1 }
                    )
                    .eraseToAnyPublisher()
            }
            .sink(receiveValue: { _ in })
            .store(in: &cancellables)

        testScheduler.advance(by: 2)

        XCTAssertEqual(innerPublisherSubscriptionCount, 1)
        XCTAssertEqual(innerPublisherCompletionCount, 1)
    }

    func test_flatMapFirst_error_upstream_skipping_flatMap() {
        let testScheduler = DispatchQueue.test

        var innerPublisherSubscriptionCount = 0

        Fail(error: TestError()).eraseToAnyPublisher()
            .delay(for: 1, scheduler: testScheduler)
            .flatMapFirst { (_: String) -> AnyPublisher<Date, TestError> in
                return Just(Date()).setFailureType(to: TestError.self)
                    .handleEvents(receiveSubscription: { _ in innerPublisherSubscriptionCount += 1 })
                    .eraseToAnyPublisher()
            }
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)

        testScheduler.advance(by: 1)

        XCTAssertEqual(innerPublisherSubscriptionCount, 0)
    }

    func test_flatmap_first() {
        let testScheduler = DispatchQueue.test

        var innerPublisherSubscriptionCount = 0
        var innerPublisherCompletionCount = 0

        testScheduler.timerPublisher(every: 1)
            .autoconnect()
            .prefix(100)
            .flatMapFirst { _ -> AnyPublisher<Date, Never> in
                return Just(Date())
                    .handleEvents(
                        receiveSubscription: { _ in innerPublisherSubscriptionCount += 1 },
                        receiveCompletion: { _ in innerPublisherCompletionCount += 1 }
                    )
                    .delay(for: 10, scheduler: testScheduler)
                    .eraseToAnyPublisher()
            }
            .sink(receiveValue: { _ in })
            .store(in: &cancellables)


        testScheduler.advance(by: 100)

        XCTAssertEqual(innerPublisherSubscriptionCount, 10)
        XCTAssertEqual(innerPublisherCompletionCount, 10)
    }
}
