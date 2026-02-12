import SwiftData
import Foundation

@Model
final class BucketListItem {
    var title: String
    var detail: String
    var isCompleted: Bool
    var colorIndex: Int
    var createdDate: Date
    var completedDate: Date?
    var targetDate: Date?

    init(title: String, detail: String = "", isCompleted: Bool = false, colorIndex: Int = 0, targetDate: Date? = nil) {
        self.title = title
        self.detail = detail
        self.isCompleted = isCompleted
        self.colorIndex = colorIndex
        self.createdDate = .now
        self.targetDate = targetDate
    }
}
