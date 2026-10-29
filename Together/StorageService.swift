//
//  StorageService.swift
//  Together
//
//  Created by Dorothy on 29/10/2026.
//


import Foundation
import FirebaseStorage

enum StorageService {
    static func uploadPhoto(
        _ data: Data,
        groupId: String,
        userId: String,
        date: String
    ) async throws -> String {
        let fileId = UUID().uuidString
        let path = "checkIns/\(groupId)/\(date)/\(userId)/\(fileId).jpg"

        let ref = Storage.storage().reference()
            .child(path)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(
            data,
            metadata: metadata
        )

        return path
    }

    static func downloadURL(
        for path: String
    ) async throws -> URL {
        try await Storage.storage()
            .reference()
            .child(path)
            .downloadURL()
    }
}
