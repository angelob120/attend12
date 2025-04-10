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
    
    // New state for showing the add event sheet
    @State private var isPresentingAddEventSheet = false
    @State private var isPresentingNotifications = false

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
                // Events Section
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(Event.sampleData) { event in
                            NavigationLink(destination: EventDetailView(event: event)) {
                                EventRow(event: event)
                            }
                        }
                    }
                    .padding()
                }
                
                // Search Bar with Custom Green Outline
                TextField("Search Mentees...", text: $searchText)
                    .padding(10)
                    .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.customGreen, lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .padding(.top)

                // Mentee List
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

                // Tab Bar for "My Mentees" and "All Mentees"
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
            .toolbarBackground(Color.customGreen, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                // Centered Title
                ToolbarItem(placement: .principal) {
                    Text("Mentor Dashboard")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                // Left: Add Event Button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isPresentingAddEventSheet = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(Color.iconColor)
                    }
                }
                // Right: Notifications Button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isPresentingNotifications = true
                    }) {
                        Image(systemName: "bell")
                            .foregroundColor(Color.iconColor)
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddEventSheet) {
                MentorAddEventView()
            }
            .sheet(isPresented: $isPresentingNotifications) {
                MentorNotificationsView()
            }
        }
        .environmentObject(menteeManager)
    }
}

// Preview
struct MentorProfileView_Previews: PreviewProvider {
    static var previews: some View {
        MentorProfileView()
            .environmentObject(MenteeManager())
    }
}
