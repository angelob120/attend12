//
//  OnboardingView.swift
//  New app working
//
//  Created by AB on 1/9/25.
//

import SwiftUI
import CloudKit

struct OnboardingView: View {
    // MARK: - User Inputs
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var classCode: String = ""
    
    // Device-specific unique identifier
    private let deviceUUID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    
    // State to control navigation
    @State private var registrationComplete = false
    @State private var registrationError: String?
    
    // Environment object for CloudKit configuration
    @EnvironmentObject var cloudKitConfig: CloudKitAppConfig
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Full Name", text: $fullName)
                        .autocapitalization(.words)
                        .disableAutocorrection(true)
                    
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section(header: Text("Class Code")) {
                    TextField("Enter Class Code", text: $classCode)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                }
                
                Section {
                    Button(action: submitData) {
                        Text("Submit")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(fullName.isEmpty || email.isEmpty || classCode.isEmpty)
                }
                
                // Error Message
                if let error = registrationError {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Onboarding")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(Color.customGreen, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .background(
                NavigationLink(
                    destination: ContentView(),
                    isActive: $registrationComplete
                ) {
                    EmptyView()
                }
            )
        }
    }
    
    // MARK: - Actions
    private func submitData() {
        Task {
            do {
                // Create a new user in CloudKit with device UUID
                let newUser = UserCK(
                    name: fullName,
                    email: email,
                    phone: phone,
                    role: .student,
                    status: .pending,
                    vacationDays: 0,
                    timeOffBalance: 0
                )
                
                // Add device UUID to a custom field
                if let record = newUser.record {
                    record["deviceUUID"] = deviceUUID
                }
                
                // Save user to CloudKit
                let savedUser = try await CloudKitService.shared.saveUser(newUser)
                
                // Mark registration as complete
                DispatchQueue.main.async {
                    registrationComplete = true
                }
            } catch {
                // Handle registration error
                DispatchQueue.main.async {
                    registrationError = "Registration failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
