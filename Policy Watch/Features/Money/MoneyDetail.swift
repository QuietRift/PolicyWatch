import SwiftUI
 
struct MoneyDetail: View {
     let row: MoneyEntry
     let person: MoneyCandidate
 
     var body: some View {
         List {
             Section("Fictional disclosure · demo data") {
                 LabeledContent("Category", value: row.kind.rawValue)
                 LabeledContent("Transaction date", value: row.day)
                 LabeledContent("Reported amount", value: row.amount)
                 LabeledContent("Reported payer", value: row.payer)
                 LabeledContent("Reported recipient", value: row.recipient)
             }
             Section("Source detail") {
                 LabeledContent("Profile", value: person.id)
                 LabeledContent("Transaction", value: row.id)
                 LabeledContent("Filing", value: row.filing)
                 Text(row.amended ? "Amended · current revision" : "Original demo filing")
                 Text(MoneyCandidate.fixturePeriod)
                 Text("Fictional fixture. No government filing exists for this row.")
                     .font(.footnote.bold())
                 NavigationLink("Read methodology") {
                     MoneyMethod()
                 }
             }
         }
         .navigationTitle("Transaction detail")
     }
}
 
struct MoneyMethod: View {
     // Verify both links against the official sites before release.
     private static let fec = URL(string: "https://www.fec.gov/data/")!
     private static let michigan =
         URL(string: "https://www.michigan.gov/sos/elections/disclosure/mitn-information")!
 
     private let correction = """
     Policy Watch correction
     Record ID:
     Disputed field:
     Official filing URL:
     Proposed correction:
     """
 
     var body: some View {
         List {
             Section("Reading a disclosure") {
                 Text("Direct receipts go to the candidate's committee. Independent spending is "
                     + "paid by someone else and is not a receipt. A listed employer describes "
                     + "the contributor's job; it does not mean the employer donated.")
                 Text("Filing delays, reporting thresholds and amendments affect coverage. "
                     + "Missing amounts display as undisclosed, never as zero.")
                 Text("Shared names or nearby dates cannot establish identity or influence. The "
                     + "demo timeline links records only by an explicit profile ID.")
                 Text("Federal law limits using individual contributor information from FEC "
                     + "reports to solicit contributions or for commercial purposes.")
             }
             Section("Verify or request a correction") {
                 Text("Check the filing identifier and amendment at the issuing authority. "
                     + "Share the record ID, the disputed field and the supporting filing with "
                     + "your Policy Watch reviewer.")
                 ShareLink("Prepare correction note", item: correction)
                 Link("Federal Election Commission data", destination: Self.fec)
                 Link("Michigan Transparency Network", destination: Self.michigan)
             }
         }
         .navigationTitle("Methodology")
     }
}
