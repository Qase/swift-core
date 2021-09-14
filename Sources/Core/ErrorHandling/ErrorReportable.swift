//
//  ErrorReportable.swift
//  Core
//
//  Created by Martin Troup on 05.04.2021.
//

import Combine
import Foundation

public typealias ErrorCatalogueID = String

public extension ErrorCatalogueID {
    static var unassigned: String { "unassigned-catalogue-id" }
}

public protocol ErrorReportable: Error, CustomDebugStringConvertible {
    var catalogueID: ErrorCatalogueID { get }
    var stackID: UUID? { get set }
    var causeDescription: CustomDebugStringConvertible? { get }
    var underlyingError: ErrorReportable? { get set }
}

public extension ErrorReportable {
    mutating func setChainedProperties(from underlyingError: ErrorReportable) {
        self.stackID = underlyingError.stackID
        self.underlyingError = underlyingError
    }
}

extension ErrorReportable {
    public var debugDescription: String {
        let causeString = causeDescription.map { " - cause: \($0.debugDescription)" } ?? ""

        return "\(type(of: self)) - stackID: \(String(describing: stackID)) - catalogueID: \(catalogueID)\(causeString)"
    }
}

// MARK: - Publisher+mapErrorReportable

public extension Publisher {
    func mapErrorReportable<E1: ErrorReportable, E2: ErrorReportable>(
        _ transform: @escaping (E1) -> E2
    ) -> Publishers.MapError<Self, E2>
    where Self.Failure == E1
    {
        mapError { errorToMap in
            var resultingError = transform(errorToMap)
            resultingError.setChainedProperties(from: errorToMap)

            return resultingError
        }
    }

    func mapErrorReportable<E1: ErrorReportable, E2: ErrorReportable>(
        to newError: E2
    ) -> Publishers.MapError<Self, E2>
    where Self.Failure == E1
    {
        mapError { errorToMap in
            var resultingError = newError
            resultingError.setChainedProperties(from: errorToMap)

            return resultingError
        }
    }
}
