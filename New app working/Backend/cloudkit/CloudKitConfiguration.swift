//
//  CloudKitConfiguration.swift
//  New app working
//
//  Created by AB on 3/26/25.
//

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
    @Published var isCloudKitAvailable = false
    @Published var isSetupComplete = false
    @Published var currentUserRoleCK: UserRoleCK = .student
    
    // Private initializer for singleton
    private init() {
        // Setup observers
        setupObservers()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observe CloudKit availability
        cloudKitService.$isUserSignedIn
            .receive(on: DispatchQueue.main)
            .assign(to: \.isCloudKitAvailable, on: self)
            .store(in: &cancellables)
        
        // Observe current user for role
        userManager.$currentUser
            .compactMap { $0?.role }
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentUserRoleCK, on: self)
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - App Initialization
    
    /// Initialize the app with CloudKit backend
    func initializeApp() async {
        // Check iCloud status first
        await cloudKitService.checkiCloudAccountStatus()
        
        if cloudKitService.isUserSignedIn {
            // Request necessary permissions
            await cloudKitService.requestApplicationPermission()
            
            // Fetch user identity
            await cloudKitService.fetchUserIdentity()
            
            // Try to fetch current user
            await userManager.fetchCurrentUser()
            
            // If no current user found but we have iCloud identity, create a new user
            if userManager.currentUser == nil && !cloudKitService.userName.isEmpty {
                let success = await userManager.registerUser(
                    name: cloudKitService.userName,
                    email: "\(cloudKitService.userName.lowercased().replacingOccurrences(of: " ", with: "."))@example.com",
                    phone: "123-456-7890",
                    role: .student // Default role
                )
                
                if success {
                    // Fetch the newly created user
                    await userManager.fetchCurrentUser()
                }
            }
            
            // If we have a current user and they're a mentor, load their mentees
            if let currentUser = userManager.currentUser, currentUser.role == .mentor {
                await menteeManager.fetchMyMentees(for: currentUser.id)
            }
            
            // Load all mentees for admin or to display in "All Mentees"
            await menteeManager.fetchAllMentees()
        }
        
        // Mark setup as complete
        DispatchQueue.main.async {
            self.isSetupComplete = true
        }
        
        /// Reset all managers (for logout)
            func resetAll() {
                attendanceManager.reset()
                menteeManager.reset()
                userManager.reset()
            }
            
            /// Log in a registered user from device registration
            func loginRegisteredUser(_ user: UserCK) async {
                DispatchQueue.main.async {
                    self.userManager.currentUser = user
                }
                
                // Additional setup for the logged-in user
                if user.role == .mentor {
                    await menteeManager.fetchMyMentees(for: user.id)
                }
                
                // Load attendance records
                await attendanceManager.fetchAttendanceRecords(for: user.id)
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
    
    // MARK: - Clock In/Out Integration
    
    /// Verify the attendance code
    func verifyAttendanceCode(code: String) async -> Bool {
        // Implement the verification logic
        return attendanceManager.verifyAttendanceCode(code: code)
    }
    
    /// Handle QR Code scan
    func handleQRCodeScan(code: String) async -> Bool {
        guard let currentUser = userManager.currentUser else { return false }
        
        // Verify the code
        if attendanceManager.verifyAttendanceCode(code: code) {
            // If valid, clock in the user
            return await attendanceManager.clockIn(menteeID: currentUser.id)
        }
        
        return false
    }
    
    /// Clock in the current user
    func clockInCurrentUser() async -> Bool {
        // Ensure we have a current user
        guard let currentUser = userManager.currentUser else {
            print("No current user found")
            return false
        }
        
        // Attempt to clock in the user
        return await attendanceManager.clockIn(menteeID: currentUser.id)
    }
    
    /// Clock out the current user
    func clockOutCurrentUser() async -> Bool {
        // Attempt to clock out
        return await attendanceManager.clockOut()
    }
    
    // MARK: - Attendance Management
    
    /// Load attendance for the current user
    func loadCurrentUserAttendance() async {
        guard let currentUser = userManager.currentUser else { return }
        
        await attendanceManager.fetchAttendanceRecords(for: currentUser.id)
    }
    
    /// Load attendance for a specific mentee
    func loadMenteeAttendance(menteeID: UUID) async {
        await attendanceManager.fetchAttendanceRecords(for: menteeID)
    }
    
    /// Load attendance for the current month
    func loadCurrentMonthAttendance() async {
        let calendar = Calendar.current
        let now = Date()
        
        // Get start and end of the current month
        let components = calendar.dateComponents([.year, .month], from: now)
        guard let startOfMonth = calendar.date(from: components),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return
        }
        
        await attendanceManager.fetchAttendanceRecords(from: startOfMonth, to: endOfMonth)
    }
    
    // MARK: - Mentee Management Integration
    
    /// Add a mentee to the current user (if mentor)
    func addMenteeToCurrentUser(_ mentee: MenteeCK) async -> Bool {
        guard let currentUser = userManager.currentUser, currentUser.role == .mentor else {
            return false
        }
        
        return await menteeManager.addToMyMentees(mentee, monitorID: currentUser.id)
    }
    
    /// Remove a mentee from the current user
    func removeMenteeFromCurrentUser(_ mentee: MenteeCK) async -> Bool {
        return await menteeManager.removeFromMyMentees(mentee)
    }
    
    // MARK: - User Management Integration
    
    /// Update the current user's vacation days
    func declareVacationDays(startDate: Date, endDate: Date) async -> Bool {
        return await userManager.declareVacationDays(startDate: startDate, endDate: endDate)
    }
    
    /// Check if user is signed in and setup is complete
    var isReady: Bool {
        return isCloudKitAvailable && isSetupComplete
    }
    
    /// Reset all managers (for logout)
    func resetAll() {
        attendanceManager.reset()
        menteeManager.reset()
        userManager.reset()
    }
}
