//
//  FileMakerConfiguration.swift
//  New app working
//
//  Created by AB on 4/16/25.
//

import Foundation
import SwiftUI
import Combine

/// Main configuration class for FileMaker integration
class FileMakerAppConfig: ObservableObject {
    // Singleton instance
    static let shared = FileMakerAppConfig()
    
    // Published properties for UI updates
    @Published var isReady = false
    @Published var isFileMakerAvailable = false
    @Published var isInitializing = true
    @Published var hasError = false
    @Published var errorMessage = ""
    
    // User management
    @Published var currentUserFM: UserFM?
    @Published var currentUserRoleFM: UserRoleFM = .student
    @Published var userProfile = UserProfileFM()
    @Published var attendanceManager = AttendanceManagerFM.shared
    
    // Service instance
    private let fmService = FileMakerService.shared
    
    // Private initializer for singleton
    private init() {
        // Initialize with default values
    }
    
    func getAllUsers() async -> [AppUser1] {
        // Convert UserFM to AppUser1
        return await (try? FileMakerService.shared.fetchAllUsers().map { $0.toAppModel() }) ?? []
    }
    
    // MARK: - App Initialization
    
    /// Initialize the app with FileMaker
    func initializeApp() async {
        // Set initializing state
        DispatchQueue.main.async {
            self.isInitializing = true
            self.hasError = false
            self.errorMessage = ""
        }
        
        do {
            // Authenticate with FileMaker
            try await fmService.authenticate()
            
            // Mark FileMaker as available and the app as ready
            DispatchQueue.main.async {
                self.isFileMakerAvailable = true
                self.isReady = true
                self.isInitializing = false
            }
        } catch {
            // Handle authentication error
            DispatchQueue.main.async {
                self.isFileMakerAvailable = false
                self.hasError = true
                self.errorMessage = "Could not connect to FileMaker: \(error.localizedDescription)"
                
                // Mark as ready anyway so the app can proceed in offline mode
                self.isReady = true
                self.isInitializing = false
            }
        }
    }
    
    // MARK: - User Management
    
    /// Map current role to app user role
    func mapToAppUserRole() -> String {
        switch currentUserRoleFM {
        case .admin:
            return "admin"
        case .mentor:
            return "mentor"
        case .student:
            return "student"
        case .pending:
            return "pending"
        }
    }
    
    /// Update user profile from UserFM model
    func updateUserProfile(from user: UserFM) {
        var updatedProfile = UserProfileFM()
        updatedProfile.name = user.name
        updatedProfile.email = user.email
        updatedProfile.role = user.role
        updatedProfile.phone = user.phone
        
        // Set optional fields if available
        if let mentorName = user.mentorName {
            updatedProfile.mentorName = mentorName
        }
        
        if let classType = user.classType {
            updatedProfile.classType = classType
        }
        
        if let timeSlot = user.timeSlot {
            updatedProfile.timeSlot = timeSlot
        }
        
        if let classCode = user.classCode {
            updatedProfile.classCode = classCode
        }
        
        updatedProfile.onboardingComplete = user.onboardingComplete ?? false
        
        // Update published property
        DispatchQueue.main.async {
            self.userProfile = updatedProfile
            self.currentUserRoleFM = user.role
            self.currentUserFM = user
        }
    }
    
    /// Save current user profile to FileMaker
    func saveUserProfile() async throws {
        // Only save if we have a current user
        guard let currentUser = currentUserFM else {
            throw FileMakerError.recordNotFound
        }
        
        // Update the user model with the current profile
        var updatedUser = currentUser
        updatedUser.role = userProfile.role
        
        // Save the updated user to FileMaker
        let savedUser = try await fmService.updateUser(updatedUser)
        
        // Update the current user
        DispatchQueue.main.async {
            self.currentUserFM = savedUser
        }
        
        return
    }
    
    // MARK: - Reset
    
    /// Reset all data (for logout)
    func resetAll() {
        // Reset user data
        currentUserFM = nil
        currentUserRoleFM = .student
        userProfile = UserProfileFM()
        
        // Reset attendance manager
        attendanceManager.reset()
        
        // Reset state flags
        isReady = false
        isInitializing = true
        hasError = false
        errorMessage = ""
        
        // Re-initialize the app
        Task {
            await initializeApp()
        }
    }
}
