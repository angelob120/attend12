//
//  AdminStudentDetailView.swift
//  New app working
//
//  Created by AB on 4/10/25.
//

import SwiftUI

// MARK: - AdminStudentDetailView
struct AdminStudentDetailView: View {
    let student: AppUser1
    let mentor: AppUser1
    let onRemoveFromMentor: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Student Profile Section
                VStack(alignment: .center, spacing: 15) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                    
                    Text(student.name)
                        .font(.title)
                        .bold()
                    
                    Text("Student")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(20)
                }
                .padding()
                
                // Contact Information Section
                VStack(alignment: .leading, spacing: 15) {
                    Text("Contact Information")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .frame(width: 25)
                                .foregroundColor(.blue)
                            Text(student.email)
                        }
                        
                        HStack {
                            Image(systemName: "phone.fill")
                                .frame(width: 25)
                                .foregroundColor(.blue)
                            Text(student.phoneNumber)
                        }
                        
                        HStack {
                            Image(systemName: "person.2.fill")
                                .frame(width: 25)
                                .foregroundColor(.green)
                            Text("Mentor: \(student.monitorName)")
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Remove from Mentor Button
                Button(action: {
                    onRemoveFromMentor()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "person.fill.xmark")
                        Text("Remove from \(mentor.name)")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationBarTitle("Student Details", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Preview
struct AdminStudentDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleStudent = AppUser1(
            name: "John Doe",
            status: "Active",
            role: "Student",
            phoneNumber: "555-123-4567",
            email: "john@example.com",
            monitorName: "Jane Smith"
        )
        
        let sampleMentor = AppUser1(
            name: "Jane Smith",
            status: "Active",
            role: "Mentor",
            phoneNumber: "555-987-6543",
            email: "jane@example.com",
            monitorName: "Emily Davis"
        )
        
        AdminStudentDetailView(student: sampleStudent, mentor: sampleMentor, onRemoveFromMentor: {})
    }
}
