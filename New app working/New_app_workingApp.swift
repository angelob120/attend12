//
//  New_app_workingApp.swift
//  New app working
//
//  Created by AB on 1/9/25.
//  Updated with one-way onboarding navigation

import SwiftUI

@main
struct New_app_workingApp: App {
    // Add the app delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // Environment Objects
    @StateObject private var cloudKitConfig = CloudKitAppConfig.shared
    
    // State for app flow
    @State private var isCheckingAuth = true
    @State private var needsOnboarding = true
    
    // Get current role from CloudKitAppConfig
    private var currentRole: String {
        cloudKitConfig.mapToAppUserRole()
    }
    
    // Device UUID for account matching
    private let deviceUUID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isCheckingAuth {
                    // Show loading view while checking authentication
                    LoadingView()
                        .environmentObject(cloudKitConfig)
                        .onAppear {
                            checkDeviceAuthentication()
                        }
                } else if needsOnboarding {
                    // Show onboarding if needed
                    // Using ZStack prevents showing navigation back button
                    OnboardingView(onboardingComplete: { user in
                        // Set the completed user and mark onboarding as done
                        cloudKitConfig.userManager.currentUser = user
                        needsOnboarding = false
                    })
                    .environmentObject(cloudKitConfig)
                    .transition(.opacity)
                    .animation(.easeInOut, value: needsOnboarding)
                } else {
                    // User is authenticated, show appropriate dashboard
                    mainContent
                        .transition(.opacity)
                        .animation(.easeInOut, value: needsOnboarding)
                }
            }
        }
    }
    
    // Main app content based on user role
    @ViewBuilder
    private var mainContent: some View {
        switch currentRole {
        case "admin":
            AdminDashboardView()
                .environmentObject(cloudKitConfig)
        case "mentor":
            MentorProfileView()
                .environmentObject(cloudKitConfig)
        default:
            StudentDashboardView()
                .environmentObject(cloudKitConfig)
        }
    }
    
    init() {
        // Configure CloudKit during app startup
        configureCloudKit()
    }
    
    // Check if device UUID matches an existing user in CloudKit
    private func checkDeviceAuthentication() {
        Task {
            do {
                // Wait for CloudKit to be ready
                while !cloudKitConfig.isReady {
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                }
                
                // Fetch all users from CloudKit
                let allUsers = try await CloudKitService.shared.fetchAllUsers()
                
                // Look for a user with matching device UUID
                let matchingUser = allUsers.first { user in
                    // Check if user record has a deviceUUID field that matches this device
                    if let record = user.record,
                       let userDeviceUUID = record["deviceUUID"] as? String {
                        return userDeviceUUID == deviceUUID
                    }
                    return false
                }
                
                DispatchQueue.main.async {
                    if let user = matchingUser {
                        // Found a matching user, set as current user and skip onboarding
                        cloudKitConfig.userManager.currentUser = user
                        needsOnboarding = false
                        
                        // Load any existing user data if available
                        if let userName = user.record?["name"] as? String {
                            UserData.shared.fullName = userName
                        }
                        if let userEmail = user.record?["email"] as? String {
                            UserData.shared.email = userEmail
                        }
                        if let mentorName = user.record?["mentorName"] as? String {
                            UserData.shared.mentorName = mentorName
                        }
                        UserData.shared.vacationDays = user.vacationDays
                        
                        // Save to UserDefaults for future reference
                        UserData.shared.saveUserData()
                    } else {
                        // No matching user found, needs onboarding
                        needsOnboarding = true
                    }
                    
                    // Authentication check completed
                    isCheckingAuth = false
                }
            } catch {
                // Handle error - if we can't access CloudKit, default to requiring onboarding
                print("Error checking device authentication: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    needsOnboarding = true
                    isCheckingAuth = false
                }
            }
        }
    }
}
