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
    @State private var attendanceData: [String: [AttendanceEntry]] = [:]
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
                    NavigationLink(destination: WeekDetailView(month: monthYearString(from: selectedDate), week: week, entries: attendanceData["\(monthYearString(from: selectedDate))-\(week)"] ?? [])) {
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
        .onAppear {
            generateAttendanceData()
        }
        .onChange(of: selectedDate) { _ in
            generateAttendanceData()
        }
    }
    
    // MARK: - Attendance Data Generation
    
    private func generateAttendanceData() {
        attendanceData.removeAll()
        
        // Generate data for all months from the past to today
        var currentMonth = earliestMonth()
        let today = Date()
        
        while currentMonth <= today {
            // Generate data for each week
            for week in 1...5 {
                let monthWeekKey = "\(monthYearString(from: currentMonth))-\(week)"
                attendanceData[monthWeekKey] = generateWeekData(for: currentMonth, week: week)
            }
            
            // Move to next month
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)!
        }
    }
    
    private func earliestMonth() -> Date {
        var dateComponents = DateComponents()
        dateComponents.year = 2024
        dateComponents.month = 12
        dateComponents.day = 1
        return calendar.date(from: dateComponents)!
    }
    
    private func generateWeekData(for month: Date, week: Int) -> [AttendanceEntry] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        
        // Calculate the start of the week
        var weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: month.addingTimeInterval(TimeInterval(week - 1) * 7 * 24 * 3600)))!
        
        var weekEntries: [AttendanceEntry] = []
        var workdayCount = 0
        
        // Generate 5 workdays with 4-hour shifts
        for _ in 0..<7 {
            // Skip weekends
            if !calendar.isDateInWeekend(weekStart) {
                // 90-99% attendance rate
                if Double.random(in: 0...1) > 0.1 {
                    let hoursWorked = 4.0
                    let hours = String(format: "%.0f hours, 0 minutes", hoursWorked)
                    weekEntries.append(AttendanceEntry(
                        date: dateFormatter.string(from: weekStart),
                        hours: hours
                    ))
                    workdayCount += 1
                }
            }
            
            // Move to next day
            weekStart = calendar.date(byAdding: .day, value: 1, to: weekStart)!
            
            // Stop if we've generated 5 workdays
            if workdayCount == 5 {
                break
            }
        }
        
        return weekEntries
    }
    
    // MARK: - Helper Functions
    
    func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    func totalHours(for date: Date) -> String {
        let monthKey = monthYearString(from: date)
        var totalMinutes = 0
        
        // Sum hours for all weeks in the month
        for week in 1...5 {
            let weekKey = "\(monthKey)-\(week)"
            if let weekEntries = attendanceData[weekKey] {
                totalMinutes += weekEntries.count * 240 // 4 hours = 240 minutes
            }
        }
        
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        return "\(hours) hours, \(minutes) minutes"
    }
    
    func weeklyHours(for date: Date, week: Int) -> String {
        let monthKey = "\(monthYearString(from: date))-\(week)"
        
        guard let weekEntries = attendanceData[monthKey], !weekEntries.isEmpty else {
            return "0 hours, 0 minutes"
        }
        
        return "\(weekEntries.count * 4) hours, 0 minutes"
    }
}

// MARK: - Week Detail View
struct WeekDetailView: View {
    let month: String
    let week: Int
    let entries: [AttendanceEntry]

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
            if entries.isEmpty {
                Text("No attendance data")
                    .foregroundColor(.secondary)
            } else {
                ForEach(entries) { entry in
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
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .navigationTitle("Week \(week) Details")
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
