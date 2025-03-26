//
//  ProfileView.swift
//  New app working
//
//  Created by AB on 1/9/25.
//

import SwiftUI

struct ProfileView: View {
    // Example state for toggles, etc.
    @State private var alertPopupsOn = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // MARK: - TOP PROFILE HEADER
                HStack(alignment: .center, spacing: 20) {
                    
                    // Profile Image + Icons Overlay
                    ZStack {
                        // Green Circle Stroke
                        Circle()
                            .stroke(Color.customGreen, lineWidth: 4)
                            .frame(width: 140, height: 140)
                        
                        // Main Profile Image (replace with a real photo if desired)
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 130, height: 130)
                            .clipShape(Circle())
                        
                        // Two small icons at the bottom of the circle
                        VStack {
                            Spacer()
                            HStack(spacing: 10) {
                                Button(action: {
                                    // Camera action
                                }) {
                                    Image(systemName: "camera.fill")
                                        .foregroundColor(.white)
                                        .padding(6)
                                        .background(Color.customGreen)
                                        .clipShape(Circle())
                                }
                                Button(action: {
                                    // Edit action
                                }) {
                                    Image(systemName: "face.smiling.fill")
                                        .foregroundColor(.white)
                                        .padding(6)
                                        .background(Color.customGreen)
                                        .clipShape(Circle())
                                }
                            }
                            .padding(.bottom, 6)
                        }
                        .frame(width: 140, height: 140) // Match circle size
                    }
                    
                    // Text Section on the Right
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Name")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("Angelo Brown")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.primary)
                        
                        Text("Mentor")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("Marcus W.")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.primary)
                        
                        Text("Vacation Time")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("96 Days")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.primary)
                    }
                }
                .padding(.top, 20)
                
                // MARK: - SETTINGS SECTIONS (Custom Green Boxes, White Text)
                
                // GENERAL
                SettingsSectionView(title: "General") {
                    SettingsRow(iconName: "person.fill", text: "Kyra Gibbs")
                    SettingsRow(iconName: "envelope.fill", text: "kgibbs23@msu.idserve.net")
                    SettingsRow(iconName: "calendar", text: "September 30, 2025")
                }
                
                // NOTIFICATIONS
                SettingsSectionView(title: "Notifications") {
                    ToggleSettingsRow(iconName: "bell.fill",
                                      text: "Alert pop-ups",
                                      isOn: $alertPopupsOn)
                }
                
                // ABOUT
                SettingsSectionView(title: "About") {
                    NavigationLink(destination: StudentCodeOfConductView()) {
                        SettingsRow(iconName: "doc.text.fill",
                                    text: "Student Code of Conduct",
                                    trailingImage: "chevron.right")
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
    }
}

// MARK: - SettingsSectionView
/// A container for each "section" (like "General," "Notifications," etc.),
/// with a custom green background, custom green outline, and white text.
struct SettingsSectionView<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            content
        }
        .padding()
        .background(Color.customGreen)  // Changed from white to custom green
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.customGreen, lineWidth: 1)
        )
        .cornerRadius(10)
    }
}

// MARK: - SettingsRow
/// A single row with an icon, main text, and optional trailing text or icon.
/// All elements are displayed in white.
struct SettingsRow: View {
    let iconName: String
    let text: String
    var trailingText: String? = nil
    var trailingImage: String? = nil
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(.white) // Changed from customGreen to white
            Text(text)
                .foregroundColor(.white) // Changed from customGreen to white
            Spacer()
            
            if let trailingText = trailingText {
                Text(trailingText)
                    .foregroundColor(.white)
            }
            if let trailingImage = trailingImage {
                Image(systemName: trailingImage)
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - ToggleSettingsRow
/// A row with an icon, text, and a Toggle on the trailing side,
/// all in white, with the toggle tinted white.
struct ToggleSettingsRow: View {
    let iconName: String
    let text: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(.white) // Changed from customGreen to white
            Text(text)
                .foregroundColor(.white) // Changed from customGreen to white
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.white) // Tinted white for contrast on custom green background
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Example Destination View
struct StudentCodeOfConductView: View {
    var body: some View {
        Text("Student Code of Conduct")
            .font(.title)
            .padding()
            .navigationTitle("Code of Conduct")
    }
}
