//
//  CheckInView.swift
//  Together
//
//  Created by Dorothy on 29/10/2026.
//


import SwiftUI
import PhotosUI

struct CheckInView: View {
    let groupId: String

    @State private var selectedItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var note = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var didSubmit = false

    private var today: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .autoupdatingCurrent
        return formatter.string(from: Date())
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Text("Today's moment")
                    .font(.largeTitle.bold())

                Text("A small step, taken together.")
                    .foregroundStyle(.secondary)

                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images
                ) {
                    Group {
                        if let photoData,
                           let image = UIImage(data: photoData) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "camera")
                                    .font(.largeTitle)
                                Text("Choose a photo")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 280)
                            .background(Color(.secondarySystemBackground))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }

                TextField("Add a note (optional)", text: $note)
                    .textFieldStyle(.roundedBorder)

                Button {
                    Task { await submit() }
                } label: {
                    HStack {
                        if isSubmitting {
                            ProgressView().tint(.white)
                        }
                        Text(isSubmitting ? "Uploading..." : "Complete today's check-in")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primary)
                    .foregroundStyle(Color(.systemBackground))
                    .clipShape(Capsule())
                }
                .disabled(photoData == nil || isSubmitting || didSubmit)

                if didSubmit {
                    Label("You're checked in!", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                Spacer(minLength: 0)
            }
            .padding(24)
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedItem) { _, item in
                Task {
                    photoData = try? await item?.loadTransferable(type: Data.self)
                }
            }
            .alert(
                "Couldn't check in",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Please try again.")
            }
        }
    }

    @MainActor
    private func submit() async {
        guard let photoData else { return }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await CheckInService.submit(
                groupId: groupId,
                date: today,
                photoData: photoData,
                note: note
            )
            didSubmit = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
