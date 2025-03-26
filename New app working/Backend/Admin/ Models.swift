//
//  AppUser1+CustomUserManager.swift
//  New app working
//
//  Created by AB on 1/9/25.
//

import Foundation
import SwiftUI

// MARK: - AppUser1 Model
struct AppUser1: Identifiable {
    var id = UUID()
    var name: String
    var status: String
    var role: String
    var phoneNumber: String
    var email: String
    var monitorName: String
}

// MARK: - CustomUserManager Class
class CustomUserManager: ObservableObject {
    @Published var allUsers: [AppUser1] = [
        AppUser1(
            name: "Angelo Brown",
            status: "Active",
            role: "Student",
            phoneNumber: "555-123-4567",
            email: "angelo@example.com",
            monitorName: "John Doe"
        ),
        AppUser1(
            name: "Jane Smith",
            status: "Active",
            role: "Mentor",
            phoneNumber: "555-987-6543",
            email: "jane@example.com",
            monitorName: "Emily Davis"
        ),
        AppUser1(
            name: "Michael Johnson",
            status: "Inactive",
            role: "Admin",
            phoneNumber: "555-456-7890",
            email: "michael@example.com",
            monitorName: "Mike Brown"
        )
    ]

    @Published var pendingInvites: [AppUser1] = [
        AppUser1(
            name: "New User 1",
            status: "Pending",
            role: "Pending",
            phoneNumber: "555-111-2222",
            email: "newuser1@example.com",
            monitorName: ""
        ),
        AppUser1(
            name: "New User 2",
            status: "Pending",
            role: "Pending",
            phoneNumber: "555-333-4444",
            email: "newuser2@example.com",
            monitorName: ""
        )
    ]

    // MARK: - Accept Invite with Role Selection
    func acceptInvite(for user: AppUser1, role: String) {
        if let index = pendingInvites.firstIndex(where: { $0.id == user.id }) {
            let acceptedUser = pendingInvites.remove(at: index)
            let activeUser = AppUser1(
                id: acceptedUser.id,
                name: acceptedUser.name,
                status: "Active",
                role: role,
                phoneNumber: acceptedUser.phoneNumber,
                email: acceptedUser.email,
                monitorName: acceptedUser.monitorName
            )
            allUsers.append(activeUser)
        }
    }

    // MARK: - Decline Invite Function
    func declineInvite(for user: AppUser1) {
        if let index = pendingInvites.firstIndex(where: { $0.id == user.id }) {
            pendingInvites.remove(at: index)
        }
    }

    // MARK: - Declare Vacation Days Function
    func declareVacationDays(startDate: Date, endDate: Date) {
        DispatchQueue.main.async {
            print("Vacation Days Declared: \(startDate) - \(endDate)")
        }
    }
}
