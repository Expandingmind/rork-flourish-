import SwiftData
import SwiftUI

@Model
final class EvidenceItem {
    var title: String
    var detail: String
    var category: String
    var amount: Double
    var date: Date

    init(title: String, detail: String = "", category: String = "win", amount: Double = 0, date: Date = .now) {
        self.title = title
        self.detail = detail
        self.category = category
        self.amount = amount
        self.date = date
    }
}

enum EvidenceCategory: String, CaseIterable {
    case win = "win"
    case saving = "saving"
    case milestone = "milestone"

    var displayName: String {
        switch self {
        case .win: return "Power Move"
        case .saving: return "Freedom Earned"
        case .milestone: return "Landmark"
        }
    }

    var icon: String {
        switch self {
        case .win: return "bolt.fill"
        case .saving: return "banknote.fill"
        case .milestone: return "flag.fill"
        }
    }

    var color: Color {
        switch self {
        case .win: return Theme.accent
        case .saving: return Theme.gold
        case .milestone: return Theme.sage
        }
    }

    var celebrationLine: String {
        switch self {
        case .win: return "You did that."
        case .saving: return "Freedom reclaimed."
        case .milestone: return "Landmark moment."
        }
    }
}
