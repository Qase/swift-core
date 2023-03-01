public struct OptionalValueIsNil: Error {}

public extension Optional {
    func orThrow() throws -> Wrapped {
        guard let value = self else {
            throw OptionalValueIsNil()
        }
        return value
    }
}
