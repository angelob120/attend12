//
//  OnboardingView.swift
//  New app working
//
//  Created by AB on 1/9/25.
//  Updated to be scrollable for better user experience on smaller screens

import SwiftUI
import CloudKit

// UserData observable object to store and share user information
class UserData: ObservableObject {
    @Published var fullName: String = ""
    @Published var email: String = ""
    @Published var mentorName: String = ""
    @Published var phone: String = ""
    @Published var classType: String = "Regular Class"
    @Published var timeSlot: String = "AM"
    @Published var classCode: String = ""
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
        if let phone = UserDefaults.standard.string(forKey: "userPhone") {
            self.phone = phone
        }
        if let classType = UserDefaults.standard.string(forKey: "userClassType") {
            self.classType = classType
        }
        if let timeSlot = UserDefaults.standard.string(forKey: "userTimeSlot") {
            self.timeSlot = timeSlot
        }
        if let classCode = UserDefaults.standard.string(forKey: "userClassCode") {
            self.classCode = classCode
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
        UserDefaults.standard.set(phone, forKey: "userPhone")
        UserDefaults.standard.set(classType, forKey: "userClassType")
        UserDefaults.standard.set(timeSlot, forKey: "userTimeSlot")
        UserDefaults.standard.set(classCode, forKey: "userClassCode")
        UserDefaults.standard.set(vacationDays, forKey: "userVacationDays")
    }
}

struct OnboardingView: View {
    // MARK: - User Inputs
    @StateObject private var userData = UserData.shared
    @State private var classCode: String = ""
    
    // Class Types and Time Slots
    let classTypes = ["Regular Class", "Renaissance Class"]
    let timeSlots = ["AM", "PM"]
    
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
        // Use ScrollView to make the entire content scrollable
        ScrollView {
            VStack(spacing: 20) {
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
                            
                            CustomTextField(title: "Phone Number", text: $userData.phone)
                                .keyboardType(.phonePad)
                            
                            CustomTextField(title: "Mentor Name", text: $userData.mentorName)
                                .autocapitalization(.words)
                                .disableAutocorrection(true)
                        }
                        .padding()
                    }
                    .padding(.horizontal)
                    
                    // Class Information
                    GroupBox(label: Text("Class Information").bold()) {
                        VStack(alignment: .leading, spacing: 15) {
                            // Class Type Picker
                            VStack(alignment: .leading) {
                                Text("Class Type")
                                    .font(.subheadline)
                                    .bold()
                                
                                Picker("Class Type", selection: $userData.classType) {
                                    ForEach(classTypes, id: \.self) { type in
                                        Text(type).tag(type)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                            
                            // Time Slot Picker
                            VStack(alignment: .leading) {
                                Text("Time Slot")
                                    .font(.subheadline)
                                    .bold()
                                
                                Picker("Time Slot", selection: $userData.timeSlot) {
                                    ForEach(timeSlots, id: \.self) { slot in
                                        Text(slot).tag(slot)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                            
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
            .padding()
        }
        .background(Color(.systemBackground))
        .edgesIgnoringSafeArea(.all)
    }
    
    // MARK: - Actions
    private func submitData() {
        // Save the class code
        userData.classCode = classCode
        
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
                    phone: userData.phone,
                    role: .student,
                    status: .active, // Set as active to skip approval process
                    vacationDays: userData.vacationDays,
                    timeOffBalance: Double(userData.vacationDays * 8) // 8 hours per day
                )
                
                // Add additional data to the user record
                if let record = newUser.record {
                    record["deviceUUID"] = deviceUUID
                    record["mentorName"] = userData.mentorName
                    record["classType"] = userData.classType
                    record["timeSlot"] = userData.timeSlot
                    record["classCode"] = classCode
                    record["onboardingComplete"] = true
                }
                
                // Update CloudKit user profile
                cloudKitConfig.userProfile.name = userData.fullName
                cloudKitConfig.userProfile.email = userData.email
                cloudKitConfig.userProfile.mentorName = userData.mentorName
                cloudKitConfig.userProfile.phone = userData.phone
                cloudKitConfig.userProfile.classType = userData.classType
                cloudKitConfig.userProfile.timeSlot = userData.timeSlot
                cloudKitConfig.userProfile.classCode = classCode
                cloudKitConfig.userProfile.onboardingComplete = true
                
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
