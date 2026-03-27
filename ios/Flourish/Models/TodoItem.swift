import Foundation
import SwiftData

@Model
final class TodoItem {
    var title: String
    var isCompleted: Bool
    var createdDate: Date
    var scheduledTime: Date?

    init(title: String, isCompleted: Bool = false, createdDate: Date = .now, scheduledTime: Date? = nil) {
        self.title = title
        self.isCompleted = isCompleted
        self.createdDate = createdDate
        self.scheduledTime = scheduledTime
    }
}
