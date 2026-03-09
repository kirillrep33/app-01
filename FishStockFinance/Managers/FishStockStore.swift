import Foundation

@MainActor
final class FishStockStore: ObservableObject {
    @Published private(set) var fishes: [FishRecord] = []
    @Published private(set) var sales: [SaleRecord] = []
    @Published private(set) var reminders: [ReminderRecord] = []

    private let persistence: PersistenceManager
    private let notificationManager: NotificationManager

    init(persistence: PersistenceManager, notificationManager: NotificationManager) {
        self.persistence = persistence
        self.notificationManager = notificationManager

        if let state = persistence.load() {
            fishes = state.fishes
            sales = state.sales
            reminders = state.reminders
        } else {
            fishes = []
            sales = []
            reminders = []
        }

        notificationManager.requestAuthorizationIfNeeded()
        notificationManager.scheduleNotifications(for: reminders)
    }

    func addFish(species: String, quantity: Int, ageGroup: FishAgeGroup, imageData: Data?) {
        let fish = FishRecord(
            species: species,
            quantity: quantity,
            ageGroup: ageGroup,
            imageData: imageData,
            lastCountDate: Date()
        )
        fishes.append(fish)
        persist()
    }

    func updateFish(id: UUID, species: String, quantity: Int, ageGroup: FishAgeGroup, imageData: Data?) {
        guard let index = fishes.firstIndex(where: { $0.id == id }) else { return }
        fishes[index].species = species
        fishes[index].quantity = max(0, quantity)
        fishes[index].ageGroup = ageGroup
        fishes[index].imageData = imageData
        fishes[index].lastCountDate = Date()
        persist()
    }

    func deleteFish(id: UUID) {
        fishes.removeAll { $0.id == id }
        sales.removeAll { $0.fishId == id }
        persist()
    }

    func addOperation(
        fishId: UUID,
        quantity: Int,
        kind: FishOperationKind,
        date: Date
    ) {
        guard let index = fishes.firstIndex(where: { $0.id == fishId }) else { return }

        let operation = FishOperation(quantity: quantity, kind: kind, date: date)
        fishes[index].operations.insert(operation, at: 0)
        fishes[index].quantity = adjustedQuantity(current: fishes[index].quantity, amount: quantity, kind: kind)
        fishes[index].lastCountDate = date
        persist()
    }

    func updateOperation(
        fishId: UUID,
        operationId: UUID,
        quantity: Int,
        kind: FishOperationKind,
        date: Date
    ) {
        guard let fishIndex = fishes.firstIndex(where: { $0.id == fishId }),
              let opIndex = fishes[fishIndex].operations.firstIndex(where: { $0.id == operationId }) else { return }

        let oldOperation = fishes[fishIndex].operations[opIndex]
        fishes[fishIndex].quantity = rollbackQuantity(current: fishes[fishIndex].quantity, operation: oldOperation)

        fishes[fishIndex].operations[opIndex].quantity = quantity
        fishes[fishIndex].operations[opIndex].kind = kind
        fishes[fishIndex].operations[opIndex].date = date

        fishes[fishIndex].quantity = adjustedQuantity(current: fishes[fishIndex].quantity, amount: quantity, kind: kind)
        fishes[fishIndex].lastCountDate = max(date, fishes[fishIndex].lastCountDate)
        persist()
    }

    func deleteOperation(fishId: UUID, operationId: UUID) {
        guard let fishIndex = fishes.firstIndex(where: { $0.id == fishId }),
              let opIndex = fishes[fishIndex].operations.firstIndex(where: { $0.id == operationId }) else { return }

        let operation = fishes[fishIndex].operations.remove(at: opIndex)
        fishes[fishIndex].quantity = rollbackQuantity(current: fishes[fishIndex].quantity, operation: operation)
        fishes[fishIndex].quantity = max(0, fishes[fishIndex].quantity)
        persist()
    }

    func addSale(_ sale: SaleRecord) {
        sales.insert(sale, at: 0)
        if let fishId = sale.fishId, let fishIndex = fishes.firstIndex(where: { $0.id == fishId }) {
            let estimatedQuantity = Int(sale.weightKg)
            if estimatedQuantity > 0 {
                let operation = FishOperation(quantity: estimatedQuantity, kind: .sold, date: sale.date)
                fishes[fishIndex].operations.insert(operation, at: 0)
                fishes[fishIndex].quantity = adjustedQuantity(current: fishes[fishIndex].quantity, amount: estimatedQuantity, kind: .sold)
                fishes[fishIndex].lastCountDate = sale.date
            }
        } else if let fishIndex = fishes.firstIndex(where: { $0.species == sale.species }) {
            let estimatedQuantity = Int(sale.weightKg)
            if estimatedQuantity > 0 {
                let operation = FishOperation(quantity: estimatedQuantity, kind: .sold, date: sale.date)
                fishes[fishIndex].operations.insert(operation, at: 0)
                fishes[fishIndex].quantity = adjustedQuantity(current: fishes[fishIndex].quantity, amount: estimatedQuantity, kind: .sold)
                fishes[fishIndex].lastCountDate = sale.date
            }
        }
        
        persist()
    }

    func updateSale(_ sale: SaleRecord) {
        guard let index = sales.firstIndex(where: { $0.id == sale.id }) else { return }
        let oldSale = sales[index]
        if let oldFishId = oldSale.fishId, let fishIndex = fishes.firstIndex(where: { $0.id == oldFishId }) {
            let oldQuantity = Int(oldSale.weightKg)
            if oldQuantity > 0,
               let opIndex = fishes[fishIndex].operations.firstIndex(where: { $0.kind == .sold && abs($0.date.timeIntervalSince(oldSale.date)) < 1 }) {
                let oldOp = fishes[fishIndex].operations.remove(at: opIndex)
                fishes[fishIndex].quantity = rollbackQuantity(current: fishes[fishIndex].quantity, operation: oldOp)
            }
        }
        
        sales[index] = sale
        if let fishId = sale.fishId, let fishIndex = fishes.firstIndex(where: { $0.id == fishId }) {
            let newQuantity = Int(sale.weightKg)
            if newQuantity > 0 {
                let operation = FishOperation(quantity: newQuantity, kind: .sold, date: sale.date)
                fishes[fishIndex].operations.insert(operation, at: 0)
                fishes[fishIndex].quantity = adjustedQuantity(current: fishes[fishIndex].quantity, amount: newQuantity, kind: .sold)
                fishes[fishIndex].lastCountDate = sale.date
            }
        }
        
        persist()
    }

    func deleteSale(id: UUID) {
        guard let sale = sales.first(where: { $0.id == id }) else { return }
        if let fishId = sale.fishId, let fishIndex = fishes.firstIndex(where: { $0.id == fishId }) {
            let quantity = Int(sale.weightKg)
            if quantity > 0,
               let opIndex = fishes[fishIndex].operations.firstIndex(where: { $0.kind == .sold && abs($0.date.timeIntervalSince(sale.date)) < 1 }) {
                let operation = fishes[fishIndex].operations.remove(at: opIndex)
                fishes[fishIndex].quantity = rollbackQuantity(current: fishes[fishIndex].quantity, operation: operation)
            }
        }
        
        sales.removeAll { $0.id == id }
        persist()
    }

    func addReminder(name: String, details: String, date: Date) {
        reminders.insert(ReminderRecord(name: name, details: details, date: date), at: 0)
        persistAndRefreshReminders()
    }

    func updateReminder(id: UUID, name: String, details: String, date: Date) {
        guard let index = reminders.firstIndex(where: { $0.id == id }) else { return }
        reminders[index].name = name
        reminders[index].details = details
        reminders[index].date = date
        persistAndRefreshReminders()
    }

    func deleteReminder(id: UUID) {
        reminders.removeAll { $0.id == id }
        persistAndRefreshReminders()
    }

    private func persistAndRefreshReminders() {
        persist()
        notificationManager.scheduleNotifications(for: reminders)
    }

    private func adjustedQuantity(current: Int, amount: Int, kind: FishOperationKind) -> Int {
        if kind.isIncoming {
            return current + amount
        }

        return max(0, current - amount)
    }

    private func rollbackQuantity(current: Int, operation: FishOperation) -> Int {
        if operation.kind.isIncoming {
            return max(0, current - operation.quantity)
        }

        return current + operation.quantity
    }

    private func persist() {
        persistence.save(state: PersistedState(fishes: fishes, sales: sales, reminders: reminders))
    }
}
