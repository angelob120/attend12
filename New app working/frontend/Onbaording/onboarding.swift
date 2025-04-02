//
//  OnboardingView.swift
//  New app working
//
//  Created by AB on 1/9/25.
//  Updated with completion handler for one-way navigation

import SwiftUI
import CloudKit

// UserData observable object to store and share user information
class UserData: ObservableObject {
    @Published var fullName: String = ""
    @Published var email: String = ""
    @Published var mentorName: String = ""
    @Published var vacationDays: Int = 96 // Default value
    
    // Singleton pattern for global access
    static let shared = UserData()
    
    private init() {
        // Load data from UserDefaults if available
        if let fullName = UserDefaults.standard.string(forKey: "userFullName") {
            self.fullName = fullName
        }
        if let email = UserDefaults.standard.string(forKey: "userEmail") {
            self.email = email
        }
        if let mentorName = UserDefaults.standard.string(forKey: "userMentorName") {
            self.mentorName = mentorName
        }
        self.vacationDays = UserDefaults.standard.integer(forKey: "userVacationDays")
        if self.vacationDays == 0 {
            self.vacationDays = 96 // Set default if not previously saved
        }
    }
    
    // Save user data to UserDefaults
    func saveUserData() {
        UserDefaults.standard.set(fullName, forKey: "userFullName")
        UserDefaults.standard.set(email, forKey: "userEmail")
        UserDefaults.standard.set(mentorName, forKey: "userMentorName")
        UserDefaults.standard.set(vacationDays, forKey: "userVacationDays")
    }
}

struct OnboardingView: View {
    // MARK: - User Inputs
    @StateObject private var userData = UserData.shared
    @State private var phone: String = ""
    @State private var classCode: String = ""
    
    // Device-specific unique identifier
    private let deviceUUID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    
    // State for UI
    @State private var registrationError: String?
    @State private var isRegistering = false
    
    // Environment object for CloudKit configuration
    @EnvironmentObject var cloudKitConfig: CloudKitAppConfig
    
    // Completion handler to notify when onboarding is complete
    var onboardingComplete: (UserCK) -> Void
    
    // Form validation
    var isFormValid: Bool {
        !userData.fullName.isEmpty && !userData.email.isEmpty && !userData.mentorName.isEmpty && !classCode.isEmpty
    }
    
    var body: some View {
        // No NavigationView to prevent back button
        VStack {
            // Header
            HStack {
                Spacer()
                Text("Welcome")
                    .font(.title)
                    .bold()
                    .foregroundColor(Color.customGreen)
                Spacer()
            }
            .padding(.top, 50)
            .padding(.bottom, 20)
            
            // Form fields in ScrollView for better handling on smaller devices
            ScrollView {
                VStack(spacing: 20) {
                    // Personal Information
                    GroupBox(label: Text("Personal Information").bold()) {
                        VStack(alignment: .leading, spacing: 15) {
                            CustomTextField(title: "Full Name", text: $userData.fullName)
                                .autocapitalization(.words)
                                .disableAutocorrection(true)
                            
                            CustomTextField(title: "Email", text: $userData.email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                            
                            CustomTextField(title: "Phone Number", text: $phone)
                                .keyboardType(.phonePad)
                            
                            CustomTextField(title: "Mentor Name", text: $userData.mentorName)
                                .autocapitalization(.words)
                                .disableAutocorrection(true)
                        }
                        .padding()
                    }
                    .padding(.horizontal)
                    
                    // Class Code
                    GroupBox(label: Text("Class Information").bold()) {
                        VStack(alignment: .leading, spacing: 15) {
                            CustomTextField(title: "Class Code", text: $classCode)
                                .autocapitalization(.allCharacters)
                                .disableAutocorrection(true)
                        }
                        .padding()
                    }
                    .padding(.horizontal)
                    
                    // Error Message
                    if let error = registrationError {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    // Submit Button
                    Button(action: submitData) {
                        if isRegistering {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Registering...")
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.customGreen)
                            .cornerRadius(10)
                            .padding(.horizontal)
                        } else {
                            Text("Submit")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isFormValid ? Color.customGreen : Color.gray)
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                    }
                    .disabled(!isFormValid || isRegistering)
                    
                    Spacer(minLength: 50)
                }
                .padding(.vertical)
            }
        }
        .background(Color(.systemBackground))
        .edgesIgnoringSafeArea(.all)
    }
    
    // MARK: - Actions
    private func submitData() {
        // Save user data to UserDefaults
        userData.saveUserData()
        
        // Set registration in progress
        isRegistering = true
        
        Task {
            do {
                // Create a new user in CloudKit with device UUID
                let newUser = UserCK(
                    name: userData.fullName,
                    email: userData.email,
                    phone: phone,
                    role: .student,
                    status: .active, // Set as active to skip approval process
                    vacationDays: userData.vacationDays,
                    timeOffBalance: Double(userData.vacationDays * 8) // 8 hours per day
                )
                
                // Add device UUID and mentor name to the user record
                if let record = newUser.record {
                    record["deviceUUID"] = deviceUUID
                    record["mentorName"] = userData.mentorName
                    
                    // Add class code for reference
                    record["classCode"] = classCode
                }
                
                // Save user to CloudKit
                let savedUser = try await CloudKitService.shared.saveUser(newUser)
                
                // Mark registration as complete using the completion handler
                DispatchQueue.main.async {
                    isRegistering = false
                    onboardingComplete(savedUser)
                }
            } catch {
                // Handle registration error
                DispatchQueue.main.async {
                    isRegistering = false
                    registrationError = "Registration failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

// Custom styled text field
struct CustomTextField: View {
    var title: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color.customGreen)
            
            TextField(title, text: $text)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.customGreen, lineWidth: 1)
                )
                .padding(.bottom, 5)
        }
    }
}

// MARK: - Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(onboardingComplete: { _ in })
            .environmentObject(CloudKitAppConfig.shared)
    }
}
