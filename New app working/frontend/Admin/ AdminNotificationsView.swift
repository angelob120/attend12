//
//   AdminNotificationsView.swift
//  New app working
//
//  Created by AB on 4/10/25.
//

import SwiftUI

// MARK: - Admin Notification Model
struct AdminNotificationItem: Identifiable, Equatable, Hashable {
    let id = UUID()
    var title: String
    var message: String
    var recipient: NotificationRecipient
    var date: Date
    var status: NotificationStatus
    
    // Enum to specify notification recipient type
    enum NotificationRecipient: Equatable, Hashable {
        case allUsers
        case specificUser(String)
        case userGroup(String)
        case mentors
        case students
        case admins
    }
    
    // Enum to track notification status
    enum NotificationStatus: Equatable, Hashable {
        case draft
        case sent
        case scheduled
    }
    
    // Implement Equatable
    static func == (lhs: AdminNotificationItem, rhs: AdminNotificationItem) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.message == rhs.message &&
               lhs.recipient == rhs.recipient &&
               lhs.date == rhs.date &&
               lhs.status == rhs.status
    }
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
        hasher.combine(message)
        hasher.combine(recipient)
        hasher.combine(date)
        hasher.combine(status)
    }
}

// MARK: - Create Admin Notification View
struct CreateAdminNotificationView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var notificationTitle: String = ""
    @State private var notificationMessage: String = ""
    @State private var selectedRecipient: AdminNotificationItem.NotificationRecipient = .allUsers
    @State private var specificUser: String = ""
    @State private var selectedGroup: String = ""
    @State private var scheduledDate: Date = Date()
    @State private var isScheduled: Bool = false
    
    // List of potential groups
    let userGroups = ["Mentors", "Students", "Admins"]
    
    var body: some View {
        NavigationView {
            Form {
                // Notification Title Section
                Section(header: Text("Notification Details")) {
                    TextField("Notification Title", text: $notificationTitle)
                    
                    TextEditor(text: $notificationMessage)
                        .frame(height: 150)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                
                // Recipient Selection Section
                Section(header: Text("Recipient Type")) {
                    Menu {
                        Button(action: {
                            selectedRecipient = .allUsers
                        }) {
                            Text("All Users")
                            Image(systemName: "person.3.fill")
                        }
                        
                        Button(action: {
                            selectedRecipient = .students
                        }) {
                            Text("All Students")
                            Image(systemName: "graduationcap.fill")
                        }
                        
                        Button(action: {
                            selectedRecipient = .mentors
                        }) {
                            Text("All Mentors")
                            Image(systemName: "person.2.fill")
                        }
                        
                        Button(action: {
                            selectedRecipient = .admins
                        }) {
                            Text("All Admins")
                            Image(systemName: "shield.fill")
                        }
                        
                        Button(action: {
                            selectedRecipient = .userGroup("")
                        }) {
                            Text("User Group")
                            Image(systemName: "rectangles.group.fill")
                        }
                        
                        Button(action: {
                            selectedRecipient = .specificUser("")
                        }) {
                            Text("Specific User")
                            Image(systemName: "person.fill")
                        }
                    } label: {
                        HStack {
                            Text("Send To:")
                            Spacer()
                            Text(recipientLabel(for: selectedRecipient))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Conditional fields based on recipient selection
                Section {
                    switch selectedRecipient {
                    case .userGroup:
                        HStack {
                            Text("Select Group")
                            Spacer()
                            Picker("Group", selection: $selectedGroup) {
                                ForEach(userGroups, id: \.self) { group in
                                    Text(group).tag(group)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(MenuPickerStyle())
                        }
                    case .specificUser:
                        HStack {
                            Text("User Name")
                            Spacer()
                            TextField("Enter Name", text: $specificUser)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.secondary)
                        }
                    default:
                        EmptyView()
                    }
                }
                
                // Scheduling Section
                Section(header: Text("Scheduling")) {
                    Toggle("Schedule Notification", isOn: $isScheduled)
                    
                    if isScheduled {
                        DatePicker("Send Date", selection: $scheduledDate, in: Date()...)
                            .datePickerStyle(CompactDatePickerStyle())
                    }
                }
                
                // Send Button Section
                Section {
                    Button(action: sendNotification) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text(isScheduled ? "Schedule Notification" : "Send Notification")
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.blue)
                    }
                    .disabled(notificationTitle.isEmpty || notificationMessage.isEmpty)
                }
            }
            .navigationTitle("Create Notification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    // Helper method to get a label for the selected recipient
    private func recipientLabel(for recipient: AdminNotificationItem.NotificationRecipient) -> String {
        switch recipient {
        case .allUsers:
            return "All Users"
        case .students:
            return "All Students"
        case .mentors:
            return "All Mentors"
        case .admins:
            return "All Admins"
        case .userGroup(let group):
            return group.isEmpty ? "User Group" : group
        case .specificUser(let name):
            return name.isEmpty ? "Specific User" : name
        }
    }
    
    private func sendNotification() {
        // Determine recipient based on selection
        let finalRecipient: AdminNotificationItem.NotificationRecipient
        switch selectedRecipient {
        case .userGroup:
            finalRecipient = .userGroup(selectedGroup)
        case .specificUser:
            finalRecipient = .specificUser(specificUser)
        default:
            finalRecipient = selectedRecipient
        }
        
        // Determine notification status
        let status: AdminNotificationItem.NotificationStatus = isScheduled ? .scheduled : .sent
        
        // Create notification item
        let newNotification = AdminNotificationItem(
            title: notificationTitle,
            message: notificationMessage,
            recipient: finalRecipient,
            date: isScheduled ? scheduledDate : Date(),
            status: status
        )
        
        // In a real app, this would be sent to a backend or notification service
        print("Created notification: \(newNotification)")
        
        // Dismiss the view
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Admin Notifications View
struct AdminNotificationsView: View {
    @State private var notifications: [AdminNotificationItem] = [
        AdminNotificationItem(
            title: "System Update",
            message: "Upcoming maintenance scheduled for this weekend.",
            recipient: .allUsers,
            date: Date().addingTimeInterval(-24 * 3600),
            status: .sent
        ),
        AdminNotificationItem(
            title: "Quarterly Meeting",
            message: "All hands meeting next Friday at 10 AM.",
            recipient: .mentors,
            date: Date().addingTimeInterval(-48 * 3600),
            status: .draft
        )
    ]
    
    @State private var showingCreateNotification = false
    
    var body: some View {
        NavigationView {
            VStack {
                if notifications.isEmpty {
                    Text("No notifications")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List {
                        ForEach($notifications) { $notification in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(notification.title)
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    // Status badge
                                    statusBadge(for: notification.status)
                                    
                                    // Recipient badge
                                    recipientBadge(for: notification.recipient)
                                }
                                
                                Text(notification.message)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                                
                                // Date display
                                Text(relativeDateString(for: notification.date))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Centered Title
                ToolbarItem(placement: .principal) {
                    Text("Admin Notifications")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                // Add Notification Button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateNotification = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                    }
                }
            }
            .toolbarBackground(Color.customGreen, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showingCreateNotification) {
                CreateAdminNotificationView()
            }
        }
    }
    
    // Helper function to create recipient badge
    private func recipientBadge(for recipient: AdminNotificationItem.NotificationRecipient) -> some View {
        var badgeText: String
        var badgeColor: Color
        
        switch recipient {
        case .allUsers:
            badgeText = "All Users"
            badgeColor = .blue
        case .students:
            badgeText = "Students"
            badgeColor = .green
        case .mentors:
            badgeText = "Mentors"
            badgeColor = .orange
        case .admins:
            badgeText = "Admins"
            badgeColor = .red
        case .userGroup(let group):
            badgeText = group.isEmpty ? "User Group" : group
            badgeColor = .purple
        case .specificUser(let name):
            badgeText = name.isEmpty ? "Specific User" : name
            badgeColor = .indigo
        }
        
        return Text(badgeText)
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeColor)
            .cornerRadius(8)
    }
    
    // Helper function to create status badge
    private func statusBadge(for status: AdminNotificationItem.NotificationStatus) -> some View {
        var badgeText: String
        var badgeColor: Color
        
        switch status {
        case .draft:
            badgeText = "Draft"
            badgeColor = .gray
        case .sent:
            badgeText = "Sent"
            badgeColor = .green
        case .scheduled:
            badgeText = "Scheduled"
            badgeColor = .blue
        }
        
        return Text(badgeText)
            .font(.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeColor)
            .cornerRadius(8)
    }
    
    // Helper function to display relative date
    private func relativeDateString(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// Preview
struct AdminNotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        AdminNotificationsView()
    }
}
