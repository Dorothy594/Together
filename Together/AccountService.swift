//
//  AccountService.swift
//  Together
//
//  Created by Dorothy on 29/10/2026.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

struct ConnectedUser: Identifiable {
    let id: String
    let name: String
}

enum AccountService {
    private static let db = Firestore.firestore()

    static func register(name: String, email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(
            withEmail: email.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password
        )

        let change = result.user.createProfileChangeRequest()
        change.displayName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        try await change.commitChanges()

        try await db.collection("users").document(result.user.uid).setData([
            "displayName": name.trimmingCharacters(in: .whitespacesAndNewlines),
            "groupIds": []
        ])
    }

    static func signIn(email: String, password: String) async throws {
        try await Auth.auth().signIn(
            withEmail: email.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password
        )
    }

    static func signOut() throws {
        try Auth.auth().signOut()
    }

    static func createGroup(name: String, user: User) async throws -> String {
        let group = db.collection("groups").document()
        let userRef = db.collection("users").document(user.uid)
        let displayName = user.displayName ?? user.email ?? "Together user"
        let batch = db.batch()

        batch.setData([
            "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
            "createdBy": user.uid,
            "createdAt": FieldValue.serverTimestamp()
        ], forDocument: group)

        batch.setData([
            "userId": user.uid,
            "displayName": displayName,
            "joinedAt": FieldValue.serverTimestamp()
        ], forDocument: group.collection("members").document(user.uid))

        batch.updateData([
            "groupIds": FieldValue.arrayUnion([group.documentID])
        ], forDocument: userRef)

        try await batch.commit()
        return group.documentID
    }

    static func joinGroup(code: String, user: User) async throws {
        let groupId = code.trimmingCharacters(in: .whitespacesAndNewlines)
        let group = db.collection("groups").document(groupId)
        let userRef = db.collection("users").document(user.uid)
        let displayName = user.displayName ?? user.email ?? "Together user"
        let batch = db.batch()

        batch.setData([
            "userId": user.uid,
            "displayName": displayName,
            "joinedAt": FieldValue.serverTimestamp()
        ], forDocument: group.collection("members").document(user.uid))

        batch.updateData([
            "groupIds": FieldValue.arrayUnion([groupId])
        ], forDocument: userRef)

        try await batch.commit()
    }

    static func connectedUsers(for user: User) async throws -> [ConnectedUser] {
        let profile = try await db.collection("users")
            .document(user.uid)
            .getDocument()

        let groupIds = profile.data()?["groupIds"] as? [String] ?? []
        var connected: [String: ConnectedUser] = [:]

        for groupId in groupIds {
            let members = try await db.collection("groups")
                .document(groupId)
                .collection("members")
                .getDocuments()

            for member in members.documents where member.documentID != user.uid {
                let name = member.data()["displayName"] as? String ?? "Together user"
                connected[member.documentID] = ConnectedUser(
                    id: member.documentID,
                    name: name
                )
            }
        }

        return connected.values.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }
}
