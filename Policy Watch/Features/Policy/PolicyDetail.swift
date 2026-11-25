import SwiftUI
 
struct PolicyDetail: View {
     @EnvironmentObject var library: Library
     let item: Policy
 
     var body: some View {
         List {
             Section {
                 Text(item.headline)
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)
                if item.headline != item.title {
                    Text("Official title: " + item.title)
                        .font(.footnote)
                        .foregroundStyle(Palette.slate)
                    }

                 StageBadge(label: item.stageLabel, stage: item.stage)
             } header: {
                 Text(item.place)
             }
             ImpactSection(impact: item.impact)
             
             if let lastAction = item.lastAction {
                 Section("Last action") {
                     Text(lastAction)
                 }
             }
             Section("What happens next") {
                 Text(item.next)
             }
             Section {
                 NavigationLink("Timeline and votes") {
                     RecordHistory(item: item)
                 }
             }
             Section("My library") {
                 Button {
                     library.toggle(item, on: .watch)
                 } label: {
                     if library.contains(item, on: .watch) {
                         Label("Following · Unfollow", systemImage: "eye.fill")
                     } else {
                         Label("Follow policy", systemImage: "eye")
                     }
                 }
                 Button {
                     library.toggle(item, on: .saved)
                 } label: {
                     if library.contains(item, on: .saved) {
                         Label("Saved · Remove bookmark", systemImage: "bookmark.fill")
                     } else {
                         Label("Save policy", systemImage: "bookmark")
                     }
                 }
             }
             Section("Source") {
                 if let source = item.source {
                     if let agency = item.agency {
                         LabeledContent("Issuing agency", value: agency)
                     }
                     LabeledContent("Published", value: item.published ?? "Undated")
                     Link("Read the published document", destination: source)
                     Text("Federal Register. The summary above is the publisher's abstract.")
                         .font(.footnote)
                 } else {
                     Text("Sample record · fictional city. No government record exists for it.")
                         .font(.footnote)
                 }
             }
         }
         .navigationTitle("Policy detail")
         .navigationBarTitleDisplayMode(.inline)
     }
}
 
#Preview {
     NavigationStack {
         PolicyDetail(item: Policy.samples[0])
     }
     .environmentObject(Library())
}
