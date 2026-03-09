import Foundation

final class PersistenceManager {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let fileName = "fish-stock-state.json"

    init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func load() -> PersistedState? {
        guard let url = fileURL(), FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(PersistedState.self, from: data)
        } catch {
            return nil
        }
    }

    func save(state: PersistedState) {
        guard let url = fileURL() else { return }

        do {
            let data = try encoder.encode(state)
            try data.write(to: url, options: [.atomic])
        } catch {
        }
    }

    private func fileURL() -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent(fileName)
    }
}
