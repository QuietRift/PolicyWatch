import Foundation
import Combine

protocol FeedSource: Sendable {
    func load(_ url: URL) async throws -> (Data, URLResponse)
}

struct LiveFeedSource: FeedSource {
    func load(_ url:  URL) async throws -> (Data, URLResponse) {
        try await URLSession.shared.data(from: url)
    }
}

struct FederalRegisterPage: Decodable {
    struct Agency: Decodable {
             let name: String?
         }
     
         struct Document: Decodable {
             let documentNumber: String
             let title: String
             let type: String
             let publicationDate: String
             let htmlURL: URL
             let pdfURL: URL?
             let abstract: String?
             let agencies: [Agency]?
     
             enum CodingKeys: String, CodingKey {
                 case title, type, abstract, agencies
                 case documentNumber = "document_number"
                 case publicationDate = "publication_date"
                 case htmlURL = "html_url"
                 case pdfURL = "pdf_url"
             }
         }
     
         let results: [Document]
    }
     
    extension FederalRegisterPage.Document {
         var policy: Policy {
             let names = (agencies ?? []).compactMap(\.name)
             return Policy(
                 id: "fr-" + documentNumber,
                 title: title,
                 place: "Federal",
                 stage: .published,
                 summary: abstract ?? "No abstract was published. Open the source for details.",
                 next: "Check the published document for comment deadlines and effective dates.",
                 lastAction: publicationDate + " · Published in the Federal Register",
                 documentType: type,
                 agency: names.isEmpty ? nil : names.joined(separator: ", "),
                 source: pdfURL ?? htmlURL,
                 published: publicationDate
             )
         }
    }
     
    @MainActor
    final class Feed: ObservableObject {
         @Published private(set) var items: [Policy] = []
         @Published private(set) var checked: Date?
         @Published private(set) var loading = false
         @Published private(set) var problem: String?
     
         static let endpoint = URL(string: "https://www.federalregister.gov/api/v1/documents.json")!
             .appending(queryItems: [
                 URLQueryItem(name: "order", value: "newest"),
                 URLQueryItem(name: "per_page", value: "20")
             ])
     
         private let source: FeedSource
         private let defaults: UserDefaults
         private let key = "policyWatch.feed.v2"
     
         private struct Snapshot: Codable {
             let items: [Policy]
             let checked: Date
         }
     
         init(source: FeedSource = LiveFeedSource(), defaults: UserDefaults = .standard) {
             self.source = source
             self.defaults = defaults
             if let data = defaults.data(forKey: key),
                let cache = try? JSONDecoder().decode(Snapshot.self, from: data) {
                 items = cache.items
                 checked = cache.checked
             }
         }
     
         /// On failure, keeps the last verified records and their check time.
         func refresh() async {
             guard !loading else { return }
             loading = true
             defer { loading = false }
             do {
                 let (data, response) = try await source.load(Self.endpoint)
                 guard let http = response as? HTTPURLResponse,
                       (200..<300).contains(http.statusCode) else {
                     throw URLError(.badServerResponse)
                 }
                 let page = try JSONDecoder().decode(FederalRegisterPage.self, from: data)
                 let records = page.results.map(\.policy)
                 let snapshot = Snapshot(items: records, checked: .now)
                 defaults.set(try JSONEncoder().encode(snapshot), forKey: key)
                 items = records
                 checked = snapshot.checked
                 problem = nil
             } catch {
                 problem = "Refresh failed. Showing the last verified records."
             }
         }
}
