//
//  UserManager.swift
//  New app working
//
//  Created by AB on 3/26/25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - User Manager
class UserManagerCK: ObservableObject {
    // Singleton instance
    static let shared = UserManagerCK()
    
    // Published properties
    @Published var currentUser: UserCK?
    @Published var allUsers: [UserCK] = []
    @Published var pendingInvites: [UserCK] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // References
    private let cloudService = CloudKitService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Private initializer for singleton
    private init() {
        // Initial data fetch if user is signed in
        cloudService.$isUserSignedIn
            .filter { $0 }
            .sink { [weak self] _ in
                Task {
                    await self?.fetchAllUsers()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - User Management
    
    /// Fetch all users from CloudKit
    func fetchAllUsers() async {
        guard !isLoading else { return }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let users = try await cloudService.fetchAllUsers()
            
            DispatchQueue.main.async {
                self.allUsers = users
                self.pendingInvites = users.filter { $0.status == .pending }
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.error = "Failed to fetch users: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// Fetch current user (by Apple ID or stored ID)
    func fetchCurrentUser() async {
        guard !isLoading else { return }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        // In a real app, you would have some way to know the current user's ID
        // For this example, we'll try to find a user with matching name from iCloud
        do {
            let users = try await cloudService.fetchAllUsers()
            let potentialUser = users.first(where: { $0.name == cloudService.userName })
            
            DispatchQueue.main.async {
                self.currentUser = potentialUser
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.error = "Failed to fetch current user: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// Register a new user
    func registerUser(name: String, email: String, phone: String, role: UserRoleCK) async -> Bool {
        guard !isLoading else { return false }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        // Create a new user
        let newUser = UserCK(
            name: name,
            email: email,
            phone: phone,
            role: role,
            status: .pending,
            vacationDays: 0,
            timeOffBalance: 0
        )
        
        do {
            let savedUser = try await cloudService.saveUser(newUser)
            
            DispatchQueue.main.async {
                self.allUsers.append(savedUser)
                if savedUser.status == .pending {
                    self.pendingInvites.append(savedUser)
                }
                self.isLoading = false
            }
            
            return true
        } catch {
            DispatchQueue.main.async {
                self.error = "Failed to register user: \(error.localizedDescription)"
                self.isLoading = false
            }
            
            return false
        }
    }
    
    /// Accept an invite for a pending user
    func acceptInvite(for user: UserCK, role: UserRoleCK) async -> Bool {
        guard !isLoading else { return false }
        
        // Create a modified user with active status and the specified role
        var modifiedUser = user
        if let record = user.record {
            record[UserKeys.status] = UserStatusCK.active.recordValue
            record[UserKeys.role] = role.recordValue
        }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let updatedUser = try await cloudService.updateUser(modifiedUser)
            
            DispatchQueue.main.async {
                // Update in allUsers
                if let index = self.allUsers.firstIndex(where: { $0.id == updatedUser.id }) {
                    self.allUsers[index] = updatedUser
                }
                
                // Remove from pendingInvites
                self.pendingInvites.removeAll { $0.id == updatedUser.id }
                
                self.isLoading = false
            }
            
            return true
        } catch {
            DispatchQueue.main.async {
                self.error = "Failed to accept invite: \(error.localizedDescription)"
                self.isLoading = false
            }
            
            return false
        }
    }
    
    /// Decline an invite for a pending user
    func declineInvite(for user: UserCK) async -> Bool {
        guard !isLoading else { return false }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            try await cloudService.deleteUser(user)
            
            DispatchQueue.main.async {
                // Remove from allUsers
                self.allUsers.removeAll { $0.id == user.id }
                
                // Remove from pendingInvites
                self.pendingInvites.removeAll { $0.id == user.id }
                
                self.isLoading = false
            }
            
            return true
        } catch {
            DispatchQueue.main.async {
                self.error = "Failed to decline invite: \(error.localizedDescription)"
                self.isLoading = false
            }
            
            return false
        }
    }
    
    /// Update a user
    func updateUser(_ user: UserCK) async -> Bool {
        guard !isLoading else { return false }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let updatedUser = try await cloudService.updateUser(user)
            
            DispatchQueue.main.async {
                // Update in allUsers
                if let index = self.allUsers.firstIndex(where: { $0.id == updatedUser.id }) {
                    self.allUsers[index] = updatedUser
                }
                
                // Update currentUser if it matches
                if self.currentUser?.id == updatedUser.id {
                    self.currentUser = updatedUser
                }
                
                self.isLoading = false
            }
            
            return true
        } catch {
            DispatchQueue.main.async {
                self.error = "Failed to update user: \(error.localizedDescription)"
                self.isLoading = false
            }
            
            return false
        }
    }
    
    /// Delete a user
    func deleteUser(_ user: UserCK) async -> Bool {
        guard !isLoading else { return false }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            try await cloudService.deleteUser(user)
            
            DispatchQueue.main.async {
                // Remove from allUsers
                self.allUsers.removeAll { $0.id == user.id }
                
                // Remove from pendingInvites if it exists
                self.pendingInvites.removeAll { $0.id == user.id }
                
                // Clear currentUser if it matches
                if self.currentUser?.id == user.id {
                    self.currentUser = nil
                }
                
                self.isLoading = false
            }
            
            return true
        } catch {
            DispatchQueue.main.async {
                self.error = "Failed to delete user: \(error.localizedDescription)"
                self.isLoading = false
            }
            
            return false
        }
    }
    
    /// Declare vacation days
    func declareVacationDays(startDate: Date, endDate: Date) async -> Bool {
        guard !isLoading, let currentUser = self.currentUser else { return false }
        
        // Calculate the number of vacation days
        let calendar = Calendar.current
        let range = calendar.dateComponents([.day], from: startDate, to: endDate)
        let daysCount = max(1, range.day ?? 1)
        
        // Update the user's vacation days
        var modifiedUser = currentUser
        if let record = currentUser.record {
            let remainingDays = max(0, currentUser.vacationDays - daysCount)
            record[UserKeys.vacationDays] = remainingDays
        }
        
        return await updateUser(modifiedUser)
    }
    
    /// Get user by ID
    func getUser(with id: UUID) -> UserCK? {
        return allUsers.first(where: { $0.id == id })
    }
    
    /// Reset state (for logout)
    func reset() {
        currentUser = nil
        allUsers = []
        pendingInvites = []
        error = nil
    }
}

// MARK: - Helper Extension to Bridge Old Model with CloudKit Model
extension AppUser1 {
    func toCloudKitModel() -> UserCK {
        let role: UserRoleCK
        switch self.role {
        case "Admin":
            role = .admin
        case "Mentor":
            role = .mentor
        default:
            role = .student
        }
        
        let status: UserStatusCK
        switch self.status {
        case "Active":
            status = .active
        case "Pending Invitation":
            status = .pending
        default:
            status = .inactive
        }
        
        return UserCK(
            name: name,
            email: email,
            phone: phoneNumber,
            role: role,
            status: status,
            vacationDays: 0,  // Default value
            timeOffBalance: 0.0  // Default value
        )
    }
}

extension UserCK {
    func toAppModel() -> AppUser1 {
        return AppUser1(
            name: name,
            status: status.rawValue.capitalized,
            role: role.rawValue.capitalized,
            phoneNumber: phone,
            email: email,
            monitorName: "Unassigned"  // Default value
        )
    }
}
