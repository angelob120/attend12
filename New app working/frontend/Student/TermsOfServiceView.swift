//
//  TermsOfServiceView.swift
//  New app working
//
//  Created by AB on 4/10/25.
//

import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                Text("Terms of Service")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 10)
                    .foregroundColor(Color.customGreen)
                
                // Last Updated
                Text("Last Updated: April 1, 2025")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
                
                // Introduction
                Text("These Terms of Service (\"Terms\") govern your use of our mobile application (the \"App\") and the services provided through the App. By using the App, you agree to these Terms. If you do not agree to these Terms, please do not use the App.")
                    .font(.body)
                    .padding(.bottom, 10)
                
                // Eligibility Section
                TermsSection(title: "Eligibility") {
                    Text("You must be enrolled in our program to use the App. By using the App, you represent and warrant that:")
                        .padding(.bottom, 5)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        TermsBulletPoint("You are at least 18 years of age or have parental/guardian consent")
                        TermsBulletPoint("You are currently enrolled in our program")
                        TermsBulletPoint("You have the right and authority to agree to these Terms")
                        TermsBulletPoint("You will comply with all applicable laws and regulations")
                    }
                }
                
                // Account Requirements Section
                TermsSection(title: "Account Requirements") {
                    VStack(alignment: .leading, spacing: 10) {
                        TermsBulletPoint("You are responsible for maintaining the confidentiality of your account credentials")
                        TermsBulletPoint("You are responsible for all activities that occur under your account")
                        TermsBulletPoint("You must provide accurate and complete information when creating your account")
                        TermsBulletPoint("You agree to promptly update any information to keep it accurate and complete")
                        TermsBulletPoint("You may not share your account with anyone else")
                        TermsBulletPoint("You must notify us immediately of any unauthorized use of your account")
                    }
                }
                
                // Acceptable Use Section
                TermsSection(title: "Acceptable Use") {
                    Text("When using the App, you agree not to:")
                        .padding(.bottom, 5)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        TermsBulletPoint("Violate any applicable laws or regulations")
                        TermsBulletPoint("Circumvent or attempt to circumvent any security measures")
                        TermsBulletPoint("Use the App to send unsolicited communications")
                        TermsBulletPoint("Upload viruses or other malicious code")
                        TermsBulletPoint("Attempt to gain unauthorized access to the App or its systems")
                        TermsBulletPoint("Use the App for any illegal or unauthorized purpose")
                        TermsBulletPoint("Interfere with or disrupt the App or servers")
                        TermsBulletPoint("Clock in or clock out on behalf of another user")
                        TermsBulletPoint("Falsify attendance or program records")
                    }
                }
                
                // Intellectual Property Section
                TermsSection(title: "Intellectual Property") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("The App and its contents, features, and functionality are owned by us and are protected by copyright, trademark, and other intellectual property laws.")
                            .padding(.bottom, 5)
                        
                        Text("You may not:")
                            .padding(.bottom, 5)
                        
                        TermsBulletPoint("Reproduce, distribute, modify, or create derivative works of the App")
                        TermsBulletPoint("Decompile, reverse engineer, or disassemble the App")
                        TermsBulletPoint("Remove any copyright or proprietary notices")
                        TermsBulletPoint("Transfer your rights under these Terms to any third party")
                    }
                }
                
                // Data Collection and Use Section
                TermsSection(title: "Data Collection and Use") {
                    Text("By using the App, you agree to our Privacy Policy, which describes how we collect, use, and disclose information about you. The Privacy Policy is incorporated by reference into these Terms.")
                    
                    Text("You acknowledge that we may collect and use data related to your use of the App, including attendance records, for program administration purposes.")
                        .padding(.top, 5)
                }
                
                // Termination Section
                TermsSection(title: "Termination") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("We may terminate or suspend your access to the App immediately, without prior notice or liability, for any reason, including if you breach these Terms.")
                            .padding(.bottom, 5)
                        
                        Text("Upon termination, your right to use the App will immediately cease. All provisions of these Terms which by their nature should survive termination shall survive, including ownership provisions, warranty disclaimers, indemnity, and limitations of liability.")
                    }
                }
                
                // Disclaimer of Warranties Section
                TermsSection(title: "Disclaimer of Warranties") {
                    Text("THE APP IS PROVIDED \"AS IS\" AND \"AS AVAILABLE\" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED. TO THE FULLEST EXTENT PERMITTED BY LAW, WE DISCLAIM ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO, IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.")
                        .font(.subheadline)
                    
                    Text("We do not warrant that the App will function uninterrupted, secure, or available at any particular time or location, or that any errors or defects will be corrected.")
                        .font(.subheadline)
                        .padding(.top, 10)
                }
                
                // Limitation of Liability Section
                TermsSection(title: "Limitation of Liability") {
                    Text("TO THE FULLEST EXTENT PERMITTED BY LAW, IN NO EVENT SHALL WE BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING WITHOUT LIMITATION, LOSS OF PROFITS, DATA, USE, GOODWILL, OR OTHER INTANGIBLE LOSSES, RESULTING FROM YOUR ACCESS TO OR USE OF OR INABILITY TO ACCESS OR USE THE APP.")
                        .font(.subheadline)
                }
                
                // Governing Law Section
                TermsSection(title: "Governing Law") {
                    Text("These Terms shall be governed by and construed in accordance with the laws of the State of California, without regard to its conflict of law provisions. Any legal action or proceeding relating to these Terms shall be brought exclusively in the courts located in Los Angeles County, California.")
                }
                
                // Changes to Terms Section
                TermsSection(title: "Changes to Terms") {
                    Text("We reserve the right to modify or replace these Terms at any time. We will provide notice of any changes by posting the new Terms on the App and updating the \"Last Updated\" date.")
                    
                    Text("Your continued use of the App after any such changes constitutes your acceptance of the new Terms.")
                        .padding(.top, 5)
                }
                
                // Contact Information
                TermsSection(title: "Contact Us") {
                    Text("If you have any questions about these Terms, please contact us at:")
                        .padding(.bottom, 5)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Legal Department")
                            .fontWeight(.medium)
                        Text("Email: legal@example.com")
                        Text("Phone: (555) 987-6543")
                        Text("Address: 123 Main Street, Suite 500, Anytown, CA 12345")
                    }
                    .padding(.leading)
                }
                
                // Agreement
                VStack(alignment: .center, spacing: 10) {
                    Text("By using the App, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.vertical)
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.top, 20)
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Terms of Service")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .toolbarBackground(Color.customGreen, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

// MARK: - Helper Views

struct TermsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.customGreen)
            
            content
            
            Divider()
                .padding(.top, 10)
        }
        .padding(.vertical, 5)
    }
}

struct TermsBulletPoint: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("•")
                .font(.headline)
                .foregroundColor(Color.customGreen)
            Text(text)
                .font(.body)
        }
    }
}

struct TermsOfServiceView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TermsOfServiceView()
        }
    }
}
