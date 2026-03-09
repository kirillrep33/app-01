import Foundation
import Combine

@MainActor
final class FishListViewModel: ObservableObject {
    @Published private(set) var fishes: [FishRecord] = []

    private let store: FishStockStore

    init(store: FishStockStore) {
        self.store = store
        self.fishes = store.fishes

        store.$fishes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.fishes = $0
            }
            .store(in: &cancellables)
    }

    func addFish(species: String, quantity: Int, ageGroup: FishAgeGroup, imageData: Data?) {
        store.addFish(species: species, quantity: quantity, ageGroup: ageGroup, imageData: imageData)
    }

    func updateFish(id: UUID, species: String, quantity: Int, ageGroup: FishAgeGroup, imageData: Data?) {
        store.updateFish(id: id, species: species, quantity: quantity, ageGroup: ageGroup, imageData: imageData)
    }

    func deleteFish(id: UUID) {
        store.deleteFish(id: id)
    }

    func addOperation(fishId: UUID, quantity: Int, kind: FishOperationKind, date: Date) {
        store.addOperation(fishId: fishId, quantity: quantity, kind: kind, date: date)
    }

    func updateOperation(fishId: UUID, operationId: UUID, quantity: Int, kind: FishOperationKind, date: Date) {
        store.updateOperation(fishId: fishId, operationId: operationId, quantity: quantity, kind: kind, date: date)
    }

    func deleteOperation(fishId: UUID, operationId: UUID) {
        store.deleteOperation(fishId: fishId, operationId: operationId)
    }

    func fish(by id: UUID) -> FishRecord? {
        store.fishes.first(where: { $0.id == id })
    }

    private var cancellables: Set<AnyCancellable> = []
}

@MainActor
final class SalesListViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedCategory: BuyerCategory? = nil
    @Published var selectedDate: Date? = nil
    @Published var sortAscending: Bool = true
    @Published private(set) var sales: [SaleRecord] = []

    private let store: FishStockStore
    private var cancellables: Set<AnyCancellable> = []

    init(store: FishStockStore) {
        self.store = store
        self.sales = store.sales

        store.$sales
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.sales = $0
            }
            .store(in: &cancellables)
    }

    var filteredSales: [SaleRecord] {
        let filtered = sales.filter { sale in
            let matchesSearch = searchText.isEmpty || sale.species.localizedCaseInsensitiveContains(searchText) || sale.buyer.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || sale.category == selectedCategory
            return matchesSearch && matchesCategory
        }
        
        return filtered.sorted { sale1, sale2 in
            if sortAscending {
                return sale1.date < sale2.date
            } else {
                return sale1.date > sale2.date
            }
        }
    }
    
    func toggleSort() {
        sortAscending.toggle()
    }

    var speciesOptions: [String] {
        Array(Set(store.fishes.map(\.species))).sorted()
    }

    func addSale(_ sale: SaleRecord) { store.addSale(sale) }
    func updateSale(_ sale: SaleRecord) { store.updateSale(sale) }
    func deleteSale(id: UUID) { store.deleteSale(id: id) }
}

@MainActor
final class NotificationsViewModel: ObservableObject {
    @Published private(set) var reminders: [ReminderRecord] = []

    private let store: FishStockStore
    private var cancellables: Set<AnyCancellable> = []

    init(store: FishStockStore) {
        self.store = store
        self.reminders = store.reminders

        store.$reminders
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.reminders = $0
            }
            .store(in: &cancellables)
    }

    func add(name: String, details: String, date: Date) {
        store.addReminder(name: name, details: details, date: date)
    }

    func update(id: UUID, name: String, details: String, date: Date) {
        store.updateReminder(id: id, name: name, details: details, date: date)
    }

    func delete(id: UUID) {
        store.deleteReminder(id: id)
    }
}

@MainActor
final class StatisticsViewModel: ObservableObject {
    enum Mode: String, CaseIterable, Identifiable {
        case livestock = "Livestock"
        case sales = "Sales"

        var id: String { rawValue }
    }

    @Published var mode: Mode = .sales
    @Published private(set) var fishes: [FishRecord] = []
    @Published private(set) var sales: [SaleRecord] = []

    private let store: FishStockStore
    private var cancellables: Set<AnyCancellable> = []

    init(store: FishStockStore) {
        self.store = store
        self.fishes = store.fishes
        self.sales = store.sales

        Publishers.CombineLatest(store.$fishes, store.$sales)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] fishes, sales in
                self?.fishes = fishes
                self?.sales = sales
            }
            .store(in: &cancellables)
    }

    var monthlyRevenue: Double {
        let month = Calendar.current.component(.month, from: Date())
        let year = Calendar.current.component(.year, from: Date())

        return sales
            .filter {
                Calendar.current.component(.month, from: $0.date) == month &&
                Calendar.current.component(.year, from: $0.date) == year
            }
            .reduce(0) { $0 + $1.totalPrice }
    }

    var annualRevenue: Double {
        let year = Calendar.current.component(.year, from: Date())
        return sales
            .filter { Calendar.current.component(.year, from: $0.date) == year }
            .reduce(0) { $0 + $1.totalPrice }
    }

    var topBuyerLine: String {
        let grouped = Dictionary(grouping: sales, by: \.buyer)
            .mapValues { $0.reduce(0) { $0 + $1.totalPrice } }

        guard let top = grouped.max(by: { $0.value < $1.value }) else {
            return "No sales yet"
        }

        return "\(top.key) - \(Formatters.currency(top.value))"
    }

    var topBuyer: (name: String, total: Double)? {
        let grouped = Dictionary(grouping: sales, by: \.buyer)
            .mapValues { $0.reduce(0) { $0 + $1.totalPrice } }

        guard let top = grouped.max(by: { $0.value < $1.value }) else {
            return nil
        }

        return (name: top.key, total: top.value)
    }
    
    var buyersDistribution: [(name: String, total: Double, percent: Double)] {
        let totalRevenue = sales.reduce(0) { $0 + $1.totalPrice }
        guard totalRevenue > 0 else { return [] }
        
        let grouped = Dictionary(grouping: sales, by: \.buyer)
            .mapValues { $0.reduce(0) { $0 + $1.totalPrice } }
        
        let sorted = grouped
            .filter { $0.value > 0 }
            .map { (name: $0.key, total: $0.value, percent: ($0.value / totalRevenue) * 100) }
            .sorted { $0.total > $1.total }

        guard !sorted.isEmpty else { return [] }

        if sorted.count <= 3 {
            return sorted
        }

        let topTwo = Array(sorted.prefix(2))
        let otherTotal = sorted.dropFirst(2).reduce(0.0) { $0 + $1.total }
        let otherPercent = (otherTotal / totalRevenue) * 100

        if otherTotal > 0 {
            return topTwo + [(name: "Other", total: otherTotal, percent: otherPercent)]
        } else {
            return topTwo
        }
    }
    var averagePricePerKg: Double {
        let totalWeight = sales.reduce(0) { $0 + $1.weightKg }
        guard totalWeight > 0 else { return 0 }
        return sales.reduce(0) { $0 + $1.totalPrice } / totalWeight
    }

    var monthlyRevenueBars: [MonthValue] {
        let grouped = Dictionary(grouping: sales) { sale -> Int in
            Calendar.current.component(.month, from: sale.date)
        }

        return (1...12).map { month in
            let total = grouped[month, default: []].reduce(0) { $0 + $1.totalPrice }
            return MonthValue(month: month, value: total)
        }
    }
    
    var last6MonthsRevenue: [MonthRevenueItem] {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)

        let isFirstHalf = currentMonth <= 6
        let startMonth = isFirstHalf ? 1 : 7
        let endMonth = startMonth + 5
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM"

        return (startMonth...endMonth).compactMap { month in
            var components = DateComponents()
            components.year = currentYear
            components.month = month
            components.day = 1
            guard let monthDate = calendar.date(from: components) else { return nil }

            let salesForMonth = sales.filter {
                let saleMonth = calendar.component(.month, from: $0.date)
                let saleYear = calendar.component(.year, from: $0.date)
                return saleMonth == month && saleYear == currentYear
            }

            let total = salesForMonth.reduce(0.0) { $0 + $1.totalPrice }
            let monthName = formatter.string(from: monthDate)
            let isCurrentMonth = month == currentMonth

            return MonthRevenueItem(month: month, monthName: monthName, value: total, isCurrentMonth: isCurrentMonth)
        }
    }

    var livestockBars: [DayValue] {
        let calendar = Calendar.current
        let today = Date()
        guard let monthInterval = calendar.dateInterval(of: .month, for: today) else { return [] }

        let monthStart = monthInterval.start
        let monthRange = calendar.range(of: .day, in: .month, for: monthStart) ?? 1..<31
        let lastDay = monthRange.count
        let checkpoints = [5, 10, 15, 20, 25, lastDay]

        let currentDay = calendar.component(.day, from: today)
        let currentCheckpointDay = checkpoints.first(where: { currentDay <= $0 }) ?? lastDay

        return checkpoints.compactMap { day in
            var components = calendar.dateComponents([.year, .month], from: monthStart)
            components.day = min(day, lastDay)
            components.hour = 23
            components.minute = 59
            components.second = 59
            guard let checkpointDate = calendar.date(from: components) else { return nil }

                let totalAtCheckpoint = fishes.reduce(0) { partial, fish in
                let rollback = fish.operations.reduce(0) { rollbackPartial, operation in
                    guard operation.date > checkpointDate else { return rollbackPartial }
                    if operation.kind.isIncoming {
                        return rollbackPartial + operation.quantity
                    } else {
                        return rollbackPartial - operation.quantity
                    }
                }
                return partial + max(0, fish.quantity - rollback)
            }

            let dayLabel = String(format: "%02d", min(day, lastDay))
            return DayValue(
                date: checkpointDate,
                value: Double(totalAtCheckpoint),
                label: dayLabel,
                isCurrentPoint: day == currentCheckpointDay
            )
        }
    }

    var livestockTableRows: [(species: String, inValue: Int, outValue: Int, result: Int)] {
        fishes.map { fish in
            let incoming = fish.operations
                .filter { $0.kind.isIncoming }
                .reduce(0) { $0 + $1.quantity }
            let outgoing = fish.operations
                .filter { !$0.kind.isIncoming }
                .reduce(0) { $0 + $1.quantity }
            return (fish.species, incoming, outgoing, fish.quantity)
        }
    }
}

struct MonthValue: Identifiable {
    let id = UUID()
    let month: Int
    let value: Double
}

struct DayValue: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let label: String
    let isCurrentPoint: Bool
}

struct MonthRevenueItem: Identifiable {
    let id = UUID()
    let month: Int
    let monthName: String
    let value: Double
    let isCurrentMonth: Bool
}
