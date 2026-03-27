import SwiftData
import Foundation

@Model
final class Goal {
    var title: String
    var detail: String
    var targetDate: Date?
    var isCompleted: Bool
    var category: String

    init(title: String, detail: String = "", targetDate: Date? = nil, isCompleted: Bool = false, category: String = "personal") {
        self.title = title
        self.detail = detail
        self.targetDate = targetDate
        self.isCompleted = isCompleted
        self.category = category
    }
}
