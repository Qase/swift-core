//
//  GeneralError.swift
//  Core
//
//  Created by Martin Troup on 30.05.2021.
//

import Foundation

public struct GeneralError: ErrorReportable {

    // MARK: - Cause

    public enum ErrorCause: Error, CustomDebugStringConvertible {
        public var debugDescription: String {
            let caseString: (String) -> String = { "ErrorCause.\($0)" }

            switch self {
            case let .nilSelf(file, line):
                return caseString("nilSelf(file: \(file), line: \(line)).")
            }
        }

        case nilSelf(file: String, line: UInt)
    }

    public var causeDescription: CustomDebugStringConvertible? { cause.debugDescription }

    // MARK: - Properties

    public let catalogueID = ErrorCatalogueID.unassigned
    public let cause: ErrorCause
    public var stackID: UUID?
    public var underlyingError: ErrorReportable?

    // MARK: - Initializers

    public init(cause: ErrorCause, stackID: UUID? = nil) {
        self.cause = cause
        self.stackID = stackID ?? UUID()
    }
}

// MARK: - GeneralError instances

public extension GeneralError {
    static var nilSelf: Self {
        .init(cause: .nilSelf(file: #file, line: #line))
    }
}
