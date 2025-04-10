//
//  New_app_workingApp.swift
//  New app working
//
//  Created by AB on 1/9/25.
//  Updated for onboarding flow with role switcher tab
//

import SwiftUI

@main
struct New_app_workingApp: App {
    // Add the app delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // Shared CloudKit configuration
    @StateObject private var cloudKitConfig = CloudKitAppConfig.shared
    
    // Create a separate CustomUserManager for environment injection
    @StateObject private var userManager = CustomUserManager()
    
    // States for app flow
    @State private var isCheckingAuth = true
    @State private var needsOnboarding = true  // Set to true to show onboarding first
    
    // Device UUID for account matching
    private let deviceUUID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isCheckingAuth {
                    // Show loading view while checking authentication
                    LoadingView()
                        .environmentObject(cloudKitConfig)
                        .environmentObject(userManager)
                        .onAppear {
                            checkDeviceAuthentication()
                        }
                } else if needsOnboarding {
                    // Show onboarding first
                    OnboardingView(onboardingComplete: { user in
                        // Set the completed user and mark onboarding as done
                        userManager.allUsers.append(user.toAppModel())
                        needsOnboarding = false
                    })
                    .environmentObject(cloudKitConfig)
                    .environmentObject(userManager)
                    .transition(.opacity)
                    .animation(.easeInOut, value: needsOnboarding)
                } else {
                    // Show the StudentDashboardView with role switcher tab
                    MainTabView()
                        .environmentObject(cloudKitConfig)
                        .environmentObject(userManager)
                        .transition(.opacity)
                        .animation(.easeInOut, value: needsOnboarding)
                }
            }
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
                        userManager.allUsers.append(user.toAppModel())
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

// Main tab view with Dashboard and Role Switcher
struct MainTabView: View {
    @EnvironmentObject var cloudKitConfig: CloudKitAppConfig
    @EnvironmentObject var userManager: CustomUserManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // First tab - Dashboard
            StudentDashboardView()
                .tag(0)
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
            
            // Second tab - Role Switcher
            RoleSwitcherView()
                .tag(1)
                .tabItem {
                    Label("Roles", systemImage: "person.3.fill")
                }
        }
    }
}

// Role Switcher View
struct RoleSwitcherView: View {
    @EnvironmentObject var cloudKitConfig: CloudKitAppConfig
    @EnvironmentObject var userManager: CustomUserManager
    @State private var showView: String? = nil
    
    // Role options
    let roleOptions: [(name: String, icon: String, color: Color, viewType: String)] = [
        ("Student", "graduationcap.fill", .blue, "student"),
        ("Mentor", "person.2.fill", .green, "mentor"),
        ("Admin", "shield.fill", .red, "admin"),
        ("iPad", "display.fill", .orange, "ipad"),
        ("Test", "hammer.fill", .purple, "test")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Switch Role")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    // Role buttons
                    ForEach(roleOptions, id: \.viewType) { role in
                        Button(action: {
                            switchToRole(role.viewType)
                        }) {
                            HStack {
                                Image(systemName: role.icon)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(role.color)
                                    .clipShape(Circle())
                                
                                Text(role.name)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .padding(.leading, 10)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(15)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
                .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            }
            .navigationBarTitle("Role Switcher", displayMode: .inline)
            .background(
                Group {
                    if let showView = showView {
                        NavigationLink(
                            destination: destinationView(for: showView),
                            isActive: Binding(
                                get: { self.showView != nil },
                                set: { if !$0 { self.showView = nil } }
                            )
                        ) {
                            EmptyView()
                        }
                    }
                }
            )
        }
    }
    
    private func switchToRole(_ role: String) {
        // Set the role in CloudKitConfig if needed
        switch role {
        case "admin":
            cloudKitConfig.currentUserRoleCK = .admin
        case "mentor":
            cloudKitConfig.currentUserRoleCK = .mentor
        case "student":
            cloudKitConfig.currentUserRoleCK = .student
        default:
            break
        }
        // Navigate to the selected view
        self.showView = role
    }
    
    @ViewBuilder
    private func destinationView(for role: String) -> some View {
        switch role {
        case "student":
            StudentDashboardView()
        case "mentor":
            MentorProfileView()
        case "admin":
            AdminDashboardView()
        case "ipad":
            iPadDashboardView()
        case "test":
            TestView()
        default:
            Text("Invalid Selection")
        }
    }
}

