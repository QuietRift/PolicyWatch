import Foundation

enum Chamber: String, CaseIterable, Codable {
    case house = "U.S. House"
    case senate = "U.S. Senate"
    case president = "President"
    
    var castsRollCallVotes: Bool { self != .president }
}

enum Topic: String, CaseIterable, Identifiable, Codable {
    case healthCare = "Health Care"
    case energy = "Energy"
    case transportation = "Transportation"
    case taxes = "Taxes"
    
    var id: Self{self}
}

struct Statement: Identifiable, Hashable {
    let id: String
    let day: String
    let quote: String
    let venue: String
    let source: String
    let topic: Topic
    
    let linkedVoteIDs: [String]
}

struct RollCallVote: Identifiable, Hashable {
    let id: String
    let day: String
    let bill: String
    let title: String
    let question: String
    let choice: VoteChoice
    let result: String
    let topic: Topic
}

/// Fictional officials only. No real person is represented.
struct Official: Identifiable, Hashable {
    let money: MoneyCandidate
    let chamber: Chamber
    let seat: String
    let party: String
    let since: String
    let upcoming: String
    let statements: [Statement]
    let votes: [RollCallVote]

    var id: String { money.id }
    var name: String { money.name }
    var officeLine: String { chamber.rawValue + " · " + seat }

    var initials: String {
        name.split(separator: " ").compactMap { word in word.first.map { String($0) } }.joined()
    }
}

extension Official {
    static let directory: [Official] = [vale, alder, cedar]

    /// Shares profile ID D-F1 with the Phase 9 money fixture.
    static let vale = Official(
        money: MoneyCandidate.directory[0],
        chamber: .house,
        seat: "Sample State, District 4 (fictional)",
        party: "Sample Party (fictional)",
        since: "2023",
        upcoming: "Next election November 3, 2026",
        statements: [
            Statement(id: "S1", day: "2025-02-11",
                      quote: "I will vote to cap what families pay for insulin.",
                      venue: "Town hall · Sample City", source: "Demo video transcript",
                      topic: .healthCare, linkedVoteIDs: ["V2"]),
            Statement(id: "S2", day: "2025-08-20",
                      quote: "I will oppose any new federal fuel fee.",
                      venue: "Campaign mailer", source: "Demo mailer scan",
                      topic: .energy, linkedVoteIDs: ["V3"]),
            Statement(id: "S3", day: "2026-01-15",
                      quote: "Evening transit service deserves federal support.",
                      venue: "Floor remarks", source: "Demo floor transcript",
                      topic: .transportation, linkedVoteIDs: [])
        ],
        votes: [
            RollCallVote(id: "V1", day: "2025-03-04", bill: "Demo H.R. 101",
                         title: "Sample Appropriations Act", question: "On passage",
                         choice: .yes, result: "Passed", topic: .taxes),
            RollCallVote(id: "V2", day: "2025-06-04", bill: "Demo H.R. 214",
                         title: "Sample Insulin Cost Act", question: "On passage",
                         choice: .yes, result: "Passed", topic: .healthCare),
            RollCallVote(id: "V3", day: "2026-02-10", bill: "Demo H.R. 388",
                         title: "Sample Highway Funding Act (includes a fuel fee)",
                         question: "On passage", choice: .yes, result: "Passed",
                         topic: .energy),
            RollCallVote(id: "V4", day: "2026-03-19", bill: "Demo Bill 14",
                         title: "Sample Transit Measure", question: "Committee vote",
                         choice: .absent, result: "Agreed to", topic: .transportation),
            RollCallVote(id: "V5", day: "2026-03-25", bill: "Demo H.R. 402",
                         title: "Sample Tax Credit Extension", question: "On passage",
                         choice: .no, result: "Failed", topic: .taxes)
        ]
    )

    /// No statements or votes reviewed yet. Every count reads Unavailable.
    static let alder = Official(
        money: MoneyCandidate(id: "D-S1", name: "Quinn Alder", office: "US Senate (fictional)",
                              place: "Federal", committee: "Alder Demo Committee"),
        chamber: .senate,
        seat: "Sample State (fictional)",
        party: "Sample Party (fictional)",
        since: "2021",
        upcoming: "Next election November 7, 2028",
        statements: [],
        votes: []
    )

    static let cedar = Official(
        money: MoneyCandidate(id: "D-P1", name: "Rowan Cedar", office: "President (fictional)",
                              place: "Federal", committee: "Cedar Demo Committee"),
        chamber: .president,
        seat: "United States (fictional)",
        party: "Sample Party (fictional)",
        since: "2025",
        upcoming: "Term ends January 20, 2029",
        statements: [
            Statement(id: "P1", day: "2025-02-01",
                      quote: "I will sign an insulin cost cap if Congress sends me one.",
                      venue: "Address to Congress", source: "Demo transcript",
                      topic: .healthCare, linkedVoteIDs: [])
        ],
        votes: []
    )
}

/// One row on the Timeline tab.
struct ProfileEvent: Identifiable, Hashable {
    let id: String
    let day: String
    let label: String
    let text: String
}

enum ProfileMath {
    /// Absences are missed votes. "Abstained" counts as a vote cast (Present).
    static func votesCast(_ votes: [RollCallVote]) -> Int {
        votes.filter { $0.choice != .absent }.count
    }

    /// Counts always use the full record, never a filtered list.
    static func castText(_ votes: [RollCallVote]) -> String {
        guard !votes.isEmpty else { return "Unavailable" }
        return String(votesCast(votes)) + " of " + String(votes.count)
    }

    static func missedText(_ votes: [RollCallVote]) -> String {
        guard !votes.isEmpty else { return "Unavailable" }
        let missed = votes.count - votesCast(votes)
        let percent = Int((Double(missed) * 100 / Double(votes.count)).rounded())
        return String(missed) + " (" + String(percent) + "%)"
    }

    /// Receipts total only when every receipt amount is disclosed.
    static func raised(_ rows: [MoneyEntry]) -> Int? {
        let receipts = rows.filter { $0.kind == .individual || $0.kind == .committee }
        guard !receipts.isEmpty else { return nil }
        let amounts = receipts.compactMap(\.dollars)
        guard amounts.count == receipts.count else { return nil }
        return amounts.reduce(0, +)
    }

    /// Only reviewer-assigned IDs link a statement to a vote.
    static func linkedVotes(for statement: Statement, in votes: [RollCallVote]) -> [RollCallVote] {
        votes.filter { statement.linkedVoteIDs.contains($0.id) }
    }

    /// Topic and search narrow the list only. Counts never change.
    static func filter(_ votes: [RollCallVote], topic: Topic?, search: String) -> [RollCallVote] {
        let term = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return votes.filter { vote in
            (topic == nil || vote.topic == topic)
                && (term.isEmpty || [vote.bill, vote.title].contains {
                    $0.localizedCaseInsensitiveContains(term)
                })
        }
    }

    /// Plain words for a vote. No verdict.
    static func recordText(_ vote: RollCallVote) -> String {
        switch vote.choice {
        case .yes: "Voted Yes"
        case .no: "Voted No"
        case .absent: "Did not vote"
        case .abstained: "Voted Present"
        }
    }

    /// What they said and how they voted, most recent first.
    /// Money stays on its own track.
    static func timeline(for official: Official) -> [ProfileEvent] {
        let said = official.statements.map { item in
            ProfileEvent(id: item.id, day: item.day, label: "Statement",
                         text: "“" + item.quote + "”")
        }
        let voted = official.votes.map { vote in
            ProfileEvent(id: vote.id, day: vote.day, label: recordText(vote),
                         text: vote.bill + " · " + vote.title)
        }
        return (said + voted).sorted { $0.day > $1.day }
    }

    static func correctionNote(profile: String, record: String) -> String {
        """
        Policy Watch correction
        Profile ID: \(profile)
        Record ID: \(record)
        Disputed field:
        Official source URL:
        Proposed correction:
        """
    }
}

/// Followed profiles, stored as JSON.
struct ProfileFollows: Codable, Equatable {
    private(set) var ids: [String] = []

    init() {}

    func contains(_ id: String) -> Bool {
        ids.contains(id)
    }

    mutating func toggle(_ id: String) {
        if let index = ids.firstIndex(of: id) {
            ids.remove(at: index)
        } else {
            ids.append(id)
        }
    }

    func encoded() -> Data {
        (try? JSONEncoder().encode(self)) ?? Data()
    }

    /// Bad or empty data reads as no follows.
    static func decode(_ data: Data) -> ProfileFollows {
        (try? JSONDecoder().decode(ProfileFollows.self, from: data)) ?? ProfileFollows()
    }
}
