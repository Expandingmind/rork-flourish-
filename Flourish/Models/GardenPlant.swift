import SwiftData
import SwiftUI

@Model
final class GardenPlant {
    var plantType: String
    var growthStage: Int
    var gridIndex: Int
    var sourceDescription: String
    var createdDate: Date
    var lastWateredDate: Date

    init(plantType: String, growthStage: Int = 0, gridIndex: Int, sourceDescription: String, createdDate: Date = .now) {
        self.plantType = plantType
        self.growthStage = growthStage
        self.gridIndex = gridIndex
        self.sourceDescription = sourceDescription
        self.createdDate = createdDate
        self.lastWateredDate = createdDate
    }

    var type: PlantType {
        PlantType(rawValue: plantType) ?? .daisy
    }

    var stage: GrowthStage {
        GrowthStage(rawValue: growthStage) ?? .seed
    }

    var isWilted: Bool {
        let daysSinceWatered = Calendar.current.dateComponents([.day], from: lastWateredDate, to: .now).day ?? 0
        return daysSinceWatered > 3
    }
}

enum PlantType: String, CaseIterable {
    case daisy
    case tulip
    case rose
    case sunflower
    case lavender
    case succulent

    var petalColor: Color {
        switch self {
        case .daisy: return Theme.softLemon
        case .tulip: return Theme.softPink
        case .rose: return Theme.dustyRose
        case .sunflower: return Theme.softPeach
        case .lavender: return Theme.softLavender
        case .succulent: return Theme.softMint
        }
    }

    var label: String {
        switch self {
        case .daisy: return "Daisy"
        case .tulip: return "Tulip"
        case .rose: return "Rose"
        case .sunflower: return "Sunflower"
        case .lavender: return "Lavender"
        case .succulent: return "Succulent"
        }
    }
}

enum GrowthStage: Int, CaseIterable {
    case seed = 0
    case sprout = 1
    case bloom = 2

    var label: String {
        switch self {
        case .seed: return "Seed"
        case .sprout: return "Sprout"
        case .bloom: return "Bloom"
        }
    }
}
