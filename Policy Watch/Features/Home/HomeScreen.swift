import SwiftUI

struct HomeScreen: View {
    @EnvironmentObject var feed: Feed
    @EnvironmentObject var library: Library

    private var followed: [Policy] { library.items(on: .watch) }

    private var watchlist: [Policy] {
        Watchlist.preview(followed: followed, current: feed.items + Policy.samples)
    }

    var body: some View {
        List {
            Section {
                            if watchlist.isEmpty {
                                Text("Follow a policy to see its next action here.")
                                    .foregroundStyle(Palette.slate)
                            }
                            ForEach(watchlist) { item in
                                NavigationLink {
                                    PolicyDetail(item: item)
                                } label: {
                                    PolicyRow(item: item)
                                }
                            }
                        } header: {
                            HStack {
                                Text("Your watchlist")
                                Spacer()
                                if Watchlist.showsSeeAll(followed.count) {
                                    NavigationLink("See all " + String(followed.count)) {
                                        PolicyShelf(shelf: .watch)
                                    }
                                    .font(.subheadline.weight(.semibold))
                                    .textCase(nil)
                                    .accessibilityHint("Opens your full watchlist")
                                }
                            }
                        }

            Section {
                ForEach(BillLevel.allCases) { level in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(level.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .accessibilityAddTraits(.isHeader)
                        ScrollView(.horizontal) {
                            HStack(alignment: .top, spacing: 12) {
                                ForEach(Trending.ranked(level)) { bill in
                                    NavigationLink(value: bill) {
                                        TrendingCard(bill: bill)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .scrollIndicators(.hidden)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Most searched bills")
            } footer: {
                Text("Demo ranking with fictional bills. Not real search data.")
            }
            Section {
                if let checked = feed.checked {
                    Text("Last checked " + checked.formatted(date: .abbreviated, time: .shortened)
                         + ". A newer action may be available.")
                        .font(.footnote)
                        .foregroundStyle(Palette.slate)
                }
                if let problem = feed.problem {
                    Text(problem)
                }
                Button(refreshLabel) {
                    Task { await feed.refresh() }
                }
                .disabled(feed.loading)
                if feed.items.isEmpty && !feed.loading {
                    Text("No federal publications loaded yet.")
                }
                ForEach(feed.items) { item in
                    NavigationLink {
                        PolicyDetail(item: item)
                    } label: {
                        PolicyRow(item: item)
                    }
                }
            } header: {
                Text("Federal Register · recent publications")
            } footer: {
                Text("Source: Federal Register API. The check time is shown separately from "
                     + "each publication date.")
            }
            Section("Sample records · fictional city") {
                ForEach(Policy.samples) { item in
                    NavigationLink {
                        PolicyDetail(item: item)
                    } label: {
                        PolicyRow(item: item)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.paper)
        .navigationTitle("Your briefing")
        .navigationDestination(for: TrendingBill.self) { bill in
            PolicyDetail(item: bill.policy)
        }
        .refreshable { await feed.refresh() }
        .task {
            if feed.checked == nil { await feed.refresh() }
        }
    }

    private var refreshLabel: String {
        if feed.loading { return "Checking…" }
        return feed.problem == nil ? "Refresh records" : "Try again"
    }
}

/// One card in a "Most searched" row.
struct TrendingCard: View {
    let bill: TrendingBill

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(bill.policy.headline)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
            StageBadge(label: bill.policy.stage.rawValue, stage: bill.policy.stage)
            Text(bill.searches.formatted() + " searches · demo")
                .font(.caption)
                .foregroundStyle(Palette.slate)
        }
        .padding(12)
        .frame(width: 200, alignment: .leading)
        .frame(minHeight: 140, alignment: .topLeading)
        .background(Palette.paper, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the bill")
    }
}

/// One record in a list: place, title and status.
struct PolicyRow: View {
    let item: Policy

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.isSample ? "Sample · " + item.place : item.place)
                .font(.footnote)
                .foregroundStyle(Palette.slate)
            Text(item.headline)
                .font(.headline)
                .lineLimit(2)
            StageBadge(label: item.stageLabel, stage: item.stage)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
