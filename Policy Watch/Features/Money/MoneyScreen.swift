import SwiftUI
 
struct MoneyScreen: View {
     let person: MoneyCandidate
     @State private var cycle = 2026
     @State private var kind: MoneyKind?
     @State private var window = DateWindow.entire
     @AppStorage("money.savedView.v2") private var savedData = Data()
 
     private var rows: [MoneyEntry] { person.entries(cycle: cycle) }
     private var visible: [MoneyEntry] { MoneyMath.filter(rows, kind: kind, window: window) }
     private var savedView: SavedMoneyView? {
         guard let view = try? JSONDecoder().decode(SavedMoneyView.self, from: savedData),
               view.personID == person.id else { return nil }
         return view
     }
 
     var body: some View {
         List {
             Section("Source and coverage") {
                 Text(person.name + " · " + person.place)
                 Text("Fictional demo data · cycle " + String(cycle))
                     .font(.footnote.bold())
                 Text(rows.isEmpty
                      ? "Coverage unavailable for this selection."
                      : MoneyCandidate.fixturePeriod)
                     .font(.footnote)
                 Picker("Election cycle", selection: $cycle) {
                     ForEach([2026, 2024], id: \.self) { year in
                         Text(String(year)).tag(year)
                     }
                 }
             }
             Section("Reporting-period summary · committee activity") {
                 ForEach([MoneyKind.individual, .committee, .spending]) { item in
                     LabeledContent(item.rawValue, value: totalText(item))
                         .monospacedDigit()
                 }
             }
             Section("Transactions") {
                 Picker("Category", selection: $kind) {
                     Text("All").tag(MoneyKind?.none)
                     ForEach(MoneyKind.allCases) { item in
                         Text(item.rawValue).tag(Optional(item))
                     }
                 }
                 Picker("Dates", selection: $window) {
                     ForEach(DateWindow.allCases) { item in
                         Text(item.rawValue).tag(item)
                     }
                 }
                 ForEach(visible) { row in
                     NavigationLink {
                         MoneyDetail(row: row, person: person)
                     } label: {
                         VStack(alignment: .leading) {
                             Text(row.kind.rawValue + " · " + row.amount)
                                 .monospacedDigit()
                             Text(row.day + " · " + row.payer)
                                 .font(.footnote)
                         }
                         .accessibilityElement(children: .combine)
                     }
                 }
                 if visible.isEmpty {
                     Text("No records for this selection.")
                 }
                 Button("Save this view") { save() }
                 if let saved = savedView {
                     Button("Restore saved view") {
                         cycle = saved.cycle
                         kind = saved.kind
                         window = saved.window
                     }
                 }
             }
             Section("Outside spending and lobbying · not committee receipts") {
                 ForEach([MoneyKind.outside, .lobbying]) { item in
                     let matching = rows.filter { $0.kind == item }
                     Text(item.rawValue)
                         .font(.headline)
                     if matching.isEmpty {
                         Text("Coverage unavailable.")
                     }
                     ForEach(matching) { row in
                         NavigationLink(row.payer + " · " + row.amount) {
                             MoneyDetail(row: row, person: person)
                         }
                     }
                 }
             }
             Section {
                 NavigationLink("Public-record timeline") { timeline }
                 NavigationLink("Methodology and corrections") { MoneyMethod() }
             }
         }
         .navigationTitle("Follow the Money")
     }
 
     /// Two separate tracks. Nearby dates are never presented as a link.
     private var timeline: some View {
         List {
             Section("Financial disclosures · demo") {
                 if rows.isEmpty {
                     Text("No disclosure coverage.")
                 }
                 ForEach(rows.sorted { $0.day < $1.day }) { row in
                     NavigationLink(row.day + " · " + row.kind.rawValue) {
                         MoneyDetail(row: row, person: person)
                     }
                 }
             }
             Section("Legislative actions · separate track") {
                 let actions = person.actions(cycle: cycle)
                 if actions.isEmpty {
                     Text("No matched actions.")
                 }
                 ForEach(actions) { action in
                     Text(action.day + " · " + action.text)
                 }
                 if !actions.isEmpty {
                     Text("Demo match by profile ID " + person.id
                          + ". Timing alone cannot establish influence.")
                         .font(.footnote)
                 }
             }
         }
         .navigationTitle("Public-record timeline")
     }
 
     /// "Unavailable" when there is no coverage or any amount is undisclosed.
     private func totalText(_ kind: MoneyKind) -> String {
         MoneyMath.total(of: kind, in: rows)?.formatted(.currency(code: "USD")) ?? "Unavailable"
     }
 
     private func save() {
         let view = SavedMoneyView(personID: person.id, cycle: cycle, kind: kind, window: window)
         if let data = try? JSONEncoder().encode(view) {
             savedData = data
         }
     }
}
