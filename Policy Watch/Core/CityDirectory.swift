import Foundation
 
/// One .gov registry snapshot made on your Mac by Tools/city_directory.py.
struct CitySnapshot: Codable {
    let source: String
    let state: String
    let captured: String
    let count: Int
    let cities: [CityEntry]
 
    /// Rejects files that don't look like the tool's output.
    var isValid: Bool {
        !cities.isEmpty && count == cities.count
            && Set(cities.map(\.id)).count == cities.count
            && cities.allSatisfy { !$0.domains.isEmpty }
    }
}
 
/// The registry files all of these under "City". The tool sorts them by name.
enum GovernmentKind: String, Codable, CaseIterable, Identifiable {
    case city = "City"
    case village = "Village"
    case township = "Township"
    case other = "Other"
 
    var id: Self { self }
}
 
/// One local government and every .gov domain it registered.
struct CityEntry: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let kind: GovernmentKind
    let state: String
    let mailingCity: String
    let primary: String
    let domains: [CityDomain]
 
    /// The registry lists a mailing address, not the area the government serves.
    var place: String {
        mailingCity.isEmpty ? state : mailingCity + ", " + state
    }
}
 
struct CityDomain: Codable, Hashable, Identifiable {
    let domain: String
    let org: String
 
    var id: String { domain }
 
    /// Only HTTPS links to the registered .gov name itself are opened.
    var website: URL? {
        guard domain.hasSuffix(".gov"), !domain.contains("/"),
              let url = URL(string: "https://" + domain), url.host() == domain else {
            return nil
        }
        return url
    }
}
 
/// Where the app gets cities. Today: a file bundled for testing.
/// Later: add another loader (your backend) and the screens stay the same.
struct CityDirectory {
    let snapshot: CitySnapshot
 
    enum LoadError: Error {
        case missing
        case invalid
    }
 
    static func bundled(_ name: String = "cities-MI", in bundle: Bundle = .main) throws
        -> CityDirectory {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw LoadError.missing
        }
        return try decode(Data(contentsOf: url))
    }
 
    static func decode(_ data: Data) throws -> CityDirectory {
        let snapshot = try JSONDecoder().decode(CitySnapshot.self, from: data)
        guard snapshot.isValid else { throw LoadError.invalid }
        return CityDirectory(snapshot: snapshot)
    }
 
    /// Matches name, mailing city or any domain. An empty search returns everything.
    func matching(_ query: String, kind: GovernmentKind? = nil) -> [CityEntry] {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return snapshot.cities.filter { city in
            guard kind == nil || city.kind == kind else { return false }
            if term.isEmpty { return true }
            return [city.name, city.mailingCity].contains {
                $0.localizedCaseInsensitiveContains(term)
            } || city.domains.contains { $0.domain.localizedCaseInsensitiveContains(term) }
        }
    }
}
