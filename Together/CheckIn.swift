//
//  CheckIn.swift
//  Together
//
//  Created by Dorothy on 29/10/2026.
//


import Foundation
import FirebaseFirestore

struct CheckIn: Identifiable, Codable {
    @DocumentID var id: String?

    let userId: String
    let date: String
    let photoPath: String
    let note: String
    let createdAt: Date?
}
