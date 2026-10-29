//
//  CheckInService.swift
//  Together
//
//  Created by Dorothy on 29/10/2026.
//


import Foundation
import FirebaseAuth
import FirebaseFirestore

enum CheckInService {
    static let db = Firestore.firestore()

    static func submit(
        groupId: String,
        date: String,
        photoData: Data,
        note: String
    ) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(
                domain: "Together",
                code: 401,
                userInfo: [
                    NSLocalizedDescriptionKey: "Please sign in first."
                ]
            )
        }

        // Upload the photo first.
        let path = try await StorageService.uploadPhoto(
            photoData,
            groupId: groupId,
            userId: userId,
            date: date
        )

        // One document per user per day.
        let documentId = "\(date)_\(userId)"

        let ref = db.collection("groups")
            .document(groupId)
            .collection("checkIns")
            .document(documentId)

        let data: [String: Any] = [
            "userId": userId,
            "date": date,
            "photoPath": path,
            "note": String(note.prefix(200)),
            "createdAt": FieldValue.serverTimestamp()
        ]

        // create() fails if the document already exists.
        // This prevents overwriting an existing check-in.
        try await db.runTransaction { transaction, errorPointer in
            do {
                // Check whether today's check-in already exists.
                let snapshot = try transaction.getDocument(ref)

                guard !snapshot.exists else {
                    errorPointer?.pointee = NSError(
                        domain: "Together",
                        code: 409,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "You have already checked in today."
                        ]
                    )
                    return nil
                }

                transaction.setData(data, forDocument: ref)
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }
}
