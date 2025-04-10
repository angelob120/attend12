//
//  AdminDashboardView.swift
//  New app working
//
//  Created by AB on 1/9/25.
//  Updated to use separated components

import SwiftUI

struct AdminMentorRow: View {
    let user: AppUser1
    
    var body: some View {
        HStack {
            Image(systemName: "person.2.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .foregroundColor(.green)
            
            VStack(alignment: .leading) {
                Text(user.name)
                    .font(.headline)
                
                // You can customize this further, perhaps adding the number of students or email
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 10)
            
            Spacer()
            
            // Indicator for admin to manage this mentor
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 6)
    }
}

struct AdminDashboardView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var searchText: String = ""
    @StateObject private var userManager = CustomUserManager()
    @State private var isPresentingAddUserSheet = false
    @State private var isPresentingManageRolesSheet = false
    @State private var selectedTab: String = "All Students"  // Default tab
    
    // State for navigation
    @State private var selectedUser: AppUser1?
    @State private var selectedMentor: AppUser1?
    @State private var navigateToMentorDetail = false
    @State private var selectedEvent: Event?
    
    // Filter users based on search text and selected tab
    var filteredUsers: [AppUser1] {
        // First, filter by role
        let roleFilteredUsers: [AppUser1]
        if selectedTab == "All Students" {
            roleFilteredUsers = userManager.allUsers.filter { $0.role == "Student" }
        } else {
            roleFilteredUsers = userManager.allUsers.filter { $0.role == "Mentor" }
        }
        
        // Then, filter by search text if needed
        if searchText.isEmpty {
            return roleFilteredUsers
        } else {
            return roleFilteredUsers.filter { user in
                user.name.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // MARK: - Events Section
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(Event.sampleData) { event in
                            EventRow(event: event)
                                .onTapGesture {
                                    selectedEvent = event
                                }
                        }
                    }
                    .padding()
                }
                .sheet(item: $selectedEvent) { event in
                    event.detailView
                }
                
                // MARK: - Search Bar with Custom Green Outline
                TextField("Search \(selectedTab)...", text: $searchText)
                    .padding(10)
                    .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.customGreen, lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .padding(.top)
                
                // MARK: - User List
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(filteredUsers, id: \.id) { user in
                            if selectedTab == "All Students" {
                                // For students, show a sheet with details
                                Button {
                                    selectedUser = user
                                } label: {
                                    UserRow(user: user)
                                        .padding(.vertical, 8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else {
                                // For mentors, navigate to the mentor detail view
                                Button {
                                    selectedMentor = user
                                    navigateToMentorDetail = true
                                } label: {
                                    AdminMentorRow(user: user)
                                        .padding(.vertical, 8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            Divider()
                        }
                    }
                    .padding(.horizontal)
                }

                // MARK: - Tab Bar for "All Students" and "All Mentors" with Consistent Styling
                HStack {
                    Button(action: {
                        selectedTab = "All Students"
                        searchText = "" // Clear search when switching tabs
                    }) {
                        Text("All Students")
                            .fontWeight(selectedTab == "All Students" ? .bold : .regular)
                            .foregroundColor(selectedTab == "All Students" ? .white : .primary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                selectedTab == "All Students" ?
                                Color.customGreen :
                                (colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.customGreen, lineWidth: 1)
                            )
                            .cornerRadius(10)
                    }

                    Button(action: {
                        selectedTab = "All Mentors"
                        searchText = "" // Clear search when switching tabs
                    }) {
                        Text("All Mentors")
                            .fontWeight(selectedTab == "All Mentors" ? .bold : .regular)
                            .foregroundColor(selectedTab == "All Mentors" ? .white : .primary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                selectedTab == "All Mentors" ?
                                Color.customGreen :
                                (colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.customGreen, lineWidth: 1)
                            )
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.bottom)
            .background(colorScheme == .dark ? Color.black : Color(.systemBackground))
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
            .background(
                // Navigation link for mentor detail
                NavigationLink(
                    destination: mentorDetailDestination,
                    isActive: $navigateToMentorDetail,
                    label: { EmptyView() }
                )
            )
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
    
    // MARK: - Navigation Destinations
    
    // Extract the mentor detail destination to simplify the code
    @ViewBuilder
    private var mentorDetailDestination: some View {
        if let mentor = selectedMentor {
            AdminMentorDetailView(mentor: mentor)
                .environmentObject(userManager)
        } else {
            Text("No mentor selected")
        }
    }
}

// MARK: - UserRow View (for Students)
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
            
            // Chevron indicator
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Preview
struct AdminDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        AdminDashboardView()
            .environmentObject(CloudKitAppConfig.shared)
    }
}
