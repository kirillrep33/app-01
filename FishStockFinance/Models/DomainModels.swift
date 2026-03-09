import Foundation

enum FishAgeGroup: String, Codable, CaseIterable, Identifiable {
    case young = "Young"
    case fattened = "Fattened"
    case market = "Market"

    var id: String { rawValue }
}

enum FishOperationKind: String, Codable, CaseIterable, Identifiable {
    case incomingFry = "Fry"
    case sold = "Sold"
    case dead = "Dead"

    var id: String { rawValue }

    var isIncoming: Bool { self == .incomingFry }
}

struct FishOperation: Identifiable, Codable, Hashable {
    let id: UUID
    var quantity: Int
    var kind: FishOperationKind
    var date: Date

    init(id: UUID = UUID(), quantity: Int, kind: FishOperationKind, date: Date) {
        self.id = id
        self.quantity = quantity
        self.kind = kind
        self.date = date
    }
}

struct FishRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var species: String
    var quantity: Int
    var ageGroup: FishAgeGroup
    var imageData: Data?
    var lastCountDate: Date
    var operations: [FishOperation]

    init(
        id: UUID = UUID(),
        species: String,
        quantity: Int,
        ageGroup: FishAgeGroup,
        imageData: Data? = nil,
        lastCountDate: Date,
        operations: [FishOperation] = []
    ) {
        self.id = id
        self.species = species
        self.quantity = quantity
        self.ageGroup = ageGroup
        self.imageData = imageData
        self.lastCountDate = lastCountDate
        self.operations = operations
    }
}

enum BuyerCategory: String, Codable, CaseIterable, Identifiable {
    case wholesaler = "Wholesaler"
    case retail = "Retail"
    case restaurant = "Restaurant"

    var id: String { rawValue }
}

struct SaleRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var fishId: UUID?
    var species: String
    var weightKg: Double
    var totalPrice: Double
    var buyer: String
    var category: BuyerCategory
    var date: Date

    init(
        id: UUID = UUID(),
        fishId: UUID? = nil,
        species: String,
        weightKg: Double,
        totalPrice: Double,
        buyer: String,
        category: BuyerCategory,
        date: Date
    ) {
        self.id = id
        self.fishId = fishId
        self.species = species
        self.weightKg = weightKg
        self.totalPrice = totalPrice
        self.buyer = buyer
        self.category = category
        self.date = date
    }

    var pricePerKg: Double {
        guard weightKg > 0 else { return 0 }
        return totalPrice / weightKg
    }
}

struct ReminderRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var details: String
    var date: Date

    init(id: UUID = UUID(), name: String, details: String, date: Date) {
        self.id = id
        self.name = name
        self.details = details
        self.date = date
    }
}

struct PersistedState: Codable {
    var fishes: [FishRecord]
    var sales: [SaleRecord]
    var reminders: [ReminderRecord]
}
