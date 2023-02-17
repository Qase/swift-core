enum OptionalError: Error {
    case nilValueFound
}

public extension Optional {
    func orThrow() throws -> Wrapped {
        guard let value = self else {
            throw OptionalError.nilValueFound
        }
        return value
    }
}
