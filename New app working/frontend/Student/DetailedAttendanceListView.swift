//
//  DetailedAttendanceListView.swift
//  New app working
//
//  Created by AB on 1/13/25.
//

import SwiftUI

// MARK: - Attendance Entry Model
struct AttendanceEntry: Identifiable, Hashable {
    let id = UUID()
    let date: String
    let hours: String
}

// MARK: - Detailed Attendance List View
struct DetailedAttendanceListView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedDate: Date = Date()
    private let calendar = Calendar.current

    var body: some View {
        VStack {
            // Add extra space at the top
            Spacer().frame(height: 20)
            
            // Header with month navigation
            HStack {
                Button(action: {
                    selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
                }) {
                    Image(systemName: "chevron.left")
                    Text("Previous")
                }
                .foregroundColor(.customGreen)
                
                Spacer()
                
                Button(action: {
                    selectedDate = Date()
                }) {
                    Text("Today")
                }
                .foregroundColor(.customGreen)
                
                Spacer()
                
                Button(action: {
                    selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
                }) {
                    Text("Next")
                    Image(systemName: "chevron.right")
                }
                .foregroundColor(.customGreen)
            }
            .padding(.horizontal)
            
            // Month Title
            Text(monthYearString(from: selectedDate))
                .font(.title2)
                .bold()
                .foregroundColor(.primary)
                .padding(.top, 10)
            
            // Sum of Hours Card
            HStack {
                Text("Sum of hours")
                    .foregroundColor(.primary)
                Spacer()
                Text(totalHours(for: selectedDate))
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            
            // Hour-by-Week List
            List {
                ForEach(1..<6) { week in
                    NavigationLink(destination: WeekDetailView(month: monthYearString(from: selectedDate), week: week)) {
                        HStack {
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: 25, height: 25)
                                .overlay(
                                    Text("\(week)")
                                        .foregroundColor(.white)
                                        .font(.subheadline)
                                )
                            
                            Text(weeklyHours(for: selectedDate, week: week))
                                .foregroundColor(weeklyHours(for: selectedDate, week: week) != "0 hours, 0 minutes" ? .white : .secondary)
                            
                            Spacer()
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
        .padding()
        .background(Color(.systemBackground))
        .navigationTitle("Detailed Attendance")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Helper Functions
    
    func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    func totalHours(for date: Date) -> String {
        let monthYear = monthYearString(from: date)
        switch monthYear {
        case "January 2025":
            return "14 hours, 3 minutes"
        case "December 2024":
            return "32 hours, 47 minutes"
        default:
            return "0 hours, 0 minutes"
        }
    }
    
    func weeklyHours(for date: Date, week: Int) -> String {
        let monthYear = monthYearString(from: date)
        switch (monthYear, week) {
        case ("January 2025", 2):
            return "11 hours, 44 minutes"
        case ("January 2025", 3):
            return "2 hours, 19 minutes"
        case ("December 2024", 1):
            return "10 hours, 32 minutes"
        case ("December 2024", 2):
            return "15 hours, 10 minutes"
        case ("December 2024", 3):
            return "7 hours, 4 minutes"
        default:
            return "0 hours, 0 minutes"
        }
    }
}

// MARK: - Week Detail View
struct WeekDetailView: View {
    let month: String
    let week: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Week \(week) Details")
                .font(.title2)
                .bold()
                .foregroundColor(.primary)
                .padding(.top)
            
            Text("Month: \(month)")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Divider()
            
            // Detailed attendance data
            ForEach(weekDetails(for: month, week: week)) { entry in
                HStack {
                    Text(entry.date)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(entry.hours)
                        .font(.subheadline)
                        .foregroundColor(.customGreen)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .navigationTitle("Week \(week) Details")
    }
    
    // MARK: - Helper Function for Detailed Data
    func weekDetails(for month: String, week: Int) -> [AttendanceEntry] {
        switch (month, week) {
        case ("January 2025", 2):
            return [
                AttendanceEntry(date: "Jan 8", hours: "3 hours, 15 minutes"),
                AttendanceEntry(date: "Jan 9", hours: "4 hours, 30 minutes"),
                AttendanceEntry(date: "Jan 10", hours: "4 hours, 0 minutes")
            ]
        case ("January 2025", 3):
            return [
                AttendanceEntry(date: "Jan 15", hours: "1 hour, 10 minutes"),
                AttendanceEntry(date: "Jan 16", hours: "1 hour, 9 minutes")
            ]
        case ("December 2024", 1):
            return [
                AttendanceEntry(date: "Dec 1", hours: "3 hours, 0 minutes"),
                AttendanceEntry(date: "Dec 2", hours: "4 hours, 0 minutes"),
                AttendanceEntry(date: "Dec 3", hours: "3 hours, 32 minutes")
            ]
        default:
            return [AttendanceEntry(date: "No data", hours: "0 hours, 0 minutes")]
        }
    }
}

// MARK: - Preview
struct DetailedAttendanceListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DetailedAttendanceListView()
        }
        .preferredColorScheme(.dark)
        
        NavigationView {
            DetailedAttendanceListView()
        }
        .preferredColorScheme(.light)
    }
}
