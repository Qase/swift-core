import Foundation
import CoreData


extension TestModel {
  @NSManaged public var id: UUID
  @NSManaged public var name: String
}

extension TestModel: Identifiable {
}
