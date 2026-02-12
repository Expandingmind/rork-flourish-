import Foundation
import SwiftData
import SwiftUI

struct BackupData: Codable {
    var version: Int = 1
    var exportDate: Date = .now
    var dailyActions: [DailyActionBackup]
    var evidenceItems: [EvidenceItemBackup]
    var travelDestinations: [TravelDestinationBackup]
    var goals: [GoalBackup]
    var bucketListItems: [BucketListItemBackup]
    var todoItems: [TodoItemBackup]
    var gardenPlants: [GardenPlantBackup]
    var microActions: [MicroActionBackup]?
    var gardenResources: [GardenResourceBackup]?
    var userName: String?
    var userFocusArea: String?
    var userUsername: String?
    var profileImageBase64: String?
    var appLockEnabled: Bool?
    var notificationsEnabled: Bool?
    var dailyReminders: Bool?
    var hapticFeedback: Bool?
}

struct DailyActionBackup: Codable {
    let title: String
    let isCompleted: Bool
    let createdDate: Date
    let category: String
}

struct EvidenceItemBackup: Codable {
    let title: String
    let detail: String
    let category: String
    let amount: Double
    let date: Date
}

struct TravelDestinationBackup: Codable {
    let name: String
    let country: String
    let estimatedBudget: Double
    let savedAmount: Double
    let targetDate: Date?
    let notes: String
    let isVisited: Bool
}

struct GoalBackup: Codable {
    let title: String
    let detail: String
    let targetDate: Date?
    let isCompleted: Bool
    let category: String
}

struct BucketListItemBackup: Codable {
    let title: String
    let detail: String
    let isCompleted: Bool
    let colorIndex: Int
    let createdDate: Date
    let completedDate: Date?
    let targetDate: Date?
}

struct TodoItemBackup: Codable {
    let title: String
    let isCompleted: Bool
    let createdDate: Date
    let scheduledTime: Date?
}

struct GardenPlantBackup: Codable {
    let plantType: String
    let growthStage: Int
    let gridIndex: Int
    let sourceDescription: String
    let createdDate: Date
    let lastWateredDate: Date
}

struct MicroActionBackup: Codable {
    let actionKey: String
    let isCompleted: Bool
    let dateSelected: Date
}

struct GardenResourceBackup: Codable {
    let seeds: Int
    let waterCans: Int
    let totalSeedsEarned: Int
    let totalWaterEarned: Int
}

enum BackupService {
    static func exportData(context: ModelContext) throws -> Data {
        let actions = try context.fetch(FetchDescriptor<DailyAction>())
        let evidence = try context.fetch(FetchDescriptor<EvidenceItem>())
        let destinations = try context.fetch(FetchDescriptor<TravelDestination>())
        let goals = try context.fetch(FetchDescriptor<Goal>())
        let bucketItems = try context.fetch(FetchDescriptor<BucketListItem>())
        let todoItems = try context.fetch(FetchDescriptor<TodoItem>())
        let plants = try context.fetch(FetchDescriptor<GardenPlant>())
        let microActions = try context.fetch(FetchDescriptor<MicroAction>())
        let gardenResources = try context.fetch(FetchDescriptor<GardenResource>())

        let backup = BackupData(
            dailyActions: actions.map { DailyActionBackup(title: $0.title, isCompleted: $0.isCompleted, createdDate: $0.createdDate, category: $0.category) },
            evidenceItems: evidence.map { EvidenceItemBackup(title: $0.title, detail: $0.detail, category: $0.category, amount: $0.amount, date: $0.date) },
            travelDestinations: destinations.map { TravelDestinationBackup(name: $0.name, country: $0.country, estimatedBudget: $0.estimatedBudget, savedAmount: $0.savedAmount, targetDate: $0.targetDate, notes: $0.notes, isVisited: $0.isVisited) },
            goals: goals.map { GoalBackup(title: $0.title, detail: $0.detail, targetDate: $0.targetDate, isCompleted: $0.isCompleted, category: $0.category) },
            bucketListItems: bucketItems.map { BucketListItemBackup(title: $0.title, detail: $0.detail, isCompleted: $0.isCompleted, colorIndex: $0.colorIndex, createdDate: $0.createdDate, completedDate: $0.completedDate, targetDate: $0.targetDate) },
            todoItems: todoItems.map { TodoItemBackup(title: $0.title, isCompleted: $0.isCompleted, createdDate: $0.createdDate, scheduledTime: $0.scheduledTime) },
            gardenPlants: plants.map { GardenPlantBackup(plantType: $0.plantType, growthStage: $0.growthStage, gridIndex: $0.gridIndex, sourceDescription: $0.sourceDescription, createdDate: $0.createdDate, lastWateredDate: $0.lastWateredDate) },
            microActions: microActions.map { MicroActionBackup(actionKey: $0.actionKey, isCompleted: $0.isCompleted, dateSelected: $0.dateSelected) },
            gardenResources: gardenResources.map { GardenResourceBackup(seeds: $0.seeds, waterCans: $0.waterCans, totalSeedsEarned: $0.totalSeedsEarned, totalWaterEarned: $0.totalWaterEarned) },
            userName: UserDefaults.standard.string(forKey: "userName"),
            userFocusArea: UserDefaults.standard.string(forKey: "userFocusArea"),
            userUsername: UserDefaults.standard.string(forKey: "userUsername"),
            profileImageBase64: UserDefaults.standard.data(forKey: "profileImageData")?.base64EncodedString(),
            appLockEnabled: UserDefaults.standard.bool(forKey: "appLockEnabled"),
            notificationsEnabled: UserDefaults.standard.bool(forKey: "notificationsEnabled"),
            dailyReminders: UserDefaults.standard.bool(forKey: "dailyReminders"),
            hapticFeedback: UserDefaults.standard.object(forKey: "hapticFeedback") == nil ? true : UserDefaults.standard.bool(forKey: "hapticFeedback")
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(backup)
    }

    static func importData(_ data: Data, context: ModelContext) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(BackupData.self, from: data)

        for item in backup.dailyActions {
            context.insert(DailyAction(title: item.title, isCompleted: item.isCompleted, createdDate: item.createdDate, category: item.category))
        }
        for item in backup.evidenceItems {
            context.insert(EvidenceItem(title: item.title, detail: item.detail, category: item.category, amount: item.amount, date: item.date))
        }
        for item in backup.travelDestinations {
            context.insert(TravelDestination(name: item.name, country: item.country, estimatedBudget: item.estimatedBudget, savedAmount: item.savedAmount, targetDate: item.targetDate, notes: item.notes, isVisited: item.isVisited))
        }
        for item in backup.goals {
            context.insert(Goal(title: item.title, detail: item.detail, targetDate: item.targetDate, isCompleted: item.isCompleted, category: item.category))
        }
        for item in backup.bucketListItems {
            let bucketItem = BucketListItem(title: item.title, detail: item.detail, isCompleted: item.isCompleted, colorIndex: item.colorIndex, targetDate: item.targetDate)
            bucketItem.completedDate = item.completedDate
            context.insert(bucketItem)
        }
        for item in backup.todoItems {
            context.insert(TodoItem(title: item.title, isCompleted: item.isCompleted, createdDate: item.createdDate, scheduledTime: item.scheduledTime))
        }
        for item in backup.gardenPlants {
            let plant = GardenPlant(plantType: item.plantType, growthStage: item.growthStage, gridIndex: item.gridIndex, sourceDescription: item.sourceDescription, createdDate: item.createdDate)
            plant.lastWateredDate = item.lastWateredDate
            context.insert(plant)
        }

        if let microActions = backup.microActions {
            for item in microActions {
                context.insert(MicroAction(actionKey: item.actionKey, isCompleted: item.isCompleted, dateSelected: item.dateSelected))
            }
        }

        if let gardenResources = backup.gardenResources {
            for item in gardenResources {
                let resource = GardenResource(seeds: item.seeds, waterCans: item.waterCans, totalSeedsEarned: item.totalSeedsEarned, totalWaterEarned: item.totalWaterEarned)
                context.insert(resource)
            }
        }

        if let name = backup.userName {
            UserDefaults.standard.set(name, forKey: "userName")
        }
        if let focus = backup.userFocusArea {
            UserDefaults.standard.set(focus, forKey: "userFocusArea")
        }
        if let username = backup.userUsername {
            UserDefaults.standard.set(username, forKey: "userUsername")
        }
        if let imageBase64 = backup.profileImageBase64, let imageData = Data(base64Encoded: imageBase64) {
            UserDefaults.standard.set(imageData, forKey: "profileImageData")
        }
        if let appLock = backup.appLockEnabled {
            UserDefaults.standard.set(appLock, forKey: "appLockEnabled")
        }
        if let notif = backup.notificationsEnabled {
            UserDefaults.standard.set(notif, forKey: "notificationsEnabled")
        }
        if let daily = backup.dailyReminders {
            UserDefaults.standard.set(daily, forKey: "dailyReminders")
        }
        if let haptic = backup.hapticFeedback {
            UserDefaults.standard.set(haptic, forKey: "hapticFeedback")
        }

        try context.save()
    }

    static func exportToFile(context: ModelContext) throws -> URL {
        let data = try exportData(context: context)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let fileName = "Flourish_Backup_\(formatter.string(from: .now)).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: tempURL)
        return tempURL
    }
}
