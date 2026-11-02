import SwiftUI

@main
struct TalkBoardApp: App {
    @StateObject private var store = BoardStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .persistentSystemOverlays(.hidden)   // hides the home indicator bar
        }
    }
}
