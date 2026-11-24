import SwiftUI

/// One screen for Explore, Saved and the full watchlist (Home → See all).
struct PolicyShelf: View {
    let shelf: Shelf
    @EnvironmentObject var feed: Feed
    @EnvironmentObject var library: Library
    @State private var query = ""

    private var records: [Policy] {
        let current = feed.items + Policy.samples
        let selected: [Policy]
        if shelf == .explore {
            selected = current
        } else {
            selected = library.items(on: shelf).map { stored in
                current.first { $0.id == stored.id } ?? stored
            }
        }
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return selected }
        return selected.filter { item in
            [item.title, item.place, item.id, item.summary, item.agency ?? ""]
                .contains { $0.localizedCaseInsensitiveContains(term) }
        }
    }

    private var emptyMessage: String {
        if !query.isEmpty {
            return "No matching records in the loaded catalog."
        }
        switch shelf {
        case .watch: return "Follow a policy to see its next action here."
        case .saved: return "Save a policy to keep it here."
        case .explore: return "No records loaded. Refresh Home and try again."
        }
    }

    var body: some View {
        List {
            if records.isEmpty {
                Text(emptyMessage)
            }
            ForEach(records) { item in
                NavigationLink {
                    PolicyDetail(item: item)
                } label: {
                    PolicyRow(item: item)
                }
            }
        }
        .searchable(text: $query, prompt: "Title, agency, ID or place")
        .navigationTitle(shelf.title)
    }
}
