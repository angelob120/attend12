//
//  ContentView.swift
//  New app working
//
//  Created by AB on 11/1/24.
//

import SwiftUI

enum UserRole: String, CaseIterable {
    case student
    case mentor
    case admin
    case ipad
    case onboarding
    case test
    
    // Helper for icon name
    var iconName: String {
        switch self {
        case .student: return "graduationcap.fill"
        case .mentor: return "person.2.fill"
        case .admin: return "shield.fill"
        case .ipad: return "display.fill"
        case .onboarding: return "person.badge.plus.fill"
        case .test: return "hammer.fill"
        }
    }
    
    // Helper for display name
    var displayName: String {
        return self.rawValue.capitalized
    }
    
    // Helper for role color
    var color: Color {
        switch self {
        case .student: return .blue
        case .mentor: return .green
        case .admin: return .red
        case .ipad: return .orange
        case .onboarding: return .purple
        case .test: return .pink
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var cloudKitConfig: CloudKitAppConfig
    @State private var selectedRole: UserRole = .student  // Default role

    var body: some View {
        TabView(selection: $selectedRole) {
            // Create a tab for each role
            ForEach(UserRole.allCases, id: \.self) { role in
                roleView(for: role)
                    .tabItem {
                        Label(role.displayName, systemImage: role.iconName)
                    }
                    .tag(role)
            }
        }
        .accentColor(.blue)
        .onAppear {
            // Set the initial role based on CloudKit user role
            updateRoleFromCloudKit()
        }
    }
    
    private func updateRoleFromCloudKit() {
        let roleString = cloudKitConfig.mapToAppUserRole()
        switch roleString {
        case "admin":
            selectedRole = .admin
        case "mentor":
            selectedRole = .mentor
        case "student":
            selectedRole = .student
        default:
            // Keep the default role
            break
        }
    }
    
    @ViewBuilder
    private func roleView(for role: UserRole) -> some View {
        switch role {
        case .student:
            StudentDashboardView()
        case .mentor:
            MentorProfileView()
        case .admin:
            AdminDashboardView()
        case .onboarding:
            // We should never reach here since onboarding is handled at the app level
            // But just in case, include a proper implementation
            OnboardingView(onboardingComplete: { user in
                // Update the role based on the completed user
                if let role = user.record?["role"] as? String {
                    switch role {
                    case "admin":
                        selectedRole = .admin
                    case "mentor":
                        selectedRole = .mentor
                    default:
                        selectedRole = .student
                    }
                } else {
                    selectedRole = .student
                }
            })
        case .ipad:
            iPadDashboardView()
        case .test:
            TestView()
        }
    }
}

// Status Banner to show at top of each role view
struct RoleStatusBanner: View {
    let role: UserRole
    
    var body: some View {
        HStack {
            Circle()
                .fill(role.color)
                .frame(width: 12, height: 12)
            
            Text("Active Role: \(role.displayName)")
                .font(.caption)
                .bold()
                .foregroundColor(role.color)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(role.color.opacity(0.1))
    }
}

// Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(CloudKitAppConfig.shared)
    }
}
