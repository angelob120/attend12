//
//  MenteeDetailView.swift
//  New app working
//
//  Created by AB on 1/15/25.
//

import SwiftUI


struct MenteeDetailView: View {
    @EnvironmentObject var menteeManager: MenteeManager
    let mentee: Mentee
    @State private var showTransferSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Profile Image
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .padding(.top, 20)
                
                // MARK: - Mentee Name
                Text(mentee.name)
                    .font(.largeTitle)
                    .bold()
                
                // MARK: - Progress
                Text("Progress: \(mentee.progress)%")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Divider()
                
                // MARK: - Contact Information
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "envelope")
                        Text(mentee.email)
                            .foregroundColor(.blue)
                    }
                    HStack {
                        Image(systemName: "phone")
                        Text(mentee.phone)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                Divider()
                
                // MARK: - Attendance Calendar
                Text("Attendance")
                    .font(.headline)
                    .padding(.top, 10)
                
                AttendanceCalendarView(attendanceRecords: mentee.attendanceRecords)
                
                Spacer()
                
                // MARK: - Transfer Mentee Button
                Button(action: {
                    showTransferSheet.toggle()
                }) {
                    Text("Transfer Mentee")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                .sheet(isPresented: $showTransferSheet) {
                    TransferMenteeSheet(mentee: mentee)
                        .environmentObject(menteeManager)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Centered Title
            ToolbarItem(placement: .principal) {
                Text("Mentee Details")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .toolbarBackground(Color.customGreen, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}
