import SwiftData
import SwiftUI

@Model
final class GardenResource {
    var seeds: Int
    var waterCans: Int
    var totalSeedsEarned: Int
    var totalWaterEarned: Int

    init(seeds: Int = 0, waterCans: Int = 0, totalSeedsEarned: Int = 0, totalWaterEarned: Int = 0) {
        self.seeds = seeds
        self.waterCans = waterCans
        self.totalSeedsEarned = totalSeedsEarned
        self.totalWaterEarned = totalWaterEarned
    }

    func earnSeed(count: Int = 1) {
        seeds += count
        totalSeedsEarned += count
    }

    func earnWater(count: Int = 1) {
        waterCans += count
        totalWaterEarned += count
    }

    func spendSeed() -> Bool {
        guard seeds > 0 else { return false }
        seeds -= 1
        return true
    }

    func spendWater() -> Bool {
        guard waterCans > 0 else { return false }
        waterCans -= 1
        return true
    }
}
