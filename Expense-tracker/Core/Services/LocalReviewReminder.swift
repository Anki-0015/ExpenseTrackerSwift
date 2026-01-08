import Foundation
import UserNotifications

struct LocalReviewReminder {
    func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func scheduleDailyReviewReminder(time: DateComponents) async {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "Review pending expenses"
        content.body = "Confirm or discard today's entries to keep your ledger clean."
        content.sound = .default

        var dateComponents = time
        dateComponents.calendar = .current

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily-review-reminder", content: content, trigger: trigger)

        try? await center.add(request)
    }

    func cancelDailyReviewReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-review-reminder"])
    }
}
