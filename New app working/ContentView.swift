//
//  ContentView.swift
//  ATTEn
//
//  Created by AB on 11/1/24.
//


import SwiftUI

enum UserRole {
    case student
    case mentor
    case admin
    case ipad
    case onboarding
    case test
}

struct ContentView: View {
    @EnvironmentObject var cloudKitConfig: CloudKitAppConfig
    @State private var selectedRole: UserRole = .student  // Default role

    var body: some View {
        VStack {
            roleBasedTabView()
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
    private func roleBasedTabView() -> some View {
        TabView {
            switch selectedRole {
            case .student:
                StudentDashboardView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Dashboard")
                    }
            case .mentor:
                MentorProfileView()
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("Profile")
                    }
            case .admin:
                AdminDashboardView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Dashboard")
                    }
            case .onboarding:
                OnboardingView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Dashboard")
                    }
            case .ipad:
                iPadDashboardView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Dashboard")
                    }
            
            case .test:
                TestView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Dashboard")
                    }
            }
            
            
            SwitchRoleView(selectedRole: $selectedRole)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Switch Role")
                }
        
        }
    }
}

struct SwitchRoleView: View {
    @Binding var selectedRole: UserRole
    @EnvironmentObject var cloudKitConfig: CloudKitAppConfig
    
    var body: some View {
        VStack {
            Text("Switch Role")
                .font(.largeTitle)
                .padding()
            
            // Cloud status indicator
            HStack {
                Circle()
                    .fill(cloudKitConfig.isCloudKitAvailable ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                
                Text(cloudKitConfig.isCloudKitAvailable ? "iCloud Connected" : "iCloud Disconnected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 20)
            
            Button("Switch to Student") {
                selectedRole = .student
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Button("Switch to Mentor") {
                selectedRole = .mentor
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Button("Switch to Admin") {
                selectedRole = .admin
            }
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Button("Switch to iPad") {
                selectedRole = .ipad
            }
            .padding()
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Button("Switch to onboarding") {
                selectedRole = .onboarding
            }
            .padding()
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Button("Switch to test") {
                selectedRole = .test
            }
            .padding()
            .background(Color.pink)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
    }
}

// Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(CloudKitAppConfig.shared)
    }
}
