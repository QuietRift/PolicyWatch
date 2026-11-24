import Foundation
import Combine

enum Shelf: String {
    case watch, saved, explore
    
    var title: String {
        switch self {
        case .watch: "Watch"
        case .saved: "Saved"
        case .explore: "Explore"
        }
    }
}

@MainActor
final class Library: ObservableObject {
    @Published private(set) var shelves: [String: [Policy]] = [:]
    private let defaults: UserDefaults
    private let key = "policyWatch.library.v2"
    
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let stored = try? JSONDecoder().decode([String: [Policy]].self, from: data) {
            shelves = stored
        }
    }
    
    func items(on shelf: Shelf) -> [Policy] {
        shelves[shelf.rawValue, default: []]
    }
    
    func contains(_ item: Policy, on shelf: Shelf) -> Bool {
        items(on: shelf).contains { $0.id == item.id }
    }
    
    func toggle(_ item: Policy, on shelf: Shelf) {
        guard shelf != .explore else { return }
        var rows = items(on: shelf)
        if contains(item, on: shelf) {
            rows.removeAll { $0.id == item.id }
        } else {
            rows.append(item)
        }
        shelves[shelf.rawValue] = rows
        if let data = try? JSONEncoder().encode(shelves) {
            defaults.set(data, forKey: key)
        }
    }
}
