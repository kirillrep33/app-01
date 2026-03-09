import Foundation

@MainActor
final class AppContext {
    static let shared = AppContext()

    let notificationManager: NotificationManager
    let store: FishStockStore

    private init() {
        let persistence = PersistenceManager()
        let notificationManager = NotificationManager()
        self.notificationManager = notificationManager
        self.store = FishStockStore(persistence: persistence, notificationManager: notificationManager)
    }
}
