import Foundation
 
enum Cadence: String, CaseIterable, Identifiable {
     case off = "Off"
     case daily = "Daily"
     case weekly = "Weekly"
 
     var id: String { rawValue }
}
 
/// Scheduling rules, kept out of the view so they can be tested.
struct ReminderPlan {
     static let identifier = "policyWatch.briefing"
     static let jurisdictions = ["All jurisdictions", "Federal", "Detroit"]
     static let focuses = ["Policy activity", "Votes", "Effective dates"]
 
     let place: String
     let focus: String
     let cadence: Cadence
 
     /// nil means no reminder. Weekday 2 is Monday in the Gregorian calendar.
     var dateComponents: DateComponents? {
         switch cadence {
         case .off:
             return nil
         case .daily:
             return DateComponents(hour: 9, minute: 0)
         case .weekly:
             return DateComponents(hour: 9, minute: 0, weekday: 2)
         }
     }
 
     /// An invitation to review. It never claims that something happened.
     var message: String {
         "Time to review " + focus.lowercased() + " · " + place
             + ". Open Policy Watch for the latest verified records."
     }
 
     var confirmation: String {
         switch cadence {
         case .off: "Reminder turned off."
         case .daily: "Reminder scheduled for 9 AM daily."
         case .weekly: "Reminder scheduled for Mondays at 9 AM."
         }
     }
}
