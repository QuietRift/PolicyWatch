import Foundation
 
enum MoneyKind: String, CaseIterable, Identifiable, Codable {
     case individual = "Individual receipt"
     case committee = "Committee receipt"
     case spending = "Campaign spending"
     case outside = "Independent spending"
     case lobbying = "Lobbying disclosure"
 
     var id: Self { self }
}
 
/// Date filter for the March demo fixture.
enum DateWindow: String, CaseIterable, Identifiable, Codable {
     case entire = "Entire period"
     case firstHalf = "March 1–15"
     case secondHalf = "March 16–31"
 
     var id: Self { self }
 
     /// Days are ISO dates, so text order is date order.
     func contains(_ day: String) -> Bool {
         switch self {
         case .entire: true
         case .firstHalf: day <= "2026-03-15"
         case .secondHalf: day >= "2026-03-16"
         }
     }
}
 
struct MoneyEntry: Identifiable, Hashable {
     let id: String
     let kind: MoneyKind
     let day: String
     let payer: String
     let recipient: String
     /// nil means not disclosed. It is never shown as zero.
     let dollars: Int?
     let filing: String
     let amended: Bool
 
     var amount: String {
         dollars.map { $0.formatted(.currency(code: "USD")) } ?? "Amount undisclosed"
     }
}
 
struct LegislativeAction: Identifiable, Hashable {
     let id: String
     let day: String
     let text: String
}
 
/// Fictional profiles only. No real person or committee is represented.
struct MoneyCandidate: Identifiable, Hashable {
     let id: String
     let name: String
     let office: String
     let place: String
     let committee: String
 
     static let fixturePeriod = "Reporting period Jan–Mar 2026 · demo snapshot April 15, 2026"
 
     static let directory = [
         MoneyCandidate(id: "D-F1", name: "Avery Vale", office: "US House (fictional)",
                        place: "Federal", committee: "Vale Demo Committee"),
         MoneyCandidate(id: "D-M1", name: "Morgan Elm", office: "State House (fictional)",
                        place: "Michigan", committee: "Elm Demo Committee"),
         MoneyCandidate(id: "D-L1", name: "Robin Ash", office: "City Council (fictional)",
                        place: "Detroit / Wayne County", committee: "Ash Demo Committee")
     ]
 
     func entries(cycle: Int) -> [MoneyEntry] {
         guard id == "D-F1", cycle == 2026 else { return [] }
         return [
             MoneyEntry(id: "T1", kind: .individual, day: "2026-03-02",
                        payer: "Casey Birch", recipient: committee,
                        dollars: 125, filing: "DEMO-Q1-A1", amended: true),
             MoneyEntry(id: "T2", kind: .committee, day: "2026-03-10",
                        payer: "Sample Civic PAC", recipient: committee,
                        dollars: 500, filing: "DEMO-Q1", amended: false),
             MoneyEntry(id: "T3", kind: .spending, day: "2026-03-12",
                        payer: committee, recipient: "Sample Print",
                        dollars: 90, filing: "DEMO-Q1", amended: false),
             MoneyEntry(id: "T4", kind: .outside, day: "2026-03-18",
                        payer: "Sample Independent Fund", recipient: "Sample Media",
                        dollars: 200, filing: "DEMO-IE1", amended: false),
             MoneyEntry(id: "T5", kind: .lobbying, day: "2026-03-21",
                        payer: "Sample Association", recipient: "Sample Advocate",
                        dollars: nil, filing: "DEMO-L1", amended: false)
         ]
     }
 
     func actions(cycle: Int) -> [LegislativeAction] {
         guard id == "D-F1", cycle == 2026 else { return [] }
         return [
             LegislativeAction(id: "A1", day: "2026-03-19", text: "Demo Bill 14 · committee vote")
         ]
     }
}
 
enum MoneyMath {
     /// A total appears only when every row in it has a disclosed amount.
     static func total(of kind: MoneyKind, in rows: [MoneyEntry]) -> Int? {
         let matching = rows.filter { $0.kind == kind }
         guard !matching.isEmpty else { return nil }
         let amounts = matching.compactMap(\.dollars)
         guard amounts.count == matching.count else { return nil }
         return amounts.reduce(0, +)
     }
 
     /// Filters only the transaction list. Summaries use the full period.
     static func filter(
         _ rows: [MoneyEntry],
         kind: MoneyKind?,
         window: DateWindow
     ) -> [MoneyEntry] {
         rows.filter { row in
             (kind == nil || row.kind == kind) && window.contains(row.day)
         }
     }
}
 
struct SavedMoneyView: Codable, Equatable {
     let personID: String
     let cycle: Int
     let kind: MoneyKind?
     let window: DateWindow
}
