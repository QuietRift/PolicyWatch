import SwiftUI

/// What a policy would change for people, in plain words.
/// Filled only from the record itself (bill text, CBO estimate, agency notice), never guessed.
/// A policy with no impact shows "Not reviewed yet" instead.
struct Impact: Codable, Hashable {
    enum Taxes: String, Codable, CaseIterable {
        case raises, lowers, mixed, noChange

        var label: String {
            switch self {
            case .raises: "Raises a tax or fee"
            case .lowers: "Lowers a tax or fee"
            case .mixed: "Raises some, lowers others"
            case .noChange: "No tax or fee change"
            }
        }
    }

    let taxes: Taxes
    var taxNote: String? = nil
    let affects: [String]
    var costToYou: String? = nil
    let basis: String

    /// An impact needs at least one affected group and a stated basis.
    var isComplete: Bool {
        !affects.isEmpty
            && !basis.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

/// The "How this affects me" section on Policy detail.
struct ImpactSection: View {
    let impact: Impact?

    private var shown: Impact? {
        guard let impact, impact.isComplete else { return nil }
        return impact
    }

    var body: some View {
        Section {
            if let impact = shown {
                LabeledContent("Taxes", value: impact.taxes.label)
                if let note = impact.taxNote {
                    Text(note)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Who it affects")
                        .font(.subheadline.weight(.semibold))
                    ForEach(impact.affects, id: \.self) { group in
                        Label(group, systemImage: "person.2")
                    }
                }
                .accessibilityElement(children: .combine)
                if let cost = impact.costToYou {
                    Text("Cost to you: " + cost)
                }
            } else {
                Text("Not reviewed yet. Open the source to see who this affects "
                     + "and whether it changes any taxes or fees.")
                    .foregroundStyle(Palette.slate)
            }
        } header: {
            Text("How this affects me")
        } footer: {
            if let impact = shown {
                Text("Based on " + impact.basis
                     + ". A plain-language reading of the record, not a rating.")
            }
        }
    }
}
