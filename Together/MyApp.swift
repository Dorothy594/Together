
import SwiftUI
import FirebaseCore

@main
struct TogetherApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
