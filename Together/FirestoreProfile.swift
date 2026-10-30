//
//  FirestoreProfile.swift
//  Together
//
//  Created by Dorothy on 29/10/2026.
//


import Foundation
import FirebaseFirestore

enum FirestoreProfile {
    static func create(userId: String, email: String) async throws {
        try await Firestore.firestore()
            .collection("users")
            .document(userId)
            .setData([
                "email": email,
                "createdAt": FieldValue.serverTimestamp()
            ], merge: true)
    }
}
