import SwiftUI
import UniformTypeIdentifiers
 
/// One bounded OpenFEC sample made on your Mac by Tools/fec_sample.py.
struct FederalSnapshot: Codable {
     let committee: String
     let captured: String
     let cycle: Int
     let rows: [FederalReceipt]
 
     /// Rejects files that don't look like the prototype's output.
     var isValid: Bool {
         !committee.isEmpty && rows.count <= 20 && Set(rows.map(\.id)).count == rows.count
     }
}
 
struct FederalReceipt: Codable, Identifiable {
     let id: String
     let payer: String
     let day: String
     let filing: String
     let amount: Decimal?
     let link: String?
 
     /// Only official FEC HTTPS links are opened.
     var officialLink: URL? {
         guard let link, let url = URL(string: link), url.scheme == "https",
               let host = url.host(), ["docquery.fec.gov", "www.fec.gov"].contains(host) else {
             return nil
         }
         return url
     }
}
 
struct FederalSample: View {
     @AppStorage("money.federalSample.v1") private var bytes = Data()
     @State private var picking = false
     @State private var message = ""
 
     private var snapshot: FederalSnapshot? {
         try? JSONDecoder().decode(FederalSnapshot.self, from: bytes)
     }
 
     var body: some View {
         List {
             Section {
                 Button("Import federal sample") { picking = true }
                 if !message.isEmpty {
                     Text(message)
                 }
             }
             if let sample = snapshot {
                 Section("OpenFEC · limited receipt sample") {
                     Text(sample.committee + " · cycle " + String(sample.cycle))
                     Text("Snapshot " + sample.captured)
                     Text("Up to 20 itemized receipts. This is not a cycle total. Check the "
                         + "official filing for updates.")
                         .font(.footnote)
                     if sample.rows.isEmpty {
                         Text("No itemized rows returned.")
                     }
                     ForEach(sample.rows) { row in
                         NavigationLink(row.payer + " · " + row.day) {
                             FederalReceiptDetail(row: row, sample: sample)
                         }
                     }
                 }
             } else {
                 Text("Import the JSON produced by the federal prototype.")
             }
         }
         .navigationTitle("Federal source sample")
         .fileImporter(isPresented: $picking, allowedContentTypes: [.json]) { result in
             importSample(result)
         }
     }
 
     /// A bad file never replaces the last good sample.
     private func importSample(_ result: Result<URL, Error>) {
         do {
             let url = try result.get()
             let secured = url.startAccessingSecurityScopedResource()
             defer {
                 if secured { url.stopAccessingSecurityScopedResource() }
             }
             let data = try Data(contentsOf: url)
             let sample = try JSONDecoder().decode(FederalSnapshot.self, from: data)
             guard sample.isValid else { throw CocoaError(.fileReadCorruptFile) }
             bytes = data
             message = "Federal sample imported."
         } catch {
             message = "Import failed. The previous sample is unchanged."
         }
     }
}
 
struct FederalReceiptDetail: View {
     let row: FederalReceipt
     let sample: FederalSnapshot
 
     var body: some View {
         List {
             LabeledContent("Itemized receipt", value: row.day)
             LabeledContent("Payer as reported", value: row.payer)
             LabeledContent("Committee", value: sample.committee)
             LabeledContent(
                 "Amount",
                 value: row.amount?.formatted(.currency(code: "USD")) ?? "Amount undisclosed"
             )
             LabeledContent("Filing", value: row.filing)
             LabeledContent("Record", value: row.id)
             Text("Cycle " + String(sample.cycle) + " · OpenFEC snapshot " + sample.captured)
                 .font(.footnote)
             if let url = row.officialLink {
                 Link("Open original filing", destination: url)
                 ShareLink("Share source", item: url)
             } else {
                 Text("Original filing link unavailable.")
             }
         }
         .navigationTitle("Federal receipt")
     }
}
