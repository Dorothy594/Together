//
//  AuthView.swift
//  Together
//
//  Created by Dorothy on 29/10/2026.
//


import SwiftUI
import FirebaseAuth

struct AuthView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isRegistering = false
    @State private var isLoading = false

    @State private var errorMessage = ""
    @State private var showError = false
    @State private var infoMessage = ""
    @State private var showInfo = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 76))
                    .foregroundStyle(.blue)

                VStack(spacing: 8) {
                    Text("Together")
                        .font(.largeTitle.bold())

                    Text("Build habits together, one day at a time.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 16) {
                    TextField("Email address", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(
                            Color(.secondarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 12)
                        )

                    SecureField("Password (at least 6 characters)", text: $password)
                        .textContentType(
                            isRegistering ? .newPassword : .password
                        )
                        .padding()
                        .background(
                            Color(.secondarySystemBackground),
                            in: RoundedRectangle(cornerRadius: 12)
                        )

                    Button {
                        Task {
                            await authenticate()
                        }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            }

                            Text(
                                isRegistering ? "Create Account" : "Sign In"
                            )
                            .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isLoading)

                    Button(
                        isRegistering
                            ? "Already have an account? Sign in"
                            : "New to Together? Create an account"
                    ) {
                        isRegistering.toggle()
                        password = ""
                    }

                    if !isRegistering {
                        Button("Forgot password?") {
                            Task {
                                await resetPassword()
                            }
                        }
                        .font(.subheadline)
                    }
                }

                Spacer()
                Spacer()
            }
            .padding(24)
            .navigationBarHidden(true)
            .alert("Authentication Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Together", isPresented: $showInfo) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(infoMessage)
            }
        }
    }

    @MainActor
    private func authenticate() async {
        let cleanEmail = email.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter your email and password."
            showError = true
            return
        }

        if isRegistering && password.count < 6 {
            errorMessage = "Your password must contain at least 6 characters."
            showError = true
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            if isRegistering {
                let result = try await Auth.auth().createUser(
                    withEmail: cleanEmail,
                    password: password
                )

                // Create a profile document for the new user.
                try await FirestoreProfile.create(
                    userId: result.user.uid,
                    email: cleanEmail
                )
            } else {
                _ = try await Auth.auth().signIn(
                    withEmail: cleanEmail,
                    password: password
                )
            }
        } catch {
            let nsError = error as NSError

            print("========== FIREBASE AUTH ERROR ==========")
            print("Domain: \(nsError.domain)")
            print("Code: \(nsError.code)")
            print("Description: \(nsError.localizedDescription)")
            print("UserInfo: \(nsError.userInfo)")
            print("==========================================")

            errorMessage = """
            Domain: \(nsError.domain)
            Code: \(nsError.code)

            \(nsError.localizedDescription)
            """

            showError = true
        }
    }

    @MainActor
    private func resetPassword() async {
        let cleanEmail = email.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanEmail.isEmpty else {
            errorMessage = "Enter your email address first."
            showError = true
            return
        }

        do {
            try await Auth.auth().sendPasswordReset(
                withEmail: cleanEmail
            )
            infoMessage = "If this email is registered, a password reset email will be sent."
            showInfo = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
