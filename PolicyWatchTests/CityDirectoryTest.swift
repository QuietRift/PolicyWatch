import Foundation
import Testing
@testable import Policy_Watch
 
/// Small hand-written snapshot. Shaped like Tools/city_directory.py output.
private let sample = """
    {"source": "test", "state": "MI", "captured": "2026-11-23T14:00:00+00:00", "count": 2,
     "cities": [
      {"id": "MI-city-of-detroit-detroit", "name": "City of Detroit", "kind": "City",
       "state": "MI", "mailingCity": "Detroit", "primary": "detroit.gov",
       "domains": [{"domain": "detroit.gov", "org": "City of Detroit"},
                   {"domain": "detroitmi.gov", "org": "City of Detroit - ITSD"}]},
      {"id": "MI-kalamazoo-public-library-kalamazoo", "name": "Kalamazoo Public Library",
       "kind": "Other", "state": "MI", "mailingCity": "Kalamazoo", "primary": "kpl.gov",
       "domains": [{"domain": "kpl.gov", "org": "Kalamazoo Public Library"}]}
     ]}
    """
 
struct CityDirectoryTests {
    @Test func decodesAndSearches() throws {
        let directory = try CityDirectory.decode(Data(sample.utf8))
        #expect(directory.matching("").count == 2)
        #expect(directory.matching("detroitmi").first?.name == "City of Detroit")
        #expect(directory.matching("", kind: .city).count == 1)
        #expect(directory.matching("nowhere").isEmpty)
    }
 
    @Test func rejectsCountMismatch() {
        let broken = sample.replacingOccurrences(of: "\"count\": 2", with: "\"count\": 3")
        #expect(throws: (any Error).self) {
            try CityDirectory.decode(Data(broken.utf8))
        }
    }
 
    @Test func opensOnlyGovDomains() {
        #expect(CityDomain(domain: "detroit.gov", org: "x").website?.absoluteString
            == "https://detroit.gov")
        #expect(CityDomain(domain: "example.com", org: "x").website == nil)
        #expect(CityDomain(domain: "a.gov/path", org: "x").website == nil)
    }
 
    @Test func bundledFileLoads() throws {
        let directory = try CityDirectory.bundled()
        #expect(directory.snapshot.state == "MI")
        #expect(directory.snapshot.isValid)
        #expect(!directory.matching("Detroit", kind: .city).isEmpty)
    }
}
