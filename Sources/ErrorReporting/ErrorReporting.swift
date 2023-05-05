public protocol ErrorReporting: Error, CustomDebugStringConvertible, CustomStringConvertible {
    var causeUIdescription: String { get }
}
