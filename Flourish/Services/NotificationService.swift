import Foundation
import UserNotifications

struct NotificationService {
    static func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            return false
        }
    }

    static func scheduleDailyReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["dailyReminder"])

        let content = UNMutableNotificationContent()
        content.title = "Time to Flourish"
        content.body = [
            "Your future self is watching. Show up today.",
            "Small moves, big life. What will you do today?",
            "Evidence doesn't build itself. Let's go.",
            "Another day to prove yourself right.",
            "Momentum is waiting. Open up and get after it.",
            "Champions check in daily. You're one of them.",
        ].randomElement() ?? "Check in and build your momentum."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(identifier: "dailyReminder", content: content, trigger: trigger)
        center.add(request)
    }

    static func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyReminder"])
    }

    static func cancelAllNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
    }
}
