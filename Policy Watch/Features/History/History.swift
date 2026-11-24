import Foundation

enum VoteChoice: String, CaseIterable, Codable {
    case yes = "Yes"
    case no = "No"
    case absent = "Absent"
    case abstained = "Abstained"
}

struct MemberVote: Identifiable, Hashable {
    let member: String
    let choice: VoteChoice
    
    var id: String { member }
}

struct TimelineEvent: Identifiable, Hashable {
    let id: String
    let date: String
    let text: String
}

struct Motion: Hashable {
    let body: String
    let question: String
    let outcome: String
    let votes: [MemberVote]
    
    func count(_ choice: VoteChoice) -> Int {
        votes.filter { $0.choice == choice }.count
    }
    
    var tallyText: String {
        VoteChoice.allCases
            .map { $0.rawValue + " " + String(count($0)) }
            .joined(separator: " · ")
    }
}

struct PolicyHistory {
    let events: [TimelineEvent]
    let motion: Motion?
    
    static func sample(for policy: Policy) -> PolicyHistory? {
        guard policy.id == "demo-bus" else { return nil }
        return PolicyHistory(
            events: [
                TimelineEvent(id: "e2", date: "Nov 4", text: "Mobility committee agreed to hold a public hearing"),
                TimelineEvent(id: "e1", date: "Oct 28", text: "Proposal referred to the mobility committee")
            ],
            motion: Motion(
                body: "Mobility committee",
                question: "Motion to hold a public hearing",
                outcome: "Passed",
                votes: [
                    MemberVote(member: "Member A", choice: .yes),
                    MemberVote(member: "Member B", choice: .no),
                    MemberVote(member: "Member C", choice: .yes)
                ]
            )
        )
    }
}
