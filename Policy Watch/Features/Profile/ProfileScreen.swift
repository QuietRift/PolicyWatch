import SwiftUI

enum ProfileTab: String, CaseIterable, Identifiable {
    case record = "Record"
    case votes = "Votes"
    case money = "Money"
    case timeline = "Timeline"

    var id: Self { self }
}

/// The same template for every official. Compiled from records, never run by the official.
struct ProfileScreen: View {
    let official: Official
    @State private var tab = ProfileTab.record
    @State private var topic: Topic?
    @State private var search = ""
    @AppStorage("profile.follows.v1") private var followData = Data()

    private var follows: ProfileFollows { ProfileFollows.decode(followData) }
    private var isFollowing: Bool { follows.contains(official.id) }
    private var rows: [MoneyEntry] { official.money.entries(cycle: 2026) }
    private var shownVotes: [RollCallVote] {
        ProfileMath.filter(official.votes, topic: topic, search: search)
    }

    var body: some View {
        List {
            header
            Section("At a glance · full record") {
                LabeledContent("Votes cast", value: official.chamber.castsRollCallVotes
                               ? ProfileMath.castText(official.votes) : "Not applicable")
                LabeledContent("Missed votes", value: official.chamber.castsRollCallVotes
                               ? ProfileMath.missedText(official.votes) : "Not applicable")
                LabeledContent("Receipts this period", value: ProfileMath.raised(rows)?
                    .formatted(.currency(code: "USD")) ?? "Unavailable")
                LabeledContent("Statements reviewed", value: String(official.statements.count))
            }
            .monospacedDigit()
            Section {
                Picker("Profile section", selection: $tab) {
                    ForEach(ProfileTab.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
            }
            switch tab {
            case .record: recordTab
            case .votes: votesTab
            case .money: moneyTab
            case .timeline: timelineTab
            }
            Section {
                NavigationLink("How profiles are built") { ProfileMethod() }
                ShareLink("Report an error on this profile",
                          item: ProfileMath.correctionNote(profile: official.id,
                                                           record: "Whole profile"))
            }
        }
        .navigationTitle(official.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        Section {
            HStack(alignment: .top, spacing: 16) {
                Text(official.initials)
                    .font(.title2.bold())
                    .foregroundStyle(Palette.paper)
                    .frame(width: 64, height: 64)
                    .background(Palette.ink, in: Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(official.name)
                        .font(.title2.bold())
                        .accessibilityAddTraits(.isHeader)
                    Text(official.officeLine)
                        .font(.subheadline)
                    Text(official.party + " · in office since " + official.since)
                        .font(.subheadline)
                        .foregroundStyle(Palette.slate)
                    Text(official.upcoming)
                        .font(.subheadline)
                        .foregroundStyle(Palette.slate)
                }
            }
            Text("Compiled by Policy Watch from public records. Not run by, or affiliated "
                 + "with, this official.")
                .font(.footnote)
            Text("Fictional demo profile. No real person is represented.")
                .font(.footnote.bold())
            Button(isFollowing ? "Following" : "Follow",
                   systemImage: isFollowing ? "checkmark" : "plus") {
                toggleFollow()
            }
            .buttonStyle(.borderedProminent)
            .tint(Palette.ink)
            .accessibilityValue(isFollowing ? "On" : "Off")
        }
    }

    @ViewBuilder private var recordTab: some View {
        Section("Said · and the linked record") {
            if official.statements.isEmpty {
                Text("No statements reviewed yet.")
            }
            ForEach(official.statements) { statement in
                NavigationLink {
                    StatementDetail(statement: statement, official: official)
                } label: {
                    StatementCard(
                        statement: statement,
                        linked: ProfileMath.linkedVotes(for: statement, in: official.votes)
                    )
                }
            }
        }
        Section {
            Text("Policy Watch shows statements beside the record. It does not rate them.")
                .font(.footnote)
        }
    }

    @ViewBuilder private var votesTab: some View {
        if official.chamber.castsRollCallVotes {
            Section("Roll-call votes") {
                Picker("Topic", selection: $topic) {
                    Text("All topics").tag(Topic?.none)
                    ForEach(Topic.allCases) { item in
                        Text(item.rawValue).tag(Optional(item))
                    }
                }
                TextField("Search bill number or title", text: $search)
                ForEach(shownVotes) { vote in
                    NavigationLink {
                        VoteDetail(vote: vote, official: official)
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(vote.bill + " · " + vote.title)
                                Text(vote.day + " · " + vote.question)
                                    .font(.footnote)
                            }
                            Spacer()
                            ChoiceBadge(choice: vote.choice)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                if shownVotes.isEmpty {
                    Text(official.votes.isEmpty
                         ? "No votes loaded for this demo profile."
                         : "No votes match this filter.")
                }
            }
        } else {
            Section("Votes") {
                Text("Presidents don't cast roll-call votes. Bill signings and vetoes need "
                     + "their own source and come in a later phase.")
            }
        }
    }

    @ViewBuilder private var moneyTab: some View {
        Section("Money · reporting-period summary") {
            ForEach([MoneyKind.individual, .committee, .spending]) { kind in
                LabeledContent(kind.rawValue, value: MoneyMath.total(of: kind, in: rows)?
                    .formatted(.currency(code: "USD")) ?? "Unavailable")
                    .monospacedDigit()
            }
            Text(rows.isEmpty
                 ? "Coverage unavailable for this profile."
                 : MoneyCandidate.fixturePeriod)
                .font(.footnote)
            NavigationLink("Open Follow the Money") {
                MoneyScreen(person: official.money)
            }
        }
        Section {
            Text("Money and votes appear on separate tracks. A nearby date or a shared "
                 + "topic does not show influence.")
                .font(.footnote)
        }
    }

    @ViewBuilder private var timelineTab: some View {
        let events = ProfileMath.timeline(for: official)
        Section("Statements and votes · most recent first") {
            if events.isEmpty {
                Text("No dated statements or votes.")
            }
            ForEach(events) { event in
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.day + " · " + event.label)
                        .font(.footnote.weight(.semibold))
                    Text(event.text)
                }
                .accessibilityElement(children: .combine)
            }
        }
        Section("Financial disclosures · separate track") {
            if rows.isEmpty {
                Text("No disclosure coverage.")
            }
            ForEach(rows.sorted { $0.day > $1.day }) { row in
                NavigationLink(row.day + " · " + row.kind.rawValue + " · " + row.amount) {
                    MoneyDetail(row: row, person: official.money)
                }
            }
        }
    }

    private func toggleFollow() {
        var updated = follows
        updated.toggle(official.id)
        followData = updated.encoded()
    }
}

#Preview {
    NavigationStack {
        ProfileScreen(official: Official.vale)
    }
}
