//
//  OnboardingView.swift
//  New app working
//
//  Created by AB on 1/9/25.
//

import SwiftUI

struct OnboardingView: View {
    // MARK: - User Inputs
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var classCode: String = ""
    
    // MARK: - Body
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
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Centered Title
                ToolbarItem(placement: .principal) {
                    Text("Onboarding")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(Color.customGreen, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    // MARK: - Actions
    private func submitData() {
        print("Name: \(fullName)")
        print("Email: \(email)")
        print("Phone: \(phone)")
        print("Class Code: \(classCode)")
    }
}

// MARK: - Preview
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
