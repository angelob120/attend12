//
//  AdminDashboardView.swift
//  New app working
//
//  Created by AB on 1/9/25.
//

import SwiftUI

// MARK: - Custom Color Extensions (Shared with other Views

struct AdminDashboardView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var searchText: String = ""
    @StateObject private var userManager = CustomUserManager()
    @State private var isPresentingAddUserSheet = false
    @State private var isPresentingManageRolesSheet = false
    
    // State to hold which user we want to show in a sheet
    @State private var selectedUser: AppUser1?
    
    // Filter users based on search text
    var filteredUsers: [AppUser1] {
        if searchText.isEmpty {
            return userManager.allUsers
        } else {
            return userManager.allUsers.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // MARK: - Search Bar that adapts to Light/Dark Mode
                TextField("Search Users...", text: $searchText)
                    .padding(10)
                    .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top)
                
                // MARK: - User List (Original Style)
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(filteredUsers, id: \.id) { user in
                            // Tap to set `selectedUser`, triggering a sheet
                            Button {
                                selectedUser = user
                            } label: {
                                UserRow(user: user)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            // MARK: - iOS 16+ NavBar Background Styling
            .toolbarBackground(Color.customGreen, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            // MARK: - NavBar Items
            .toolbar {
                // Centered Title
                ToolbarItem(placement: .principal) {
                    Text("Admin Dashboard")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                // Left: Plus symbol to add a new user
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isPresentingAddUserSheet.toggle()
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(Color.iconColor)
                    }
                }
                // Right: Manage Roles Button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isPresentingManageRolesSheet.toggle()
                    }) {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(Color.iconColor)
                    }
                }
            }
        }
        // MARK: - Sheet Presentations
        .sheet(isPresented: $isPresentingAddUserSheet) {
            AddUserView(userManager: userManager)
        }
        .sheet(isPresented: $isPresentingManageRolesSheet) {
            ManageRolesView(userManager: userManager)
        }
        .sheet(item: $selectedUser) { user in
            UserDetailView(user: user)
        }
    }
}

// MARK: - UserRow View (Unchanged)
struct UserRow: View {
    let user: AppUser1

    var body: some View {
        HStack {
            Image(systemName: "person.crop.circle")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.gray)

            VStack(alignment: .leading) {
                Text(user.name)
                    .font(.headline)
                Text(user.status)
                    .font(.subheadline)
                    .foregroundColor(user.status == "Active" ? .green : .red)
            }
            Spacer()
        }
    }
}

// MARK: - Preview
struct AdminDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        AdminDashboardView()
    }
}
