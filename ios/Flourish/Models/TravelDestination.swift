import SwiftData
import Foundation

@Model
final class TravelDestination {
    var name: String
    var country: String
    var estimatedBudget: Double
    var savedAmount: Double
    var targetDate: Date?
    var notes: String
    var isVisited: Bool
    var colorIndex: Int

    init(name: String, country: String = "", estimatedBudget: Double = 0, savedAmount: Double = 0, targetDate: Date? = nil, notes: String = "", isVisited: Bool = false, colorIndex: Int = 0) {
        self.name = name
        self.country = country
        self.estimatedBudget = estimatedBudget
        self.savedAmount = savedAmount
        self.targetDate = targetDate
        self.notes = notes
        self.isVisited = isVisited
        self.colorIndex = colorIndex
    }

    var progress: Double {
        guard estimatedBudget > 0 else { return 0 }
        return min(savedAmount / estimatedBudget, 1.0)
    }
}
