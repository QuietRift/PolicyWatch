import Foundation

struct Policy: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let place: String
    let stage: Stage
    let summary: String
    let next: String
    var lastAction: String? = nil
    var documentType: String? = nil
    var agency: String? = nil
    var source: URL? = nil
    var published: String? = nil
    var shortTitle: String? = nil
    var impact: Impact? = nil

    var isSample: Bool { source == nil }

    /// The name shown in lists. The full official title stays on Policy detail.
    var headline: String { shortTitle ?? title }

    var stageLabel: String {
        if let documentType {
            return "Published · " + documentType
        }
        return stage.rawValue
    }

    static let samples: [Policy] = [
        Policy(
            id: "demo-bus",
            title: "Evening bus service review",
            place: "Riverbend · Sample County",
            stage: .inCommittee,
            summary: "The proposal would add later trips on two bus routes. Riders on those "
                + "routes could see service after 10 PM if council adopts the plan.",
            next: "A public hearing is the next step.",
            lastAction: "Nov 4 · Committee scheduled a public hearing",
            shortTitle: "Evening bus service",
            impact: Impact(
                taxes: .noChange,
                affects: ["Riders on the two affected bus routes", "Transit drivers"],
                basis: "the sample proposal summary"
            )
        ),
        Policy(
            id: "demo-library",
            title: "Library hours proposal",
            place: "Riverbend · Sample County",
            stage: .introduced,
            summary: "The proposal would extend Saturday library hours.",
            next: "Next action has not been announced.",
            lastAction: "Oct. 30 · Introduced at council",
            shortTitle: "Library hours",
            impact: Impact(
                taxes: .noChange,
                affects: ["Saturday library visitors", "Library staff"],
                basis: "the sample proposal summary"
            )
        )
    ]
}
