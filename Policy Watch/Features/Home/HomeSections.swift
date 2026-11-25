import Foundation

/// Government level for the "Most searched bills" rows.
enum BillLevel: String, CaseIterable, Identifiable {
    case federal = "Federal"
    case state = "State"
    case local = "Local / City"

    var id: Self { self }
}

/// One bill in a "Most searched" row. Search counts here are demo numbers.
struct TrendingBill: Identifiable, Hashable {
    let level: BillLevel
    let searches: Int
    let policy: Policy

    var id: String { policy.id }
}

enum Trending {
    /// Fictional ranking. Real counts need anonymous totals from a server,
    /// never a record of who searched for what.
    static let demo: [TrendingBill] = [
        TrendingBill(level: .federal, searches: 1_240, policy: Policy(
            id: "trend-fed-insulin", title: "Sample Insulin Cost Act (Demo H.R. 214)",
            place: "Federal · fictional", stage: .enacted,
            summary: "The bill would cap what families pay each month for insulin.",
            next: "Next action has not been announced.",
            shortTitle: "Sample Insulin Cost Act",
            impact: Impact(
                taxes: .noChange,
                affects: ["People who use insulin", "Health insurers"],
                costToYou: "A monthly cap on insulin costs",
                basis: "the fictional bill summary"))),
        TrendingBill(level: .federal, searches: 860, policy: Policy(
            id: "trend-fed-highway", title: "Sample Highway Funding Act (Demo H.R. 388)",
            place: "Federal · fictional", stage: .pending,
            summary: "The bill would fund road repairs and add a federal fuel fee.",
            next: "A floor vote in the second chamber is the next step.",
            shortTitle: "Sample Highway Funding Act",
            impact: Impact(
                taxes: .raises,
                taxNote: "Adds a federal fee on fuel.",
                affects: ["Drivers", "Trucking companies", "Road construction workers"],
                costToYou: "A higher price per gallon of fuel",
                basis: "the fictional bill summary"))),
        TrendingBill(level: .federal, searches: 410, policy: Policy(
            id: "trend-fed-tax", title: "Sample Tax Credit Extension (Demo H.R. 402)",
            place: "Federal · fictional", stage: .failed,
            summary: "The bill would have extended a household tax credit for two years.",
            next: "The bill failed. A new version could be introduced.",
            shortTitle: "Sample Tax Credit Extension",
            impact: Impact(
                taxes: .lowers,
                taxNote: "Would have kept a household tax credit for two more years. "
                    + "The bill failed, so nothing changes.",
                affects: ["Households that claim the credit"],
                basis: "the fictional bill summary"))),
        TrendingBill(level: .state, searches: 520, policy: Policy(
            id: "trend-state-roads", title: "Sample Road Repair Bill",
            place: "Sample State · fictional", stage: .inCommittee,
            summary: "The bill would move state funds into local road repair.",
            next: "A committee hearing is the next step.",
            shortTitle: "Sample Road Repair Bill",
            impact: Impact(
                taxes: .noChange,
                taxNote: "Moves existing state money. No new tax is named.",
                affects: ["Drivers", "Local road departments"],
                basis: "the fictional bill summary"))),
        TrendingBill(level: .state, searches: 690, policy: Policy(
            id: "trend-state-water", title: "Sample Clean Water Grants",
            place: "Sample State · fictional", stage: .introduced,
            summary: "The bill would create grants to replace lead service lines.",
            next: "Next action has not been announced.",
            shortTitle: "Sample Clean Water Grants",
            impact: Impact(
                taxes: .noChange,
                affects: ["Homes with lead service lines", "Local water utilities"],
                basis: "the fictional bill summary"))),
        TrendingBill(level: .state, searches: 305, policy: Policy(
            id: "trend-state-teachers", title: "Sample Teacher Pay Bill",
            place: "Sample State · fictional", stage: .pending,
            summary: "The bill would raise the minimum salary for public school teachers.",
            next: "A floor vote is the next step.",
            shortTitle: "Sample Teacher Pay Bill",
            impact: Impact(
                taxes: .noChange,
                taxNote: "The summary does not say how the raise is paid for.",
                affects: ["Public school teachers", "School districts"],
                basis: "the fictional bill summary"))),
        TrendingBill(level: .local, searches: 330, policy: Policy.samples[0]),
        TrendingBill(level: .local, searches: 145, policy: Policy.samples[1]),
        TrendingBill(level: .local, searches: 210, policy: Policy(
            id: "trend-local-lights", title: "Street lighting plan",
            place: "Riverbend · Sample County", stage: .introduced,
            summary: "The plan would replace older streetlights with LED fixtures.",
            next: "Next action has not been announced.",
            shortTitle: "Street lighting plan",
            impact: Impact(
                taxes: .noChange,
                affects: ["Residents on streets with older lights"],
                basis: "the sample plan summary")))
    ]

    /// Most searched first, within one level.
    static func ranked(_ level: BillLevel, in bills: [TrendingBill] = demo) -> [TrendingBill] {
        bills.filter { $0.level == level }.sorted { $0.searches > $1.searches }
    }
}

enum Watchlist {
    /// Home shows a "See all" link next to the heading once this many are followed.
    static let seeAllThreshold = 3

    static func showsSeeAll(_ followedCount: Int) -> Bool {
        followedCount >= seeAllThreshold
    }

    /// The first followed records for Home, using the newest copy when the feed has one.
    static func preview(followed: [Policy], current: [Policy], limit: Int = 3) -> [Policy] {
        followed.prefix(limit).map { stored in
            current.first { $0.id == stored.id } ?? stored
        }
    }
}
