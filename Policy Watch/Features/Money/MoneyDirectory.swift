import SwiftUI

struct MoneyDirectory: View {
    @State private var query = ""

    private var term: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var officials: [Official] {
        Official.directory.filter { official in
            term.isEmpty || [official.name, official.chamber.rawValue, official.seat]
                .contains { $0.localizedCaseInsensitiveContains(term) }
        }
    }

    /// State and local fixtures stay money-only until a later phase.
    private var moneyOnly: [MoneyCandidate] {
        let federal = Set(Official.directory.map(\.id))
        return MoneyCandidate.directory.filter { person in
            !federal.contains(person.id)
                && (term.isEmpty || [person.name, person.office, person.place]
                    .contains { $0.localizedCaseInsensitiveContains(term) })
        }
    }

    var body: some View {
        List {
            Section {
                NavigationLink("Federal source sample") {
                    FederalSample()
                }
            }
            Section("Congress and President · fictional profiles") {
                ForEach(officials) { official in
                    NavigationLink {
                        ProfileScreen(official: official)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(official.name)
                                .font(.headline)
                            Text(official.officeLine)
                                .font(.subheadline)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                if officials.isEmpty {
                    Text("No matching profiles.")
                }
            }
            Section("State and local · Follow the Money only") {
                ForEach(moneyOnly) { person in
                    NavigationLink {
                        List {
                            Text(person.office + " · " + person.place)
                            Text("Demo committee · " + person.committee)
                            Text("Full profiles cover Congress and the President for now.")
                                .font(.footnote)
                            NavigationLink("Follow the Money") {
                                MoneyScreen(person: person)
                            }
                        }
                        .navigationTitle(person.name)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(person.name)
                                .font(.headline)
                            Text(person.office + " · " + person.place)
                                .font(.subheadline)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                if moneyOnly.isEmpty {
                    Text("No matching profiles.")
                }
            }
        }
        .searchable(text: $query, prompt: "Name, office or jurisdiction")
        .navigationTitle("Politicians")
    }
}
