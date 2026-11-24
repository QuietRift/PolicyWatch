import SwiftUI
 
/// One assignment per policy. The policy ID is the assignment ID.
struct Assignment: Identifiable, Codable, Hashable {
     let id: String
     var title: String
     var owner: String
     var note: String
     var reviewed: Bool
}
 
/// The workspace rules, separate from the screen so they can be tested.
struct AssignmentBook {
     private(set) var items: [Assignment]
 
     init(items: [Assignment] = []) {
         self.items = items
     }
 
     init(data: Data) {
         items = (try? JSONDecoder().decode([Assignment].self, from: data)) ?? []
     }
 
     var openCount: Int {
         items.filter { !$0.reviewed }.count
     }
 
     /// Saving the same policy again replaces its assignment.
     mutating func assign(_ policy: Policy, owner: String, note: String) {
         let cleanOwner = owner.trimmingCharacters(in: .whitespacesAndNewlines)
         let cleanNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
         items.removeAll { $0.id == policy.id }
         items.append(Assignment(
             id: policy.id,
             title: policy.title,
             owner: cleanOwner,
             note: cleanNote.isEmpty ? "No review question" : cleanNote,
             reviewed: false
         ))
     }
 
     mutating func toggleReviewed(_ id: String) {
         if let index = items.firstIndex(where: { $0.id == id }) {
             items[index].reviewed.toggle()
         }
     }
 
     func encoded() throws -> Data {
         try JSONEncoder().encode(items)
     }
 
     func report(exported: Date) -> String {
         var lines = [
             "Policy Watch review brief · exported "
                 + exported.formatted(date: .abbreviated, time: .shortened),
             "Local workspace on one device. Policy IDs identify each record.",
             ""
         ]
         for item in items {
             let status = item.reviewed ? "Reviewed" : "Open"
             lines.append([item.title, "ID " + item.id, item.owner, status, item.note]
                 .joined(separator: " · "))
         }
         return lines.joined(separator: "\n")
     }
}
 
struct Workspace: View {
     @EnvironmentObject var library: Library
     @AppStorage("policyWatch.assignments.v2") private var data = Data()
     @State private var owner = ""
     @State private var note = ""
     @State private var selection = ""
     @State private var message = ""
 
     private var book: AssignmentBook { AssignmentBook(data: data) }
     private var watched: [Policy] { library.items(on: .watch) }
     private var ownerIsBlank: Bool {
         owner.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
     }
 
     var body: some View {
         List {
             Section("Assign a watched policy") {
                 Picker("Policy", selection: $selection) {
                     Text("Choose a policy").tag("")
                     ForEach(watched) { item in
                         Text(item.title).tag(item.id)
                     }
                 }
                 TextField("Reviewer name", text: $owner)
                     .textContentType(.name)
                 TextField("Review question", text: $note, axis: .vertical)
                 Button("Save assignment") { assign() }
                     .disabled(selection.isEmpty || ownerIsBlank)
                 if watched.isEmpty {
                     Text("Follow a policy first. Bookmarks alone stay in Saved.")
                 }
                 if !message.isEmpty {
                     Text(message)
                 }
             }
             Section("Needs review · " + String(book.openCount)) {
                 if book.items.isEmpty {
                     Text("No assignments yet.")
                 }
                 ForEach(book.items) { assignment in
                     VStack(alignment: .leading, spacing: 6) {
                         Text(assignment.title)
                             .font(.headline)
                         Text(assignment.owner + " · " + assignment.note)
                         if !watched.contains(where: { $0.id == assignment.id }) {
                             Text("No longer followed")
                                 .font(.footnote)
                                 .foregroundStyle(Palette.slate)
                         }
                         Button(assignment.reviewed ? "Reopen" : "Mark reviewed") {
                             var updated = book
                             updated.toggleReviewed(assignment.id)
                             store(updated)
                         }
                         .buttonStyle(.borderless)
                     }
                     .padding(.vertical, 4)
                 }
             }
             if !book.items.isEmpty {
                 Section {
                     ShareLink("Export review brief", item: book.report(exported: .now))
                 } footer: {
                     Text("Stored on this device only. A shared team workspace needs sign-in, "
                         + "organization boundaries and change history.")
                 }
             }
         }
         .navigationTitle("Local workspace")
     }
 
     private func assign() {
         guard let item = watched.first(where: { $0.id == selection }) else {
             message = "Select a policy you currently follow."
             return
         }
         var updated = book
         updated.assign(item, owner: owner, note: note)
         store(updated)
         owner = ""
         note = ""
         selection = ""
     }
 
     private func store(_ updated: AssignmentBook) {
         do {
             data = try updated.encoded()
             message = ""
         } catch {
             message = "Could not save this assignment."
         }
     }
}
