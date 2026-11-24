import SwiftUI

struct RecordHistory: View {
    let item: Policy
    @State private var search = ""
    
    private var history: PolicyHistory? {
        PolicyHistory.sample(for: item)
    }
    
    var body: some View {
        List {
            if let history {
                Section("Sample timeline · most recent first") {
                    ForEach(history.events) { event in
                        LabeledContent(event.date, value: event.text)
                    }
                }
                if let motion = history.motion {
                    let shown = filtered(motion.votes)
                    Section(motion.body + " · " + motion.question) {
                        Text("Result: " + motion.outcome)
                            .font(.headline)
                        Text(motion.tallyText)
                            .monospacedDigit()
                        ForEach(shown) { vote in
                            LabeledContent(vote.member, value: vote.choice.rawValue)
                        }
                        if shown.isEmpty {
                            Text("No members match that search.")
                        }
                    }
                    Section {
                        Text("A committee motion is not a vote on the policy itself.")
                            .font(.footnote)
                    }
                }
            } else {
                Section("Timeline") {
                    if let published = item.published {
                        LabeledContent(published, value: "Published in the Federal Register")
                    } else {
                        Text("No dated actions available.")
                    }
                }
                Section("Votes") {
                    Text("Vote counts: Unknow. The source has not supplied individual votes.")
                }
            }
        }
        .searchable(text: $search, prompt: "Find a member")
        .navigationTitle("Timeline and votes")
    }
    
    private func filtered(_ votes: [MemberVote]) -> [MemberVote] {
        let term = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return votes }
        return votes.filter { $0.member.localizedCaseInsensitiveContains(term) }
    }
}


