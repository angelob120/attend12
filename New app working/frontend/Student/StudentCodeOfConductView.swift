//
//  StudentCodeOfConductView.swift
//  New app working
//
//  Created by AB on 4/10/25.
//

import SwiftUI

struct StudentCodeOfConductView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                Text("Student Code of Conduct")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 10)
                    .foregroundColor(Color.customGreen)
                
                // Introduction
                Text("As a student, you agree to uphold the following standards and responsibilities throughout your participation in our program.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 10)
                
                // Attendance Section
                SectionView(title: "Attendance Policy") {
                    BulletPointText("Maintain at least 90% attendance rate throughout the program")
                    BulletPointText("Arrive on time for all scheduled classes and activities")
                    BulletPointText("Clock in and out using the appropriate QR codes")
                    BulletPointText("Request time off at least 48 hours in advance when possible")
                    BulletPointText("Notify your mentor immediately in case of emergencies")
                    
                    Text("Failure to maintain the required attendance rate may result in disciplinary action or dismissal from the program.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 10)
                }
                
                // Academic Integrity Section
                SectionView(title: "Academic Integrity") {
                    BulletPointText("Complete all assignments independently unless group work is specified")
                    BulletPointText("Properly attribute sources in all written work")
                    BulletPointText("Refrain from plagiarism or copying work from others")
                    BulletPointText("Report any observed academic dishonesty to program staff")
                    BulletPointText("Participate actively in peer reviews and provide constructive feedback")
                    
                    Text("Violations of academic integrity will be taken seriously and may result in dismissal from the program.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 10)
                }
                
                // Professionalism Section
                SectionView(title: "Professional Conduct") {
                    BulletPointText("Treat all staff, mentors, and fellow students with respect")
                    BulletPointText("Maintain professional communication in person and online")
                    BulletPointText("Dress appropriately according to the program dress code")
                    BulletPointText("Keep personal devices silenced during instructional time")
                    BulletPointText("Maintain a clean and organized workspace")
                    BulletPointText("Follow all health and safety protocols")
                    
                    Text("Professional conduct prepares you for your future career and creates a productive learning environment for everyone.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 10)
                }
                
                // Facility Use Section
                SectionView(title: "Facility and Equipment Use") {
                    BulletPointText("Use program equipment only for authorized purposes")
                    BulletPointText("Report any damaged or malfunctioning equipment immediately")
                    BulletPointText("Do not remove equipment from the facility without permission")
                    BulletPointText("Adhere to all security protocols when entering and exiting the facility")
                    BulletPointText("Keep food and drinks away from computer equipment")
                }
                
                // Disciplinary Procedures Section
                SectionView(title: "Disciplinary Procedures") {
                    Text("Violations of this code of conduct will be addressed through a progressive disciplinary process:")
                        .font(.subheadline)
                        .padding(.bottom, 5)
                    
                    Text("1. Verbal warning")
                        .font(.subheadline)
                    Text("2. Written warning")
                        .font(.subheadline)
                    Text("3. Probationary status")
                        .font(.subheadline)
                    Text("4. Dismissal from the program")
                        .font(.subheadline)
                        .padding(.bottom, 5)
                    
                    Text("Serious violations may result in immediate dismissal without following the progressive steps.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Acknowledgement
                VStack(alignment: .center, spacing: 10) {
                    Text("I acknowledge that I have read and understand this Code of Conduct and agree to abide by its provisions.")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.vertical)
                        .frame(maxWidth: .infinity)
                    
                    Text("Last Updated: April 1, 2025")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.top, 20)
            }
            .padding()
        }
        .navigationTitle("Code of Conduct")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Code of Conduct")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .toolbarBackground(Color.customGreen, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

// MARK: - Helper Views

struct SectionView<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.customGreen)
            
            content
        }
        .padding(.vertical, 10)
    }
}

struct BulletPointText: View {
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
        .padding(.vertical, 2)
    }
}

struct StudentCodeOfConductView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StudentCodeOfConductView()
        }
    }
}
