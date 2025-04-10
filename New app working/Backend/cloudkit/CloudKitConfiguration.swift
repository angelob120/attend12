//
//  CloudKitConfiguration.swift
//  New app working
//
//  Created by AB on 3/26/25.
//  Updated with additional fields for UserProfile

import Foundation
import SwiftUI
import Combine
import CloudKit


// MARK: - CloudKit App Configuration
class CloudKitAppConfig: ObservableObject {
    // Singleton instance
    static let shared = CloudKitAppConfig()
    
    // Services
    let cloudKitService = CloudKitService.shared
    let attendanceManager = AttendanceManager.shared
    let menteeManager = MenteeManagerCK.shared
    let userManager = UserManagerCK.shared
    
    // Published properties
    @Published var isCloudKitAvailable = true  // Always set to true to bypass iCloud check
    @Published var isSetupComplete = false
    @Published var currentUserRoleCK: UserRoleCK = .student
    @Published var isOnboardingRequired = false  // New property to track onboarding status
    @Published var userProfile = UserProfile()   // New property to store user profile data
    
    // Private initializer for singleton
    private init() {
        // Setup observers
        setupObservers()
        
        // Check if onboarding is required
        checkOnboardingStatus()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // We'll skip checking CloudKit availability since we're bypassing it
        
        // Observe current user for role
        userManager.$currentUser
            .compactMap { $0?.role }
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentUserRoleCK, on: self)
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - App Initialization
    
    /// Initialize the app with local data instead of CloudKit backend
    func initializeApp() async {
        // Force isCloudKitAvailable to true to bypass iCloud requirement
        DispatchQueue.main.async {
            self.isCloudKitAvailable = true
        }
        
        // Check if user profile exists in UserDefaults
        if let savedProfile = UserDefaults.standard.data(forKey: "userProfile") {
            do {
                let decoder = JSONDecoder()
                let profile = try decoder.decode(UserProfile.self, from: savedProfile)
                
                DispatchQueue.main.async {
                    self.userProfile = profile
                    self.isOnboardingRequired = false
                }
            } catch {
                print("Error loading user profile: \(error)")
                DispatchQueue.main.async {
                    self.isOnboardingRequired = true
                }
            }
        } else {
            // No profile found, require onboarding
            DispatchQueue.main.async {
                self.isOnboardingRequired = true
            }
        }
        
        // Create a default user if none exists
        if userManager.currentUser == nil {
            let defaultName = userProfile.name.isEmpty ? "Demo User" : userProfile.name
            let defaultEmail = userProfile.email.isEmpty ? "demo.user@example.com" : userProfile.email
            
            let success = await userManager.registerUser(
                name: defaultName,
                email: defaultEmail,
                phone: userProfile.phone.isEmpty ? "123-456-7890" : userProfile.phone,
                role: .student // Default role
            )
            
            if success {
                // Fetch the newly created user
                await userManager.fetchCurrentUser()
            }
        }
        
        // Load sample mentees data
        await menteeManager.fetchAllMentees()
        
        // Mark setup as complete
        DispatchQueue.main.async {
            self.isSetupComplete = true
        }
    }
    
    // MARK: - Onboarding
    
    /// Check if onboarding is required
    private func checkOnboardingStatus() {
        // Check if user profile exists in UserDefaults
        if UserDefaults.standard.data(forKey: "userProfile") == nil {
            isOnboardingRequired = true
        } else {
            isOnboardingRequired = false
        }
    }
    
    /// Save user profile after onboarding
    func saveUserProfile(name: String, email: String, mentorName: String, phone: String = "",
                        classType: String = "Regular Class", timeSlot: String = "AM",
                        classCode: String = "") {
        // Update the profile
        userProfile.name = name
        userProfile.email = email
        userProfile.mentorName = mentorName
        userProfile.phone = phone
        userProfile.classType = classType
        userProfile.timeSlot = timeSlot
        userProfile.classCode = classCode
        userProfile.onboardingComplete = true
        
        // Save to UserDefaults
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(userProfile)
            UserDefaults.standard.set(data, forKey: "userProfile")
            
            // Update onboarding status
            isOnboardingRequired = false
        } catch {
            print("Error saving user profile: \(error)")
        }
    }
    
    // MARK: - Role-Based Navigation
    
    /// Map UserRoleCK to a string representing the app's role
    func mapToAppUserRole() -> String {
        switch currentUserRoleCK {
        case .admin:
            return "admin"
        case .mentor:
            return "mentor"
        case .student:
            return "student"
        }
    }
    
    // MARK: - Check if user is signed in and setup is complete
    var isReady: Bool {
        return isCloudKitAvailable && isSetupComplete
    }
    
    /// Reset all managers (for logout)
    func resetAll() {
        attendanceManager.reset()
        menteeManager.reset()
        userManager.reset()
        
        // Reset user profile
        userProfile = UserProfile()
        UserDefaults.standard.removeObject(forKey: "userProfile")
        isOnboardingRequired = true
    }
}

// MARK: - User Profile Model
struct UserProfile: Codable {
    var name: String = ""
    var email: String = ""
    var mentorName: String = ""
    var vacationDays: Int = 96
    
    // Additional fields for capturing onboarding data
    var phone: String = ""
    var classType: String = "Regular Class"
    var timeSlot: String = "AM"
    var classCode: String = ""
    var onboardingComplete: Bool = false
    
    init(name: String = "", email: String = "", mentorName: String = "", vacationDays: Int = 96,
         phone: String = "", classType: String = "Regular Class", timeSlot: String = "AM",
         classCode: String = "", onboardingComplete: Bool = false) {
        self.name = name
        self.email = email
        self.mentorName = mentorName
        self.vacationDays = vacationDays
        self.phone = phone
        self.classType = classType
        self.timeSlot = timeSlot
        self.classCode = classCode
        self.onboardingComplete = onboardingComplete
    }
}
