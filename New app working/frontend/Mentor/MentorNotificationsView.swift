import SwiftUI

// MARK: - Mentor Notification Model
struct MentorNotificationItem: Identifiable, Equatable, Hashable {
    let id = UUID()
    var title: String
    var message: String
    var recipient: NotificationRecipient
    var date: Date
    var status: NotificationStatus
    
    // Enum to specify notification recipient type
    enum NotificationRecipient: Equatable, Hashable {
        case allStudents
        case specificStudent(String)
        case menteeGroup(String)
        case myMentees
    }
    
    // Enum to track notification status
    enum NotificationStatus: Equatable, Hashable {
        case draft
        case sent
        case scheduled
    }
    
    // Implement Equatable
    static func == (lhs: MentorNotificationItem, rhs: MentorNotificationItem) -> Bool {
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

// MARK: - Create Mentor Notification View
struct CreateMentorNotificationView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var notificationTitle: String = ""
    @State private var notificationMessage: String = ""
    @State private var selectedRecipient: MentorNotificationItem.NotificationRecipient = .myMentees
    @State private var specificStudent: String = ""
    @State private var selectedGroup: String = ""
    @State private var scheduledDate: Date = Date()
    @State private var isScheduled: Bool = false
    
    // List of potential groups (can be expanded)
    let menteeGroups = ["Renaissance Class", "Regular Class"]
    
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
                Section(header: Text("Send To")) {
                    Picker("Recipient", selection: $selectedRecipient) {
                        Text("My Mentees").tag(MentorNotificationItem.NotificationRecipient.myMentees)
                        Text("All").tag(MentorNotificationItem.NotificationRecipient.allStudents)
                        Text("Group").tag(MentorNotificationItem.NotificationRecipient.menteeGroup(""))
                        Text("Specific Student").tag(MentorNotificationItem.NotificationRecipient.specificStudent(""))
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    // Conditional fields based on recipient selection
                    switch selectedRecipient {
                    case .menteeGroup:
                        HStack {
                            Text("Select Group")
                            Spacer()
                            Picker("Group", selection: $selectedGroup) {
                                ForEach(menteeGroups, id: \.self) { group in
                                    Text(group).tag(group)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(MenuPickerStyle())
                        }
                    case .specificStudent:
                        HStack {
                            Text("Student Name")
                            Spacer()
                            TextField("Enter Name", text: $specificStudent)
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
    
    private func sendNotification() {
        // Determine recipient based on selection
        let finalRecipient: MentorNotificationItem.NotificationRecipient
        switch selectedRecipient {
        case .menteeGroup:
            finalRecipient = .menteeGroup(selectedGroup)
        case .specificStudent:
            finalRecipient = .specificStudent(specificStudent)
        case .allStudents:
            finalRecipient = .allStudents
        default:
            finalRecipient = .myMentees
        }
        
        // Determine notification status
        let status: MentorNotificationItem.NotificationStatus = isScheduled ? .scheduled : .sent
        
        // Create notification item
        let newNotification = MentorNotificationItem(
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

// MARK: - Mentor Notifications View
struct MentorNotificationsView: View {
    @State private var notifications: [MentorNotificationItem] = [
        MentorNotificationItem(
            title: "Workshop Reminder",
            message: "Prepare for the upcoming mentorship workshop.",
            recipient: .myMentees,
            date: Date().addingTimeInterval(-24 * 3600),
            status: .sent
        ),
        MentorNotificationItem(
            title: "Progress Report",
            message: "Draft submitted for review.",
            recipient: .specificStudent("Angelo Brown"),
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
                    Text("Mentor Notifications")
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
                CreateMentorNotificationView()
            }
        }
    }
    
    // Helper function to create recipient badge
    private func recipientBadge(for recipient: MentorNotificationItem.NotificationRecipient) -> some View {
        var badgeText: String
        var badgeColor: Color
        
        switch recipient {
        case .myMentees:
            badgeText = "My Mentees"
            badgeColor = .blue
        case .allStudents:
            badgeText = "All Students"
            badgeColor = .green
        case .menteeGroup(let group):
            badgeText = group
            badgeColor = .orange
        case .specificStudent(let name):
            badgeText = name
            badgeColor = .purple
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
    private func statusBadge(for status: MentorNotificationItem.NotificationStatus) -> some View {
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
    
    // Helper method to get a label for the selected recipient
    private func recipientLabel(for recipient: MentorNotificationItem.NotificationRecipient) -> String {
        switch recipient {
        case .myMentees:
            return "My Mentees"
        case .allStudents:
            return "All Students"
        case .menteeGroup(let group):
            return group.isEmpty ? "Mentee Group" : group
        case .specificStudent(let name):
            return name.isEmpty ? "Specific Student" : name
        }
    }
}

// Preview
struct MentorNotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        MentorNotificationsView()
    }
}
