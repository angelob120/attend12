//
//  MentorRow.swift
//  New app working
//
//  Created by AB on 4/10/25.
//

import SwiftUI

// MARK: - MentorRow View for Admin Dashboard
struct MentorRow: View {
    // User (mentor) data
    let user: AppUser1
    
    // Environment objects for getting actual student count
    @EnvironmentObject var userManager: CustomUserManager
    
    // Calculate actual student count
    var studentCount: Int {
        // In a real implementation, this would count students with this mentor as monitor
        return userManager.allUsers.filter {
            $0.role == "Student" && $0.monitorName == user.name
        }.count
    }
    
    var body: some View {
        HStack {
            Image(systemName: "person.2.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.headline)
                
                HStack {
                    Text("\(studentCount) Student\(studentCount != 1 ? "s" : "")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if studentCount > 0 {
                        Text("Assigned")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.7))
                            .cornerRadius(8)
                    }
                }
            }
            
            Spacer()
            
            // Indicator for admin to manage this mentor
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Preview
struct MentorRow_Previews: PreviewProvider {
    static var previews: some View {
        let sampleMentor = AppUser1(
            name: "Jane Smith",
            status: "Active",
            role: "Mentor",
            phoneNumber: "555-987-6543",
            email: "jane@example.com",
            monitorName: "Emily Davis"
        )
        
        MentorRow(user: sampleMentor)
            .environmentObject(CustomUserManager())
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
