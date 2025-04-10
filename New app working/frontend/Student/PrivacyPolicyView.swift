//
//  PrivacyPolicyView.swift
//  New app working
//
//  Created by AB on 4/10/25.
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                Text("Privacy Policy")
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
                Text("This Privacy Policy describes how we collect, use, and disclose your information when you use our application.")
                    .font(.body)
                    .padding(.bottom, 10)
                
                // Information Collection Section
                PolicySection(title: "Information We Collect") {
                    Text("We collect several types of information from and about users of our application, including:")
                        .padding(.bottom, 5)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        PolicyBulletPoint("Personal information such as your name, email address, and phone number")
                        PolicyBulletPoint("Academic and performance data, including attendance records, progress metrics, and activity logs")
                        PolicyBulletPoint("Device information such as your device ID, operating system, and usage patterns")
                        PolicyBulletPoint("Location data when you check in or check out using our application")
                        PolicyBulletPoint("Communications between you and your mentors or program administrators")
                    }
                }
                
                // Use of Information Section
                PolicySection(title: "How We Use Your Information") {
                    Text("We use the information we collect about you for various purposes, including:")
                        .padding(.bottom, 5)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        PolicyBulletPoint("Providing and maintaining our application and its features")
                        PolicyBulletPoint("Tracking your attendance and progress within the program")
                        PolicyBulletPoint("Communicating with you about program updates, schedule changes, and other relevant information")
                        PolicyBulletPoint("Analyzing usage patterns to improve our application and services")
                        PolicyBulletPoint("Ensuring compliance with program requirements and policies")
                        PolicyBulletPoint("Providing personalized support and mentorship")
                    }
                }
                
                // Data Sharing Section
                PolicySection(title: "Sharing Your Information") {
                    Text("We may share your personal information with:")
                        .padding(.bottom, 5)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        PolicyBulletPoint("Program mentors and administrators who need access to provide services")
                        PolicyBulletPoint("Service providers who perform functions on our behalf")
                        PolicyBulletPoint("Educational partners or sponsoring organizations, with your consent")
                        PolicyBulletPoint("Government agencies or other third parties when required by law")
                    }
                    
                    Text("We do not sell your personal information to third parties.")
                        .fontWeight(.medium)
                        .padding(.top, 5)
                }
                
                // Data Security Section
                PolicySection(title: "Data Security") {
                    Text("We implement appropriate security measures to protect your personal information from unauthorized access, alteration, disclosure, or destruction. These measures include:")
                        .padding(.bottom, 5)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        PolicyBulletPoint("Encryption of sensitive data both in transit and at rest")
                        PolicyBulletPoint("Regular security assessments and audits")
                        PolicyBulletPoint("Access controls and authentication mechanisms")
                        PolicyBulletPoint("Employee training on privacy and security practices")
                        PolicyBulletPoint("Secure cloud storage and backup procedures")
                    }
                    
                    Text("However, no method of transmission over the Internet or electronic storage is 100% secure, so we cannot guarantee absolute security.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 5)
                }
                
                // Data Retention Section
                PolicySection(title: "Data Retention") {
                    Text("We retain your personal information for as long as necessary to fulfill the purposes outlined in this Privacy Policy, unless a longer retention period is required or permitted by law. When determining how long to keep your information, we consider:")
                        .padding(.bottom, 5)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        PolicyBulletPoint("The duration of your participation in our program")
                        PolicyBulletPoint("Our legal obligations")
                        PolicyBulletPoint("Applicable statutes of limitations")
                        PolicyBulletPoint("Ongoing administrative needs")
                    }
                }
                
                // Your Rights Section
                PolicySection(title: "Your Rights") {
                    Text("Depending on your location, you may have certain rights regarding your personal information, including:")
                        .padding(.bottom, 5)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        PolicyBulletPoint("Access to your personal information")
                        PolicyBulletPoint("Correction of inaccurate or incomplete information")
                        PolicyBulletPoint("Deletion of your personal information in certain circumstances")
                        PolicyBulletPoint("Restriction or objection to processing")
                        PolicyBulletPoint("Data portability")
                    }
                    
                    Text("To exercise any of these rights, please contact us using the information provided below.")
                        .padding(.top, 5)
                }
                
                // Changes to Policy Section
                PolicySection(title: "Changes to This Privacy Policy") {
                    Text("We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the \"Last Updated\" date.")
                    
                    Text("You are advised to review this Privacy Policy periodically for any changes. Changes to this Privacy Policy are effective when they are posted on this page.")
                        .padding(.top, 5)
                }
                
                // Contact Information
                PolicySection(title: "Contact Us") {
                    Text("If you have any questions or concerns about this Privacy Policy or our data practices, please contact us at:")
                        .padding(.bottom, 5)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Privacy Officer")
                            .fontWeight(.medium)
                        Text("Email: privacy@example.com")
                        Text("Phone: (555) 123-4567")
                        Text("Address: 123 Main Street, Suite 500, Anytown, CA 12345")
                    }
                    .padding(.leading)
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Privacy Policy")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .toolbarBackground(Color.customGreen, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

// MARK: - Helper Views

struct PolicySection<Content: View>: View {
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

struct PolicyBulletPoint: View {
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

struct PrivacyPolicyView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PrivacyPolicyView()
        }
    }
}
