//
//  KeyValueStorageError.swift
//  
//
//  Created by Martin Troup on 01.09.2021.
//

import Foundation

public struct KeyValueStorageError: ErrorReportable {

    // MARK: - Cause

    public enum ErrorCause: Error, CustomDebugStringConvertible {
        public var debugDescription: String {
            let caseString: (String) -> String = { "ErrorCause.\($0)" }

            switch self {
            case let .storeError(error):
                return caseString("storeError(\(error.localizedDescription).")
            case .noData:
                return caseString("noData")
            case let .loadError(error):
                return caseString("loadError(\(error.localizedDescription).")
            case let .deleteError(error):
                return caseString("deleteError(\(error.localizedDescription)).")
            }
        }

        case storeError(Error)
        case noData
        case loadError(Error)
        case deleteError(Error)
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

// MARK: - KeyValueStorageError instances

public extension KeyValueStorageError {
    static var storeError: (Error) -> Self = { error in
        .init(cause: .storeError(error))
    }

    static var noData: Self {
        .init(cause: .noData)
    }

    static var loadError: (Error) -> Self = { error in
        .init(cause: .loadError(error))
    }

    static var deleteError: (Error) -> Self = { error in
        .init(cause: .deleteError(error))
    }
}
