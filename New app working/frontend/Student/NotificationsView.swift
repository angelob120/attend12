//
//  NotificationsView.swift
//  New app working
//
//  Created by AB on 2/27/25.
//


import SwiftUI


// MARK: - Notification Model
struct NotificationItem: Identifiable {
    let id = UUID()
    var title: String
    var message: String
    var isRead: Bool = false
}

// MARK: - NotificationsView
struct NotificationsView1: View {
    @State private var notifications: [NotificationItem] = [
        NotificationItem(title: "Welcome", message: "Thanks for joining the app!"),
        NotificationItem(title: "Update", message: "Your schedule has been updated.")
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                if notifications.isEmpty {
                    Text("No new notifications")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    List {
                        ForEach($notifications) { $notification in
                            NotificationRow(notification: $notification)
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
                    Text("Notifications")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(Color.customGreen, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

// MARK: - NotificationRow
struct NotificationRow: View {
    @Binding var notification: NotificationItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(notification.title)
                .font(.headline)
                .foregroundColor(notification.isRead ? .secondary : .primary)
            Text(notification.message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .swipeActions(edge: .trailing) {
            if !notification.isRead {
                Button("Mark as Read") {
                    notification.isRead = true
                }
                .tint(.blue)
            } else {
                Button("Mark as Unread") {
                    notification.isRead = false
                }
                .tint(.orange)
            }
        }
    }
}

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
    }
}
