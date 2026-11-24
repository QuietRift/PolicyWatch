import SwiftUI
 
/// Brand colors from the Policy Watch Brand Kit (8-bit channels / 255).
enum Palette {
     static let ink = Color(red: 16 / 255, green: 24 / 255, blue: 32 / 255)
     static let paper = Color(red: 247 / 255, green: 246 / 255, blue: 242 / 255)
     static let gold = Color(red: 200 / 255, green: 155 / 255, blue: 60 / 255)
     static let slate = Color(red: 102 / 255, green: 112 / 255, blue: 133 / 255)
     static let blue = Color(red: 57 / 255, green: 95 / 255, blue: 130 / 255)
     static let amber = Color(red: 198 / 255, green: 135 / 255, blue: 46 / 255)
     static let green = Color(red: 40 / 255, green: 115 / 255, blue: 90 / 255)
     static let red = Color(red: 166 / 255, green: 75 / 255, blue: 75 / 255)
}
 
/// A policy's place in the process. The label is always shown;
/// color only reinforces it.
enum Stage: String, Codable, CaseIterable {
     case introduced = "Introduced"
     case inCommittee = "In committee"
     case pending = "Pending"
     case enacted = "Enacted"
     case failed = "Failed"
     case published = "Published"
 
     var color: Color {
         switch self {
         case .introduced, .published: Palette.slate
         case .inCommittee: Palette.blue
         case .pending: Palette.amber
         case .enacted: Palette.green
         case .failed: Palette.red
         }
     }
 
     /// The brand kit asks for ink text on amber; white elsewhere.
     var textColor: Color {
         self == .pending ? Palette.ink : .white
     }
}
 
/// A status label. Readable without color.
struct StageBadge: View {
    let label: String
    let stage: Stage
    
    var body: some View {
        Text(label)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(stage.textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(stage.color, in: Capsule())
            .accessibilityLabel("Status: " + label)
    }
}
