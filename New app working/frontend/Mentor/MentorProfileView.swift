//
//  MentorProfileView.swift
//  New app working
//
//  Created by AB on 1/9/25.
//

import SwiftUI


struct MentorProfileView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab: String = "My Mentees"  // Default tab
    @State private var searchText: String = ""             // Search text
    @StateObject private var menteeManager = MenteeManager()  // Shared data manager

    // Filter mentees based on search text and selected tab
    var filteredMentees: [Mentee] {
        let menteesToFilter = selectedTab == "My Mentees" ? menteeManager.myMentees : menteeManager.allMentees
        if searchText.isEmpty {
            return menteesToFilter
        } else {
            return menteesToFilter.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }

    var body: some View {
        NavigationView {
            VStack {
                // MARK: - Search Bar with Custom Green Outline, adapts to Light/Dark Mode
                TextField("Search Mentees...", text: $searchText)
                    .padding(10)
                    .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.customGreen, lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .padding(.top)

                // MARK: - Mentee List (Original Style) that adapts to Light/Dark Mode
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(filteredMentees) { mentee in
                            NavigationLink(destination: MenteeDetailView(mentee: mentee)
                                            .environmentObject(menteeManager)) {
                                MenteeRow(mentee: mentee)
                            }
                            Divider()
                        }
                    }
                    .padding(.horizontal)
                }

                // MARK: - Tab Bar for "My Mentees" and "All Mentees" with Consistent Styling
                HStack {
                    Button(action: {
                        selectedTab = "My Mentees"
                    }) {
                        Text("My Mentees")
                            .fontWeight(selectedTab == "My Mentees" ? .bold : .regular)
                            .foregroundColor(selectedTab == "My Mentees" ? .white : .primary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                selectedTab == "My Mentees" ?
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
                        selectedTab = "All Mentees"
                    }) {
                        Text("All Mentees")
                            .fontWeight(selectedTab == "All Mentees" ? .bold : .regular)
                            .foregroundColor(selectedTab == "All Mentees" ? .white : .primary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                selectedTab == "All Mentees" ?
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
                    Text("Mentor Dashboard")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                // Left: Plus Symbol for Adding New Events
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: AddEventView()) {
                        Image(systemName: "plus")
                            .foregroundColor(Color.iconColor)
                    }
                }
                // Right: Notifications (bell) icon
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: NotificationsView()) {
                        Image(systemName: "bell")
                            .foregroundColor(Color.iconColor)
                    }
                }
            }
        }
        .environmentObject(menteeManager)
    }
}

// Stub view for AddEventView (customize as needed)
struct AddEventView: View {
    var body: some View {
        Text("Add New Event")
            .font(.largeTitle)
            .padding()
    }
}
