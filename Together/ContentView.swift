import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RootView: View {
    @State private var currentUser: User?
    @State private var authListener: AuthStateDidChangeListenerHandle?

    var body: some View {
        Group {
            if currentUser != nil {
                TabView {
                    TodayView()
                        .tabItem {
                            Label("Today", systemImage: "sun.max.fill")
                        }

                    ProgressScreen()
                        .tabItem {
                            Label("Progress", systemImage: "calendar")
                        }

                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape")
                        }
                }
            } else {
                AuthView()
            }
        }
        .onAppear {
            guard authListener == nil else { return }

            authListener = Auth.auth().addStateDidChangeListener {
                _, user in

                currentUser = user

                guard let user else {
                    UserDefaults.standard.removeObject(
                        forKey: "groupId"
                    )
                    return
                }

                Task {
                    do {
                        let snapshot = try await Firestore.firestore()
                            .collection("users")
                            .document(user.uid)
                            .getDocument()

                        let groupId = snapshot.data()?["groupId"] as? String

                        await MainActor.run {
                            UserDefaults.standard.set(
                                groupId ?? "",
                                forKey: "groupId"
                            )
                        }
                    } catch {
                        print("Could not load user profile: \(error)")
                    }
                }
            }
        }
        .onDisappear {
            if let authListener {
                Auth.auth().removeStateDidChangeListener(authListener)
                self.authListener = nil
            }
        }
    }
}
