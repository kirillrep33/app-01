import Foundation
import UserNotifications

final class NotificationManager {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorizationIfNeeded() {
        center.requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }

    func scheduleNotifications(for reminders: [ReminderRecord]) {
        center.removeAllPendingNotificationRequests()

        for reminder in reminders {
            let content = UNMutableNotificationContent()
            content.title = reminder.name
            content.body = reminder.details
            content.sound = .default

            let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            let request = UNNotificationRequest(identifier: reminder.id.uuidString, content: content, trigger: trigger)
            center.add(request)
        }
    }
}
