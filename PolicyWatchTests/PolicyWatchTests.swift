import Foundation
import Testing
@testable import Policy_Watch

/// A fake network for Feed tests. Sample bytes only; not a real record.
struct FakeSource: FeedSource {
    var data = Data()
    var status = 200
    var fails = false

    func load(_ url: URL) async throws -> (Data, URLResponse) {
        if fails { throw URLError(.notConnectedToInternet) }
        let response = HTTPURLResponse(
            url: url, statusCode: status, httpVersion: nil, headerFields: nil
        )!
        return (data, response)
    }
}

let samplePage = Data("""
{"results":[{"document_number":"TEST-0001","title":"Test rule","type":"Rule",
"publication_date":"2026-11-04","html_url":"https://www.federalregister.gov/d/TEST-0001",
"pdf_url":null,"abstract":null,"agencies":[{"name":"Test Agency"}]}]}
""".utf8)

/// A throwaway UserDefaults so tests never touch real app data.
func scratchDefaults() -> UserDefaults {
    UserDefaults(suiteName: "PolicyWatchTests-" + UUID().uuidString)!
}

@MainActor
struct PolicyWatchTests {
    // MARK: Phase 4 · Votes

    @Test func tallyCountsTheFullRollCall() throws {
        let motion = try #require(PolicyHistory.sample(for: Policy.samples[0])?.motion)
        #expect(motion.count(.yes) == 2)
        #expect(motion.count(.no) == 1)
        #expect(motion.tallyText == "Yes 2 · No 1 · Absent 0 · Abstained 0")
    }

    @Test func recordsWithoutHistoryHaveNoVotes() {
        #expect(PolicyHistory.sample(for: Policy.samples[1]) == nil)
    }

    // MARK: Phase 5 · Feed

    @Test func refreshDecodesAndCaches() async {
        let defaults = scratchDefaults()
        let feed = Feed(source: FakeSource(data: samplePage), defaults: defaults)
        await feed.refresh()
        #expect(feed.items.map(\.id) == ["fr-TEST-0001"])
        #expect(feed.items.first?.agency == "Test Agency")
        #expect(feed.problem == nil)

        let relaunched = Feed(source: FakeSource(fails: true), defaults: defaults)
        #expect(relaunched.items.count == 1)
    }

    @Test func failedRefreshKeepsLastVerifiedRecords() async {
        let defaults = scratchDefaults()
        let first = Feed(source: FakeSource(data: samplePage), defaults: defaults)
        await first.refresh()
        let offline = Feed(source: FakeSource(fails: true), defaults: defaults)
        await offline.refresh()
        #expect(offline.items.count == 1)
        #expect(offline.checked != nil)
        #expect(offline.problem != nil)
    }

    @Test func serverErrorIsAFailure() async {
        let source = FakeSource(data: samplePage, status: 500)
        let feed = Feed(source: source, defaults: scratchDefaults())
        await feed.refresh()
        #expect(feed.items.isEmpty)
        #expect(feed.problem != nil)
    }

    // MARK: Phase 6 · Library

    @Test func followAndSaveAreIndependent() {
        let library = Library(defaults: scratchDefaults())
        let bus = Policy.samples[0]
        library.toggle(bus, on: .watch)
        library.toggle(bus, on: .saved)
        library.toggle(bus, on: .watch)
        #expect(!library.contains(bus, on: .watch))
        #expect(library.contains(bus, on: .saved))
    }

    @Test func libraryPersists() {
        let defaults = scratchDefaults()
        Library(defaults: defaults).toggle(Policy.samples[1], on: .saved)
        #expect(Library(defaults: defaults).contains(Policy.samples[1], on: .saved))
    }

    // MARK: Phase 7 · Reminders

    @Test func weeklyIsMondayAtNine() {
        let plan = ReminderPlan(place: "Federal", focus: "Votes", cadence: .weekly)
        #expect(plan.dateComponents == DateComponents(hour: 9, minute: 0, weekday: 2))
    }

    @Test func offSchedulesNothing() {
        let plan = ReminderPlan(place: "Federal", focus: "Votes", cadence: .off)
        #expect(plan.dateComponents == nil)
    }

    @Test func messageInvitesReviewOnly() {
        let plan = ReminderPlan(place: "Detroit", focus: "Votes", cadence: .daily)
        #expect(plan.message.hasPrefix("Time to review votes · Detroit"))
    }

    // MARK: Phase 8 · Workspace

    @Test func reassigningReplacesTheAssignment() {
        var book = AssignmentBook()
        book.assign(Policy.samples[0], owner: " Jordan ", note: "Check routes")
        book.assign(Policy.samples[0], owner: "Sam", note: "")
        #expect(book.items.count == 1)
        #expect(book.items[0].owner == "Sam")
        #expect(book.items[0].note == "No review question")
    }

    @Test func openCountFollowsReviewState() {
        var book = AssignmentBook()
        book.assign(Policy.samples[0], owner: "Jordan", note: "Q")
        book.toggleReviewed(Policy.samples[0].id)
        #expect(book.openCount == 0)
        book.toggleReviewed(Policy.samples[0].id)
        #expect(book.openCount == 1)
    }

    @Test func reportIncludesEveryField() {
        var book = AssignmentBook()
        book.assign(Policy.samples[0], owner: "Jordan", note: "Check routes")
        let report = book.report(exported: .now)
        let expected = "Evening bus service review · ID demo-bus · Jordan · Open · Check routes"
        #expect(report.contains(expected))
    }

    // MARK: Phase 9 · Follow the Money

    @Test func totalsUseTheFullPeriod() {
        let rows = MoneyCandidate.directory[0].entries(cycle: 2026)
        #expect(MoneyMath.total(of: .individual, in: rows) == 125)
        #expect(MoneyMath.total(of: .committee, in: rows) == 500)
        #expect(MoneyMath.total(of: .spending, in: rows) == 90)
    }

    @Test func undisclosedAmountsNeverBecomeZero() {
        let rows = MoneyCandidate.directory[0].entries(cycle: 2026)
        #expect(MoneyMath.total(of: .lobbying, in: rows) == nil)
        #expect(MoneyMath.total(of: .individual, in: []) == nil)
    }

    @Test func filterNarrowsOnlyTheList() {
        let rows = MoneyCandidate.directory[0].entries(cycle: 2026)
        let shown = MoneyMath.filter(rows, kind: .outside, window: .secondHalf)
        #expect(shown.map(\.id) == ["T4"])
    }

    @Test func onlyOfficialFilingLinksOpen() {
        let good = FederalReceipt(
            id: "1", payer: "P", day: "2024-01-01", filing: "1", amount: 5,
            link: "https://docquery.fec.gov/sample.pdf"
        )
        let bad = FederalReceipt(
            id: "2", payer: "P", day: "2024-01-01", filing: "1", amount: 5,
            link: "https://example.com/sample.pdf"
        )
        #expect(good.officialLink != nil)
        #expect(bad.officialLink == nil)
    }

    // MARK: Phase 10 · Politician profile

    @Test func countsUseTheFullRecord() {
        let votes = Official.vale.votes
        #expect(ProfileMath.castText(votes) == "4 of 5")
        #expect(ProfileMath.missedText(votes) == "1 (20%)")
        let shown = ProfileMath.filter(votes, topic: .healthCare, search: "")
        #expect(shown.map(\.id) == ["V2"])
        #expect(ProfileMath.castText(votes) == "4 of 5")
    }

    @Test func emptyRecordsReadUnavailable() {
        #expect(ProfileMath.castText([]) == "Unavailable")
        #expect(ProfileMath.missedText([]) == "Unavailable")
        #expect(ProfileMath.raised(Official.alder.money.entries(cycle: 2026)) == nil)
    }

    @Test func receiptsTotalOnlyWhenDisclosed() {
        #expect(ProfileMath.raised(Official.vale.money.entries(cycle: 2026)) == 625)
        let hidden = MoneyEntry(id: "X", kind: .individual, day: "2026-03-03", payer: "P",
                                recipient: "R", dollars: nil, filing: "F", amended: false)
        #expect(ProfileMath.raised([hidden]) == nil)
    }

    @Test func statementsLinkOnlyByReviewerID() {
        let said = Official.vale.statements
        #expect(ProfileMath.linkedVotes(for: said[0], in: Official.vale.votes).map(\.id) == ["V2"])
        // S3 shares a topic with V4 but has no assigned link.
        #expect(ProfileMath.linkedVotes(for: said[2], in: Official.vale.votes).isEmpty)
    }

    @Test func timelineIsMostRecentFirst() {
        let days = ProfileMath.timeline(for: Official.vale).map(\.day)
        #expect(days.count == 8)
        #expect(days == days.sorted(by: >))
    }

    @Test func followsPersistAsJSON() {
        var follows = ProfileFollows()
        follows.toggle("D-F1")
        #expect(ProfileFollows.decode(follows.encoded()).contains("D-F1"))
        follows.toggle("D-F1")
        #expect(!follows.contains("D-F1"))
        #expect(ProfileFollows.decode(Data("bad".utf8)) == ProfileFollows())
    }

    @Test func profilesCoverOnlyFederalOffices() {
        #expect(Official.directory.map(\.chamber) == [.house, .senate, .president])
        #expect(Official.directory.allSatisfy { $0.money.place == "Federal" })
        #expect(!Official.cedar.chamber.castsRollCallVotes)
    }

    @Test func correctionNoteNamesTheRecord() {
        let note = ProfileMath.correctionNote(profile: "D-F1", record: "S1")
        #expect(note.contains("Profile ID: D-F1"))
        #expect(note.contains("Record ID: S1"))
    }

    // MARK: Phase 11 · Home watchlist and Politicians tab

    @Test func eachLevelIsMostSearchedFirst() {
        for level in BillLevel.allCases {
            let counts = Trending.ranked(level).map(\.searches)
            #expect(counts.count == 3)
            #expect(counts == counts.sorted(by: >))
        }
    }

    @Test func trendingBillsHaveUniqueIDs() {
        let ids = Trending.demo.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func localRowOpensTheSampleRecords() {
        let ids = Trending.ranked(.local).map(\.id)
        #expect(ids.contains("demo-bus"))
        #expect(ids.contains("demo-library"))
    }

    @Test func watchlistPreviewUsesNewestCopyAndLimit() {
        let old = Policy(id: "w1", title: "Old title", place: "P", stage: .introduced,
                         summary: "S", next: "N")
        let newer = Policy(id: "w1", title: "New title", place: "P", stage: .pending,
                           summary: "S", next: "N")
        let followed = [old] + Policy.samples + [Trending.demo[0].policy]
        let preview = Watchlist.preview(followed: followed, current: [newer])
        #expect(preview.count == 3)
        #expect(preview.first?.title == "New title")
        #expect(Watchlist.preview(followed: [], current: [newer]).isEmpty)
    }
}
