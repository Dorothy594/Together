//
//  TodayView.swift
//  Together
//
//  Created by Dorothy on 29/10/2026.
//

import SwiftUI

struct TodayView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Today")
                    .font(.largeTitle.bold())

                Text("Your shared goal starts here.")

                Button("Check in with a photo") {
                    // Add photo check-in flow later.
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Together")
        }
    }
}

struct ProgressView: View {
    var body: some View {
        NavigationStack {
            Text("Your shared progress will appear here.")
                .navigationTitle("Progress")
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Text("Your account settings will appear here.")
                .navigationTitle("Settings")
        }
    }
}
