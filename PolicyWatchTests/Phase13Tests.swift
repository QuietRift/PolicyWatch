import Foundation
import Testing
@testable import Policy_Watch

struct Phase13Tests {
    @Test func headlineUsesShortTitleThenFallsBack() {
        let long = Policy(id: "t1", title: "A Very Long Official Title Act of 2026",
                          place: "Federal", stage: .introduced,
                          summary: "s", next: "n")
        #expect(long.headline == long.title)

        let short = Policy(id: "t2", title: "A Very Long Official Title Act of 2026",
                           place: "Federal", stage: .introduced,
                           summary: "s", next: "n", shortTitle: "Title Act")
        #expect(short.headline == "Title Act")
    }

    @Test func seeAllAppearsAtThreeFollowed() {
        #expect(!Watchlist.showsSeeAll(0))
        #expect(!Watchlist.showsSeeAll(2))
        #expect(Watchlist.showsSeeAll(3))
        #expect(Watchlist.showsSeeAll(10))
    }

    @Test func incompleteImpactIsNotShown() {
        #expect(!Impact(taxes: .noChange, affects: [], basis: "Bill text").isComplete)
        #expect(!Impact(taxes: .noChange, affects: ["Drivers"], basis: "  ").isComplete)
        #expect(Impact(taxes: .raises, affects: ["Drivers"], basis: "Bill text").isComplete)
    }

    @Test func impactSurvivesSaveAndOldCacheStillLoads() throws {
        let item = Trending.demo[1].policy
        let data = try JSONEncoder().encode(item)
        let back = try JSONDecoder().decode(Policy.self, from: data)
        #expect(back.impact == item.impact)
        #expect(back.shortTitle == item.shortTitle)

        // A record saved before Phase 13 has no shortTitle or impact.
        let old = Data("""
        {"id":"old-1","title":"Old record","place":"Federal","stage":"Pending",
        "summary":"s","next":"n"}
        """.utf8)
        let decoded = try JSONDecoder().decode(Policy.self, from: old)
        #expect(decoded.impact == nil)
        #expect(decoded.headline == "Old record")
    }

    @Test func everySampleHasACompleteImpact() {
        let all = Trending.demo.map(\.policy) + Policy.samples
        for item in all {
            #expect(item.impact?.isComplete == true, "Missing impact: \(item.id)")
            #expect(item.shortTitle != nil, "Missing short title: \(item.id)")
        }
    }
}
