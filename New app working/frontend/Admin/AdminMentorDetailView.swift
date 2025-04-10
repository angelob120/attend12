//
//  AdminMentorDetailView.swift
//  New app working
//
//  Created by AB on 4/10/25.
//

import SwiftUI

struct AdminMentorDetailView: View {
    // Mentor being displayed
    let mentor: AppUser1
    
    // Environment objects for data access
    @EnvironmentObject var userManager: CustomUserManager
    @EnvironmentObject var cloudKitConfig: CloudKitAppConfig
    
    // State for UI interactions
    @State private var showPromoteConfirmation = false
    @State private var selectedStudent: AppUser1? = nil
    @State private var showStudentDetailSheet = false
    @State private var showRemoveStudentAlert = false
    
    // Environment for dismissing the view
    @Environment(\.presentationMode) var presentationMode
    
    // Get mentor's students
    var mentorStudents: [AppUser1] {
        return userManager.allUsers.filter { user in
            user.role == "Student" && user.monitorName == mentor.name
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Back Button
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back to Admin Dashboard")
                        }
                        .foregroundColor(Color.customGreen)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                // MARK: - Mentor Header
                VStack(spacing: 15) {
                    Image(systemName: "person.2.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.green)
                        .padding()
                        .background(Circle().fill(Color.green.opacity(0.1)))
                    
                    Text(mentor.name)
                        .font(.title)
                        .bold()
                    
                    // MARK: - Contact Information
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.green)
                            Text(mentor.email)
                        }
                        
                        HStack {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.green)
                            Text(mentor.phoneNumber)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemBackground)))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    
                    // MARK: - Promote to Admin Button
                    Button(action: {
                        showPromoteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.up.square.fill")
                            Text("Promote to Admin")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .alert(isPresented: $showPromoteConfirmation) {
                        Alert(
                            title: Text("Promote to Admin"),
                            message: Text("Are you sure you want to promote \(mentor.name) to Admin? This will give them full administrative access."),
                            primaryButton: .destructive(Text("Promote")) {
                                promoteMentorToAdmin()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
                .padding()
                
                // MARK: - Students List Section
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("Assigned Students")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(mentorStudents.count) Students")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    if mentorStudents.isEmpty {
                        Text("No students assigned to this mentor")
                            .foregroundColor(.gray)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        // List of students
                        ForEach(mentorStudents, id: \.id) { student in
                            Button(action: {
                                selectedStudent = student
                                showStudentDetailSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "person.crop.circle")
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(.blue)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(student.name)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Text(student.email)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationBarTitle("Mentor Details", displayMode: .inline)
        .navigationBarHidden(true) // Hide the navigation bar since we have our own back button
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $showStudentDetailSheet) {
            if let student = selectedStudent {
                AdminStudentDetailView(
                    student: student,
                    mentor: mentor,
                    onRemoveFromMentor: {
                        showStudentDetailSheet = false
                        showRemoveStudentAlert = true
                    }
                )
            }
        }
        .alert(isPresented: $showRemoveStudentAlert) {
            Alert(
                title: Text("Remove Student"),
                message: Text("Are you sure you want to remove \(selectedStudent?.name ?? "this student") from \(mentor.name)?"),
                primaryButton: .destructive(Text("Remove")) {
                    if let student = selectedStudent {
                        removeStudentFromMentor(student)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // MARK: - Helper Functions
    
    // Function to promote mentor to admin
    private func promoteMentorToAdmin() {
        // In a real app, this would update the database
        print("Promoting \(mentor.name) to Admin")
        
        // Update the local state (for demo purposes)
        if let index = userManager.allUsers.firstIndex(where: { $0.id == mentor.id }) {
            var updatedMentor = mentor
            updatedMentor.role = "Admin"
            userManager.allUsers[index] = updatedMentor
            
            // Dismiss the view after promotion
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    // Function to remove a student from this mentor
    private func removeStudentFromMentor(_ student: AppUser1) {
        // In a real app, this would update the database
        print("Removing \(student.name) from \(mentor.name)")
        
        // Update the local state (for demo purposes)
        if let index = userManager.allUsers.firstIndex(where: { $0.id == student.id }) {
            var updatedStudent = student
            updatedStudent.monitorName = "Unassigned"
            userManager.allUsers[index] = updatedStudent
        }
    }
}

// MARK: - Preview
struct AdminMentorDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleMentor = AppUser1(
            name: "Jane Smith",
            status: "Active",
            role: "Mentor",
            phoneNumber: "555-987-6543",
            email: "jane@example.com",
            monitorName: "Emily Davis"
        )
        
        AdminMentorDetailView(mentor: sampleMentor)
            .environmentObject(CustomUserManager())
            .environmentObject(CloudKitAppConfig.shared)
    }
}
