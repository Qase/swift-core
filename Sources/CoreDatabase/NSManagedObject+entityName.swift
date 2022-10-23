import CoreData

public extension NSManagedObject {
  static var entityName: String {
    String(describing: self)
  }
}
