//
//  ProfileView.swift
//  New app working
//
//  Created by AB on 1/9/25.
//  Updated to properly navigate to individual policy views
//

import SwiftUI

struct ProfileView: View {
    // Use the shared UserData to display user information
    @ObservedObject private var userData = UserData.shared
    @EnvironmentObject var cloudKitConfig: CloudKitAppConfig
    
    // Example state for toggles, etc.
    @State private var alertPopupsOn = true
    @State private var emailNotificationsOn = true
    @State private var soundNotificationsOn = true
    
    // Current date formatter helper function
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: Date())
    }
    
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
                    
                    // Text Section on the Right - Now displays data from shared UserData
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Name")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(userData.fullName.isEmpty ? "Not Set" : userData.fullName)
                            .font(.title3)
                            .bold()
                            .foregroundColor(.primary)
                        
                        Text("Mentor")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(userData.mentorName.isEmpty ? "Not Assigned" : userData.mentorName)
                            .font(.title3)
                            .bold()
                            .foregroundColor(.primary)
                        
                        Text("Vacation Time")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("\(userData.vacationDays) Days")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.primary)
                    }
                }
                .padding(.top, 20)
                
                // MARK: - SETTINGS SECTIONS (Custom Green Boxes, White Text)
                
                // PERSONAL INFORMATION
                SettingsSectionView(title: "Personal Information") {
                    SettingsRow(iconName: "person.fill", text: userData.fullName.isEmpty ? "Not Set" : userData.fullName)
                    SettingsRow(iconName: "envelope.fill", text: userData.email.isEmpty ? "Not Set" : userData.email)
                    SettingsRow(iconName: "phone.fill", text: cloudKitConfig.userProfile.phone.isEmpty ? "Not Set" : cloudKitConfig.userProfile.phone)
                    SettingsRow(iconName: "person.2.fill", text: userData.mentorName.isEmpty ? "Not Assigned" : userData.mentorName, trailingText: "Mentor")
                }
                
                // CLASS INFORMATION
                SettingsSectionView(title: "Class Information") {
                    SettingsRow(iconName: "graduationcap.fill", text: cloudKitConfig.userProfile.classType.isEmpty ? "Regular Class" : cloudKitConfig.userProfile.classType)
                    SettingsRow(iconName: "clock.fill", text: cloudKitConfig.userProfile.timeSlot.isEmpty ? "AM" : cloudKitConfig.userProfile.timeSlot, trailingText: "Session")
                    SettingsRow(iconName: "number", text: cloudKitConfig.userProfile.classCode.isEmpty ? "Not Set" : cloudKitConfig.userProfile.classCode, trailingText: "Code")
                }
                
                // TIME OFF
                SettingsSectionView(title: "Time Off") {
                    SettingsRow(iconName: "calendar.badge.clock", text: "\(userData.vacationDays) Days Remaining")
                    SettingsRow(iconName: "clock.arrow.circlepath", text: "\(userData.vacationDays * 8) Hours Total")
                    NavigationLink(destination: DetailedAttendanceListView()) {
                        SettingsRow(iconName: "list.bullet.clipboard", text: "View Time Off History", trailingImage: "chevron.right")
                    }
                }
                
                // ACCOUNT STATUS
                SettingsSectionView(title: "Account Status") {
                    SettingsRow(iconName: "person.badge.shield.checkmark", text: "Active", trailingText: Date().formatted(date: .abbreviated, time: .omitted))
                    SettingsRow(iconName: "calendar", text: formattedDate())
                    SettingsRow(iconName: "checklist",
                               text: cloudKitConfig.userProfile.onboardingComplete ? "Onboarding Complete" : "Onboarding In Progress")
                }
                
                // NOTIFICATIONS
                SettingsSectionView(title: "Notifications") {
                    ToggleSettingsRow(iconName: "bell.fill",
                                      text: "Alert pop-ups",
                                      isOn: $alertPopupsOn)
                    ToggleSettingsRow(iconName: "envelope.fill",
                                     text: "Email notifications",
                                     isOn: $emailNotificationsOn)
                    ToggleSettingsRow(iconName: "speaker.wave.2.fill",
                                     text: "Sound notifications",
                                     isOn: $soundNotificationsOn)
                }
                
                // ABOUT
                SettingsSectionView(title: "About") {
                    // Updated to use dedicated view files
                    NavigationLink(destination: StudentCodeOfConductView()) {
                        SettingsRow(iconName: "doc.text.fill",
                                    text: "Student Code of Conduct",
                                    trailingImage: "chevron.right")
                    }
                    NavigationLink(destination: PrivacyPolicyView()) {
                        SettingsRow(iconName: "hand.raised.fill",
                                   text: "Privacy Policy",
                                   trailingImage: "chevron.right")
                    }
                    NavigationLink(destination: TermsOfServiceView()) {
                        SettingsRow(iconName: "doc.plaintext.fill",
                                   text: "Terms of Service",
                                   trailingImage: "chevron.right")
                    }
                }
                
                // SIGN OUT Button
                Button(action: {
                    // Sign out action
                    cloudKitConfig.resetAll()
                }) {
                    Text("Sign Out")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding(.top)
                .padding(.horizontal)
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

// MARK: - Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView()
                .environmentObject(CloudKitAppConfig.shared)
        }
    }
}
