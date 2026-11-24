import SwiftUI
import UserNotifications
 
struct Preferences: View {
     @AppStorage("reminder.place") private var place = "All jurisdictions"
     @AppStorage("reminder.focus") private var focus = "Policy activity"
     @AppStorage("reminder.cadence") private var cadence = Cadence.off
     @State private var feedback = ""
     @State private var saving = false
     @State private var denied = false
 
     var body: some View {
         Form {
             Section {
                 NavigationLink("Open local workspace") {
                     Workspace()
                 }
             } footer: {
                 Text("For organizations: assign watched policies to reviewers and export a "
                     + "review brief.")
             }
#if DEBUG
           Section {
               NavigationLink("City directory (test)") {
                   CityDirectoryScreen()
               }
           } header: {
               Text("Developer")
           } footer: {
               Text("Debug builds only. Michigan local governments from the .gov registry.")
           }
           #endif

             
             Section {
                 Picker("Jurisdiction", selection: $place) {
                     ForEach(ReminderPlan.jurisdictions, id: \.self) { Text($0) }
                 }
                 Picker("Review focus", selection: $focus) {
                     ForEach(ReminderPlan.focuses, id: \.self) { Text($0) }
                 }
                 Picker("Frequency", selection: $cadence) {
                     ForEach(Cadence.allCases) { option in
                         Text(option.rawValue).tag(option)
                     }
                 }
                 Button(saving ? "Applying…" : "Apply reminder") {
                     Task { await apply() }
                 }
                 .disabled(saving)
             } header: {
                 Text("Briefing reminder")
             } footer: {
                 Text("Daily at 9 AM, or Mondays at 9 AM, local time. A reminder invites you to "
                     + "review. It does not report that anything happened.")
             }
             if !feedback.isEmpty {
                 Section {
                     Text(feedback)
                     if denied {
                         Button("Open Settings") { openSettings() }
                     }
                 }
             }
         }
         .navigationTitle("Profile")
     }
 
     private func apply() async {
         saving = true
         defer { saving = false }
         let center = UNUserNotificationCenter.current()
         let plan = ReminderPlan(place: place, focus: focus, cadence: cadence)
         center.removePendingNotificationRequests(withIdentifiers: [ReminderPlan.identifier])
         guard let components = plan.dateComponents else {
             denied = false
             feedback = plan.confirmation
             return
         }
         do {
             let granted = try await center.requestAuthorization(options: [.alert, .sound])
             guard granted else {
                 denied = true
                 feedback = "Notifications are off for Policy Watch. Allow them in Settings to "
                     + "use reminders."
                 return
             }
             denied = false
             let content = UNMutableNotificationContent()
             content.title = "Your Policy Watch reminder"
             content.body = plan.message
             let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
             let request = UNNotificationRequest(
                 identifier: ReminderPlan.identifier,
                 content: content,
                 trigger: trigger
             )
             try await center.add(request)
             feedback = plan.confirmation
         } catch {
             feedback = "Could not apply the reminder. Try again."
         }
     }
 
     private func openSettings() {
         if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
             UIApplication.shared.open(url)
         }
     }
}
