import SwiftUI

/// A vote label that reads without color. Blue and amber, never red and green.
struct ChoiceBadge: View {
    let choice: VoteChoice

    private var color: Color {
        switch choice {
        case .yes: Palette.blue
        case .no: Palette.amber
        case .absent, .abstained: Palette.slate
        }
    }

    var body: some View {
        Text(choice.rawValue)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(choice == .no ? Palette.ink : .white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color, in: Capsule())
            .accessibilityLabel("Vote: " + choice.rawValue)
    }
}

/// "Said" beside "Record". The reader draws the conclusion.
struct StatementCard: View {
    let statement: Statement
    let linked: [RollCallVote]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(statement.topic.rawValue.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.slate)
            Text("Said: “" + statement.quote + "”")
            Text(statement.day + " · " + statement.venue)
                .font(.footnote)
            if linked.isEmpty {
                Text("Record: no linked vote yet")
                    .font(.footnote.bold())
            }
            ForEach(linked) { vote in
                Text("Record: " + ProfileMath.recordText(vote) + " · " + vote.bill
                     + " · " + vote.day)
                    .font(.footnote.bold())
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

struct StatementDetail: View {
    let statement: Statement
    let official: Official

    var body: some View {
        List {
            Section("Statement · word for word") {
                Text("“" + statement.quote + "”")
                LabeledContent("Date", value: statement.day)
                LabeledContent("Where", value: statement.venue)
                LabeledContent("Source", value: statement.source)
                LabeledContent("Topic", value: statement.topic.rawValue)
            }
            Section("Linked votes · reviewer-assigned") {
                let linked = ProfileMath.linkedVotes(for: statement, in: official.votes)
                if linked.isEmpty {
                    Text("No vote has been linked to this statement.")
                }
                ForEach(linked) { vote in
                    NavigationLink {
                        VoteDetail(vote: vote, official: official)
                    } label: {
                        HStack {
                            Text(vote.bill + " · " + vote.day)
                            Spacer()
                            ChoiceBadge(choice: vote.choice)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            Section {
                Text("Fictional fixture. No real statement or source exists for this record.")
                    .font(.footnote.bold())
                ShareLink("Report an error",
                          item: ProfileMath.correctionNote(profile: official.id,
                                                           record: statement.id))
            }
        }
        .navigationTitle("Statement")
    }
}

struct VoteDetail: View {
    let vote: RollCallVote
    let official: Official

    private var statements: [Statement] {
        official.statements.filter { $0.linkedVoteIDs.contains(vote.id) }
    }

    var body: some View {
        List {
            Section("Roll-call vote · demo data") {
                LabeledContent("Bill", value: vote.bill)
                LabeledContent("Title", value: vote.title)
                LabeledContent("Question", value: vote.question)
                LabeledContent("Date", value: vote.day)
                LabeledContent("Result", value: vote.result)
                LabeledContent("Topic", value: vote.topic.rawValue)
                HStack {
                    Text(official.name)
                    Spacer()
                    ChoiceBadge(choice: vote.choice)
                }
                .accessibilityElement(children: .combine)
                Text("A vote on a motion or amendment is not always a vote on the bill "
                     + "itself. Check the question.")
                    .font(.footnote)
            }
            Section("Statements linked to this vote") {
                if statements.isEmpty {
                    Text("No statements linked.")
                }
                ForEach(statements) { statement in
                    NavigationLink("“" + statement.quote + "”") {
                        StatementDetail(statement: statement, official: official)
                    }
                }
            }
            Section {
                Text("Fictional fixture. No real roll call exists for this record.")
                    .font(.footnote.bold())
                ShareLink("Report an error",
                          item: ProfileMath.correctionNote(profile: official.id,
                                                           record: vote.id))
            }
        }
        .navigationTitle("Vote")
    }
}

struct ProfileMethod: View {
    // Verify these links against the official sites before release.
    private static let congress = URL(string: "https://www.congress.gov/")!
    private static let house = URL(string: "https://clerk.house.gov/Votes")!
    private static let senate =
        URL(string: "https://www.senate.gov/legislative/votes_new.htm")!

    var body: some View {
        List {
            Section("How a profile is built") {
                Text("Every profile uses the same template and the same order. Policy Watch "
                     + "compiles it from public records. The official does not run it.")
                Text("Statements are quoted word for word with a date and a source. Votes "
                     + "come from the roll call. Neither is rated.")
                Text("A statement links to a vote only when a reviewer assigns the link. A "
                     + "shared topic or a nearby date never creates one.")
                Text("Counts use the full record. Topic and search filters narrow the list "
                     + "only.")
                Text("Money and votes sit on separate tracks. Timing alone cannot establish "
                     + "influence.")
            }
            Section("Official sources") {
                Link("Congress.gov · bills and actions", destination: Self.congress)
                Link("Clerk of the House · roll-call votes", destination: Self.house)
                Link("U.S. Senate · roll-call votes", destination: Self.senate)
            }
        }
        .navigationTitle("How profiles are built")
    }
}
