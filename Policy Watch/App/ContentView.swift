import SwiftUI

struct ContentView: View {
    @StateObject private var feed = Feed()
    @StateObject private var library = Library()

    var body: some View {
        TabView {
            NavigationStack {
                HomeScreen()
            }
            .tabItem { Label("Home", systemImage: "house") }
            NavigationStack {
                MoneyDirectory()
            }
            .tabItem { Label("Politicians", systemImage: "building.columns") }
            NavigationStack {
                PolicyShelf(shelf: .explore)
            }
            .tabItem { Label("Explore", systemImage: "magnifyingglass") }
            NavigationStack {
                PolicyShelf(shelf: .saved)
            }
            .tabItem { Label("Saved", systemImage: "bookmark") }
            NavigationStack {
                Preferences()
            }
            .tabItem { Label("Profile", systemImage: "person") }
        }
        .environmentObject(feed)
        .environmentObject(library)
        .tint(Palette.ink)
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
}
