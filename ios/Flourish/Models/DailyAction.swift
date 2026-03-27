import SwiftData
import SwiftUI

@Model
final class DailyAction {
    var title: String
    var isCompleted: Bool
    var createdDate: Date
    var category: String

    init(title: String, isCompleted: Bool = false, createdDate: Date = .now, category: String = "general") {
        self.title = title
        self.isCompleted = isCompleted
        self.createdDate = createdDate
        self.category = category
    }
}

enum ActionCategory: String, CaseIterable {
    case financial = "financial"
    case travel = "travel"
    case career = "career"
    case wellness = "wellness"
    case personal = "personal"

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .financial: return "dollarsign.circle.fill"
        case .travel: return "airplane.circle.fill"
        case .career: return "briefcase.fill"
        case .wellness: return "heart.circle.fill"
        case .personal: return "star.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .financial: return Theme.gold
        case .travel: return Theme.sage
        case .career: return Theme.accent
        case .wellness: return Theme.sage
        case .personal: return Theme.gold
        }
    }
}
