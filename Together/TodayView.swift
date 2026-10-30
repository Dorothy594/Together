//
//  TodayView.swift
//  Together
//
//  Created by Dorothy on 29/10/2026.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct TodayView: View {
    @AppStorage("groupId") private var groupId = ""
    private let db = Firestore.firestore()

    @State private var myCheckedIn = false
    @State private var friendCheckedIn = false
    @State private var isCheckingIn = false
    @State private var listener: ListenerRegistration?
    @State private var errorMessage: String?
    @State private var showError = false

    private var today: String {
        Self.dateFormatter.string(from: Date())
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private var completedCount: Int {
        (myCheckedIn ? 1 : 0) + (friendCheckedIn ? 1 : 0)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(Date.now.formatted(
                            .dateTime.weekday(.wide)
                                .month(.wide)
                                .day()
                        ))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                        Text("Today, together.")
                            .font(.largeTitle.bold())

                        Text("Small steps, shared progress.")
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Label(
                            "OUR SHARED GOAL",
                            systemImage: "scope"
                        )
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                        Text("Build a healthier routine")
                            .font(.title2.bold())

                        Text("Show up for yourself and each other.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        Color.blue.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 20)
                    )

                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Today's progress")
                                .font(.headline)

                            Spacer()

                            Text("\(completedCount) of 2")
                                .font(.subheadline.bold())
                                .foregroundStyle(.blue)
                        }

                        ProgressView(
                            value: Double(completedCount),
                            total: 2
                        )
                        .tint(.blue)

                        HStack(spacing: 12) {
                            memberStatus(
                                name: "You",
                                isComplete: myCheckedIn
                            )

                            memberStatus(
                                name: "Your friend",
                                isComplete: friendCheckedIn
                            )
                        }
                    }

                    VStack(spacing: 14) {
                        Image(
                            systemName: myCheckedIn
                                ? "checkmark.seal.fill"
                                : "calendar.badge.checkmark"
                        )
                        .font(.system(size: 42))
                        .foregroundStyle(
                            myCheckedIn ? .green : .blue
                        )

                        Text(
                            myCheckedIn
                                ? "You've checked in today!"
                                : "Ready to check in?"
                        )
                        .font(.title3.bold())

                        Text(
                            myCheckedIn
                                ? "Great job. Come back tomorrow!"
                                : "Take a moment to mark today's progress."
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                        Button {
                            Task {
                                await checkIn()
                            }
                        } label: {
                            HStack {
                                if isCheckingIn {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(
                                        systemName: myCheckedIn
                                            ? "checkmark"
                                            : "checkmark.circle.fill"
                                    )
                                }

                                Text(
                                    myCheckedIn
                                        ? "Checked in"
                                        : "Check in"
                                )
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(myCheckedIn || isCheckingIn)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        Color(.secondarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 20)
                    )

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Today's activity")
                            .font(.headline)

                        activityRow(
                            name: "You",
                            isComplete: myCheckedIn
                        )

                        activityRow(
                            name: "Your friend",
                            isComplete: friendCheckedIn
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Together")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                startListening()
            }
            .onDisappear {
                listener?.remove()
                listener = nil
            }
            .alert("Something went wrong", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Please try again.")
            }
        }
        
    }

    private func memberStatus(
        name: String,
        isComplete: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(
                systemName: isComplete
                    ? "checkmark.circle.fill"
                    : "circle"
            )
            .font(.title)
            .foregroundStyle(
                isComplete ? .green : .secondary
            )

            Text(name)
                .font(.subheadline.bold())

            Text(isComplete ? "Checked in" : "Not yet")
                .font(.caption)
                .foregroundStyle(
                    isComplete ? .green : .secondary
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            Color(.secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }

    private func activityRow(
        name: String,
        isComplete: Bool
    ) -> some View {
        HStack(spacing: 12) {
            Image(
                systemName: isComplete
                    ? "checkmark.circle.fill"
                    : "clock"
            )
            .font(.title3)
            .foregroundStyle(
                isComplete ? .green : .secondary
            )

            Text(name)
                .font(.subheadline.bold())

            Spacer()

            Text(isComplete ? "Completed" : "Not yet")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func checkIn() async {
        guard groupId != "YOUR_GROUP_ID",
              !groupId.isEmpty else {
            errorMessage = "Please configure your real group ID."
            showError = true
            return
        }

        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Please sign in first."
            showError = true
            return
        }

        guard !myCheckedIn else { return }

        isCheckingIn = true
        defer { isCheckingIn = false }

        let date = today
        let documentId = "\(date)_\(userId)"

        let ref = db.collection("groups")
            .document(groupId)
            .collection("checkIns")
            .document(documentId)

        do {
            // Transaction prevents two simultaneous submissions
            // from creating duplicate records for this user/day.
            try await db.runTransaction { transaction, errorPointer in
                do {
                    let snapshot = try transaction.getDocument(ref)

                    if snapshot.exists {
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

                    transaction.setData([
                        "userId": userId,
                        "date": date,
                        "createdAt": FieldValue.serverTimestamp()
                    ], forDocument: ref)

                    return true
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }

            // The listener will update the UI from Firestore.
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func startListening() {
        guard groupId != "YOUR_GROUP_ID",
              !groupId.isEmpty,
              let userId = Auth.auth().currentUser?.uid else {
            myCheckedIn = false
            friendCheckedIn = false
            return
        }

        listener?.remove()

        let date = today

        listener = db.collection("groups")
            .document(groupId)
            .collection("checkIns")
            .whereField("date", isEqualTo: date)
            .addSnapshotListener { snapshot, error in
                guard error == nil,
                      let documents = snapshot?.documents else {
                    return
                }

                let mine = documents.contains {
                    $0.data()["userId"] as? String == userId
                }

                let friend = documents.contains {
                    guard let id = $0.data()["userId"] as? String
                    else { return false }
                    return id != userId
                }

                DispatchQueue.main.async {
                    myCheckedIn = mine
                    friendCheckedIn = friend
                }
            }
    }
}



// MARK: - Progress screen
struct ProgressScreen: View {
    @AppStorage("groupId") private var groupId = ""
    private let db = Firestore.firestore()

    @State private var displayedMonth = Calendar.current
        .dateInterval(of: .month, for: Date())?.start ?? Date()

    @State private var checkIns: [String: Set<String>] = [:]
    @State private var listener: ListenerRegistration?

    private let calendar = Calendar.current

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide).year())
    }

    private var daysInMonth: [Date] {
        guard let interval = calendar.dateInterval(
            of: .month,
            for: displayedMonth
        ) else {
            return []
        }

        let count = calendar.range(of: .day, in: .month,
                                   for: displayedMonth)?.count ?? 0

        return (0..<count).compactMap {
            calendar.date(byAdding: .day, value: $0, to: interval.start)
        }
    }

    private var leadingEmptyDays: Int {
        guard let firstDay = daysInMonth.first else { return 0 }
        // Monday-first calendar
        return (calendar.component(.weekday, from: firstDay) + 5) % 7
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        Button {
                            changeMonth(by: -1)
                        } label: {
                            Image(systemName: "chevron.left")
                        }

                        Spacer()

                        Text(monthTitle)
                            .font(.title2.bold())

                        Spacer()

                        Button {
                            changeMonth(by: 1)
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                        .disabled(
                            calendar.isDate(
                                displayedMonth,
                                equalTo: Date(),
                                toGranularity: .month
                            )
                        )
                    }
                    .padding(.horizontal)

                    let weekdays = ["M", "T", "W", "T", "F", "S", "S"]

                    LazyVGrid(
                        columns: Array(
                            repeating: GridItem(.flexible()),
                            count: 7
                        ),
                        spacing: 12
                    ) {
                        ForEach(weekdays.indices, id: \.self) { index in
                            Text(weekdays[index])
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                        }

                        ForEach(0..<leadingEmptyDays, id: \.self) { _ in
                            Color.clear
                                .frame(height: 48)
                        }

                        ForEach(daysInMonth, id: \.self) { date in
                            dayCell(date)
                        }
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Legend")
                            .font(.headline)

                        legendRow(color: .green, text: "Both checked in")
                        legendRow(color: .blue, text: "You checked in")
                        legendRow(color: .purple, text: "Friend checked in")
                        legendRow(color: .gray.opacity(0.3), text: "No check-in")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        Color(.secondarySystemBackground),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Progress")
            .task {
                startListening()
            }
            .onDisappear {
                listener?.remove()
                listener = nil
            }
        }
    }

    @ViewBuilder
    private func dayCell(_ date: Date) -> some View {
        let key = dateKey(date)
        let users = checkIns[key] ?? []
        let mine = users.contains(Auth.auth().currentUser?.uid ?? "")
        let friend = users.contains { $0 != Auth.auth().currentUser?.uid }

        VStack(spacing: 5) {
            Text("\(calendar.component(.day, from: date))")
                .font(.subheadline)
                .foregroundStyle(
                    calendar.isDateInToday(date) ? .blue : .primary
                )

            Circle()
                .fill(statusColor(mine: mine, friend: friend))
                .frame(width: 8, height: 8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .background(
            calendar.isDateInToday(date)
                ? Color.blue.opacity(0.1)
                : Color.clear,
            in: RoundedRectangle(cornerRadius: 10)
        )
    }

    private func statusColor(mine: Bool, friend: Bool) -> Color {
        switch (mine, friend) {
        case (true, true): return .green
        case (true, false): return .blue
        case (false, true): return .purple
        default: return .gray.opacity(0.25)
        }
    }

    private func legendRow(color: Color, text: String) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            Text(text)
                .font(.subheadline)
        }
    }

    private func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func changeMonth(by offset: Int) {
        guard let newDate = calendar.date(
            byAdding: .month,
            value: offset,
            to: displayedMonth
        ) else { return }

        if newDate <= Date() {
            displayedMonth = newDate
        }
    }

    private func startListening() {
        guard groupId != "YOUR_GROUP_ID", !groupId.isEmpty else {
            return
        }

        listener?.remove()

        listener = db.collection("groups")
            .document(groupId)
            .collection("checkIns")
            .addSnapshotListener { snapshot, error in
                guard error == nil,
                      let documents = snapshot?.documents else {
                    return
                }

                var result: [String: Set<String>] = [:]

                for document in documents {
                    let data = document.data()

                    guard let date = data["date"] as? String,
                          let userId = data["userId"] as? String else {
                        continue
                    }

                    result[date, default: []].insert(userId)
                }

                DispatchQueue.main.async {
                    checkIns = result
                }
            }
    }
}


// MARK: - Settings screen
struct SettingsView: View {
    @AppStorage("groupId") private var groupId = ""

    @State private var inviteCode = ""
    @State private var isWorking = false
    @State private var statusMessage = ""
    @State private var showStatus = false
    @State private var showSignOut = false
    @State private var memberCount = 0
    @State private var groupListener: ListenerRegistration?

    private let db = Firestore.firestore()

    private var user: User? {
        Auth.auth().currentUser
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("My Account") {
                    LabeledContent(
                        "Email",
                        value: user?.email ?? "Not signed in"
                    )

                    Button(role: .destructive) {
                        showSignOut = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }

                Section("Your Shared Space") {
                    if groupId.isEmpty {
                        Text("You haven't joined a group yet.")
                            .foregroundStyle(.secondary)

                        Button {
                            Task {
                                await createGroup()
                            }
                        } label: {
                            Label("Create a Group", systemImage: "plus.circle.fill")
                        }
                        .disabled(isWorking)

                        Divider()

                        TextField("Enter your friend's invite code", text: $inviteCode)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()

                        Button {
                            Task {
                                await joinGroup()
                            }
                        } label: {
                            Label("Join a Group", systemImage: "person.2.fill")
                        }
                        .disabled(isWorking || inviteCode.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ).isEmpty)
                    } else {
                        VStack(alignment: .leading, spacing: 16) {

                            if memberCount < 2 {
                                Label(
                                    "Waiting for your friend",
                                    systemImage: "clock"
                                )
                                .font(.headline)

                                Text("Your shared space is ready. Share the code below with your friend.")
                                    .foregroundStyle(.secondary)
                            } else {
                                Label(
                                    "You're connected!",
                                    systemImage: "checkmark.circle.fill"
                                )
                                .font(.headline)
                                .foregroundStyle(.green)

                                Text("Both members have joined your shared space.")
                                    .foregroundStyle(.secondary)
                            }

                            Text("Invite Code")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(groupId)
                                .font(.title2.bold())
                                .textSelection(.enabled)

                            Text("\(memberCount) / 2 members")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            if memberCount < 2 {
                                ShareLink(
                                    item: "Join me on Together! Enter this invite code: \(groupId)"
                                ) {
                                    Label("Invite a Friend", systemImage: "square.and.arrow.up")
                                }
                            }
                        }
                    }                }

                Section("About") {
                    LabeledContent("App", value: "Together")
                    LabeledContent("Version", value: "1.0")
                }
            }
            .navigationTitle("Settings")
            .overlay {
                if isWorking {
                    ProgressView("Please wait...")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .confirmationDialog(
                "Sign out of Together?",
                isPresented: $showSignOut,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    signOut()
                }

                Button("Cancel", role: .cancel) {}
            }
            .alert("Together", isPresented: $showStatus) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(statusMessage)
            }
        }
        .onAppear {
            startGroupListener()
        }
        .onChange(of: groupId) { _, _ in
            startGroupListener()
        }
        .onDisappear {
            groupListener?.remove()
            groupListener = nil
        }
    }

    // MARK: Create a group
    private func startGroupListener() {
        groupListener?.remove()

        guard !groupId.isEmpty else {
            memberCount = 0
            return
        }

        groupListener = db.collection("groups")
            .document(groupId)
            .addSnapshotListener { snapshot, error in

                guard let data = snapshot?.data(),
                      let members = data["memberIds"] as? [String] else {
                    return
                }

                DispatchQueue.main.async {
                    memberCount = members.count
                }
            }
    }

    @MainActor
    private func createGroup() async {
        guard let user else {
            showMessage("Please sign in first.")
            return
        }

        guard groupId.isEmpty else {
            showMessage("You already belong to a group.")
            return
        }

        isWorking = true
        defer { isWorking = false }

        let code = String(
            UUID().uuidString
                .replacingOccurrences(of: "-", with: "")
                .prefix(10)
        )

        let groupRef = db.collection("groups").document(code)

        do {
            try await groupRef.setData([
                "memberIds": [user.uid],
                "goalTitle": "Build a healthier routine",
                "createdAt": FieldValue.serverTimestamp()
            ])

            try await db.collection("users")
                .document(user.uid)
                .setData(["groupId": code], merge: true)

            groupId = code
            showMessage("Your group has been created. Share the invite code with your friend.")
        } catch {
            showMessage(error.localizedDescription)
        }
    }

    // MARK: Join a group

    @MainActor
    private func joinGroup() async {
        guard let user else {
            showMessage("Please sign in first.")
            return
        }

        guard groupId.isEmpty else {
            showMessage("You already belong to a group.")
            return
        }

        let code = inviteCode
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        guard code.count == 10 else {
            showMessage("Please enter the 10-character invite code.")
            return
        }

        isWorking = true
        defer { isWorking = false }

        let groupRef = db.collection("groups").document(code)

        do {
            _ = try await db.runTransaction {
                transaction, errorPointer -> Any? in

                do {
                    let snapshot = try transaction.getDocument(groupRef)

                    guard snapshot.exists,
                          let data = snapshot.data(),
                          var members = data["memberIds"] as? [String] else {
                        errorPointer?.pointee = NSError(
                            domain: "Together",
                            code: 404,
                            userInfo: [
                                NSLocalizedDescriptionKey:
                                    "This invite code is invalid."
                            ]
                        )
                        return nil
                    }

                    if members.contains(user.uid) {
                        return true
                    }

                    guard members.count < 2 else {
                        errorPointer?.pointee = NSError(
                            domain: "Together",
                            code: 409,
                            userInfo: [
                                NSLocalizedDescriptionKey:
                                    "This group already has two members."
                            ]
                        )
                        return nil
                    }

                    members.append(user.uid)

                    transaction.updateData(
                        ["memberIds": members],
                        forDocument: groupRef
                    )

                    return true
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }

            try await db.collection("users")
                .document(user.uid)
                .setData(["groupId": code], merge: true)

            groupId = code
            inviteCode = ""

            showMessage("You've joined your friend's group!")
        } catch {
            showMessage(error.localizedDescription)
        }
    }

    // MARK: Sign out

    private func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            showMessage(error.localizedDescription)
        }
    }

    @MainActor
    private func showMessage(_ message: String) {
        statusMessage = message
        showStatus = true
    }
}
