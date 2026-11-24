import SwiftUI
 
/// Debug-only test screen. Real public data from the .gov registry, not fictional.
struct CityDirectoryScreen: View {
    /// Loaded once per launch, not every time the screen redraws.
    private static let loaded = Result { try CityDirectory.bundled() }
 
    @State private var query = ""
    @State private var kind: GovernmentKind?
 
    var body: some View {
        Group {
            switch Self.loaded {
            case .success(let directory):
                directoryList(directory)
            case .failure:
                ContentUnavailableView(
                    "City directory not found",
                    systemImage: "building.2",
                    description: Text("Add cities-MI.json to the PolicyWatch target, then run "
                        + "again.")
                )
            }
        }
        .navigationTitle("City directory")
    }
 
    private func directoryList(_ directory: CityDirectory) -> some View {
        let cities = directory.matching(query, kind: kind)
        let snapshot = directory.snapshot
        return List {
            Section {
                Picker("Type", selection: $kind) {
                    Text("All").tag(GovernmentKind?.none)
                    ForEach(GovernmentKind.allCases) { option in
                        Text(option.rawValue).tag(Optional(option))
                    }
                }
            } footer: {
                Text(String(snapshot.count) + " governments · " + snapshot.state
                    + " · registry snapshot " + String(snapshot.captured.prefix(10))
                    + ". Real public data from the .gov registry. Test build only.")
            }
            Section(String(cities.count) + " shown") {
                ForEach(cities) { city in
                    NavigationLink {
                        CityDetail(city: city)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(city.name)
                                .font(.headline)
                            Text(city.kind.rawValue + " · " + city.place + " · " + city.primary)
                                .font(.subheadline)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                if cities.isEmpty {
                    Text("No matching governments.")
                }
            }
        }
        .searchable(text: $query, prompt: "Name, city or domain")
    }
}
 
struct CityDetail: View {
    let city: CityEntry
 
    var body: some View {
        List {
            Section {
                LabeledContent("Type", value: city.kind.rawValue)
                LabeledContent("Mailing address", value: city.place)
                LabeledContent("Main domain", value: city.primary)
            }
            Section("Registered .gov domains") {
                ForEach(city.domains) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        if let url = item.website {
                            Link(item.domain, destination: url)
                        } else {
                            Text(item.domain)
                        }
                        Text(item.org)
                            .font(.footnote)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            Text("Not every registered domain runs a website. If a link doesn't load, the "
                + "registration may be unused. Council agendas and bills usually live on a "
                + "separate system and come in a later phase.")
                .font(.footnote)
        }
        .navigationTitle(city.name)
    }
}
