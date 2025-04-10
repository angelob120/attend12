//
//  UserDetailView.swift
//  New app working
//
//  Created by AB on 1/9/25.
//

import SwiftUI


// MARK: - UserDetailView
struct UserDetailView: View {
    let user: AppUser1
    @State private var selectedAttendanceRecord: AttendanceRecord1?
    @State private var showAttendanceDetailSheet = false
    @State private var attendanceRecords1: [AttendanceRecord1] = []
    @State private var selectedRecord: AttendanceRecord1?
    @State private var showEditSheet = false
    
    // Calendar State
    @State private var currentDate = Date()
    @State private var attendanceData: [Date: AttendanceType] = [:]
    
    // Enum to represent attendance types (from DetailedCalendarView)
    enum AttendanceType {
        case present
        case tardy
        case absent
    }

    var body: some View {
        ScrollView {
            VStack {
                // User Information
                VStack(alignment: .leading, spacing: 10) {
                    Text("Name: \(user.name)")
                        .font(.title)
                        .padding(.bottom, 5)

                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.blue)
                        Text("Phone: \(user.phoneNumber)")
                    }

                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.green)
                        Text("Email: \(user.email)")
                    }

                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.purple)
                        Text("Monitor: \(user.monitorName)")
                    }
                }
                .padding()

                // Status
                Text("Status: \(user.status)")
                    .font(.headline)
                    .foregroundColor(user.status == "Active" ? .green : .red)
                    .padding()

                // Attendance Calendar (from DetailedCalendarView)
                Text("Attendance Calendar")
                    .font(.title2)
                    .padding(.top, 20)
                
                // MARK: - Month Navigation Header
                HStack {
                    Button(action: goToPreviousMonth) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.customGreen)
                    }
                    Spacer()
                    Text("\(monthYearFormatter.string(from: currentDate)) Attendance")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.primary)
                    Spacer()
                    Button(action: goToNextMonth) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.customGreen)
                    }
                }
                .padding(.horizontal)
                
                // MARK: - Weekdays Header (Sun-Sat)
                HStack(spacing: 10) {
                    ForEach(weekdays, id: \.self) { day in
                        Text(day)
                            .font(.subheadline)
                            .bold()
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.vertical, 8)
                .background(Color.customGreen.opacity(0.1))
                .cornerRadius(8)
                
                // MARK: - Calendar Grid (Full Weeks, No Outline)
                VStack(spacing: 10) {
                    let weeks = generateWeeks()
                    ForEach(0..<weeks.count, id: \.self) { row in
                        HStack(spacing: 10) {
                            ForEach(0..<7, id: \.self) { column in
                                if let dayDate = weeks[row][column] {
                                    // Day cell with attendance indicator
                                    VStack(spacing: 2) {
                                        ZStack {
                                            if Calendar.current.isDateInToday(dayDate) {
                                                Circle()
                                                    .foregroundColor(.customGreen)
                                                    .frame(width: 35, height: 35)
                                                    .shadow(color: Color.customGreen.opacity(0.3), radius: 5, x: 0, y: 4)
                                            }
                                            
                                            let dayNumber = Calendar.current.component(.day, from: dayDate)
                                            Text("\(dayNumber)")
                                                .foregroundColor(Calendar.current.isDateInToday(dayDate) ? .white : .primary)
                                                .font(.headline)
                                        }
                                        .frame(width: 40, height: 35)
                                        
                                        // Attendance icon
                                        attendanceIcon(for: dayDate)
                                            .frame(width: 15, height: 15)
                                    }
                                    .onTapGesture {
                                        selectDay(dayDate)
                                    }
                                } else {
                                    // Empty cell for dates outside the current month.
                                    Spacer()
                                        .frame(width: 40, height: 40)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .shadow(color: Color.customGreen.opacity(0.1), radius: 5, x: 0, y: 3)
                
                // MARK: - Legend with Distinct Shapes for Accessibility
                HStack(spacing: 20) {
                    LegendItem(color: .red, text: "Absences")
                    LegendItem(color: .yellow, text: "Tardies")
                    LegendItem(color: .customGreen, text: "Attendances")
                }
                .padding(.vertical)

                Spacer()

                // Bottom Vertical Button Stack
                VStack(spacing: 12) {
                    // Edit Attendance

                    // Remove Student
                    Button(action: {
                        print("Remove student tapped")
                    }) {
                        Text("Remove Student")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .cornerRadius(8)
                    }

                    // Promote to Teacher or Admin
                    Menu {
                        Button("Promote to Mentor") {
                            print("Promote to Mentor tapped")
                        }
                        Button("Promote to Admin") {
                            print("Promote to Admin tapped")
                        }
                    } label: {
                        Text("Promote")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.orange)
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Centered Title
            ToolbarItem(placement: .principal) {
                Text("User Details")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .toolbarBackground(Color.customGreen, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showEditSheet) {
            if let record = selectedRecord {
                EditAttendanceSheet(record: record)
            }
        }
        .sheet(isPresented: $showAttendanceDetailSheet) {
            if let record = selectedAttendanceRecord {
                AttendanceDetailSheet(record: record)
            }
        }
        .onAppear {
            generateAttendanceData()
        }
        .onChange(of: currentDate) { _ in
            generateAttendanceData()
        }
    }
    
    // MARK: - Calendar Helper Functions
    
    // Method to select a day and find its attendance record
    private func selectDay(_ date: Date) {
        // For admin view, we want to allow editing even for dates without existing records
        let calendar = Calendar.current
        
        // Create default times for new records
        let clockInTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
        let clockOutTime = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: date) ?? date
        
        // Either use existing record or create a new one
        if let _ = attendanceData[date] {
            // Use existing data (would be pulled from actual database in real app)
            selectedRecord = AttendanceRecord1(
                date: date,
                clockIn: clockInTime,
                clockOut: clockOutTime
            )
        } else {
            // Create a new record if none exists (admin can add records)
            selectedRecord = AttendanceRecord1(
                date: date,
                clockIn: clockInTime,
                clockOut: clockOutTime
            )
        }
        
        // Show the edit sheet directly
        showEditSheet = true
    }
    
    // Generates a 2D array of optional Dates representing full weeks (Sun-Sat) for the current month.
    private func generateWeeks() -> [[Date?]] {
        var weeks: [[Date?]] = []
        let calendar = Calendar.current
        
        // First and last day of the current month.
        guard let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)),
              let lastOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstOfMonth) else {
            return weeks
        }
        
        // Compute the Sunday that starts the week of the first day.
        let weekdayOfFirst = calendar.component(.weekday, from: firstOfMonth)
        let firstWeekSunday = calendar.date(byAdding: .day, value: -(weekdayOfFirst - 1), to: firstOfMonth)!
        
        // Compute the Saturday that ends the week of the last day.
        let weekdayOfLast = calendar.component(.weekday, from: lastOfMonth)
        let lastWeekSaturday = calendar.date(byAdding: .day, value: (7 - weekdayOfLast), to: lastOfMonth)!
        
        // Iterate week-by-week from firstWeekSunday to lastWeekSaturday.
        var weekStart = firstWeekSunday
        while weekStart <= lastWeekSaturday {
            var week: [Date?] = []
            for offset in 0..<7 { // Sunday to Saturday.
                if let day = calendar.date(byAdding: .day, value: offset, to: weekStart) {
                    // Only show the day if it belongs to the current month.
                    if calendar.isDate(day, equalTo: firstOfMonth, toGranularity: .month) {
                        week.append(day)
                    } else {
                        week.append(nil)
                    }
                }
            }
            weeks.append(week)
            weekStart = calendar.date(byAdding: .day, value: 7, to: weekStart)!
        }
        return weeks
    }
    
    // MARK: - Attendance Data Generation
    
    /// Generate random attendance data for the current month
    private func generateAttendanceData() {
        // Reset attendance data
        attendanceData.removeAll()
        
        let calendar = Calendar.current
        
        // Get the first and last day of the month
        guard let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)),
              let lastOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstOfMonth) else {
            return
        }
        
        // Generate data from first of month to today or last of month
        var currentDay = firstOfMonth
        let latestDay = min(lastOfMonth, Date())
        
        // Track number of absences to limit to max 5
        var absenceCount = 0
        
        while currentDay <= latestDay {
            // Skip weekends
            if !calendar.isDateInWeekend(currentDay) {
                // Determine attendance type
                let attendanceType: AttendanceType
                
                // Limit absences to max 5
                if absenceCount < 5 && shouldBeAbsent() {
                    attendanceType = .absent
                    absenceCount += 1
                }
                // Small chance of being tardy
                else if shouldBeTardy() {
                    attendanceType = .tardy
                }
                // Otherwise present
                else {
                    attendanceType = .present
                }
                
                attendanceData[currentDay] = attendanceType
            }
            
            // Move to next day
            currentDay = calendar.date(byAdding: .day, value: 1, to: currentDay)!
        }
    }
    
    /// Probabilistic method to determine if a day should be an absence
    private func shouldBeAbsent() -> Bool {
        // Low probability of absence
        return Double.random(in: 0...1) < 0.1 // 10% chance
    }
    
    /// Probabilistic method to determine if a day should be tardy
    private func shouldBeTardy() -> Bool {
        // Low probability of tardiness
        return Double.random(in: 0...1) < 0.15 // 15% chance
    }
    
    // New method to generate attendance icon
    private func attendanceIcon(for date: Date) -> some View {
        guard let attendanceType = attendanceData[date],
              !Calendar.current.isDateInWeekend(date) else {
            return AnyView(EmptyView())
        }
        
        switch attendanceType {
        case .present:
            return AnyView(
                Circle()
                    .fill(Color.green)
                    .frame(width: 10, height: 10)
            )
        case .tardy:
            return AnyView(
                Triangle()
                    .fill(Color.yellow)
                    .frame(width: 10, height: 10)
            )
        case .absent:
            return AnyView(
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
            )
        }
    }
    
    // MARK: - Month Navigation Functions
    func goToNextMonth() {
        if let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) {
            currentDate = nextMonth
        }
    }
    
    func goToPreviousMonth() {
        if let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) {
            currentDate = previousMonth
        }
    }
    
    // Weekdays header: Sunday through Saturday.
    private var weekdays: [String] {
        ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    }
    
    // Formatter for month and year display.
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
}

// We're using the Triangle and LegendItem from DetailedCalendarView.swift
// (Triangle and LegendItem are already defined elsewhere)

// MARK: - EditAttendanceSheet
struct EditAttendanceSheet: View {
    @State var record: AttendanceRecord1
    @Environment(\.presentationMode) var presentationMode
    @State private var attendanceStatus: String = "Present"
    let statusOptions = ["Present", "Tardy", "Absent"]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Title with date
                Text("Attendance Record")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text(record.date, formatter: DateFormatter.shortDate)
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                // Current times
                HStack {
                    VStack(alignment: .leading) {
                        Text("Current Clock In:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(timeFormatter.string(from: record.clockIn))
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Current Clock Out:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(timeFormatter.string(from: record.clockOut))
                            .font(.headline)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                Divider()
                
                // Status Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Attendance Status:")
                        .font(.headline)
                        .padding(.bottom, 5)
                    
                    Picker("Status", selection: $attendanceStatus) {
                        ForEach(statusOptions, id: \.self) { status in
                            Text(status)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                .padding(.horizontal)
                
                // Edit Clock Times Section
                VStack(alignment: .leading, spacing: 20) {
                    Text("Edit Clock In/Out Times")
                        .font(.headline)
                        .padding(.top)
                    
                    // Clock In Time Picker
                    VStack(alignment: .leading) {
                        Text("Clock In Time:")
                            .font(.subheadline)
                        
                        DatePicker("", selection: $record.clockIn, displayedComponents: .hourAndMinute)
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                    }
                    
                    // Clock Out Time Picker
                    VStack(alignment: .leading) {
                        Text("Clock Out Time:")
                            .font(.subheadline)
                        
                        DatePicker("", selection: $record.clockOut,
                                   in: record.clockIn...(record.clockIn.addingTimeInterval(4 * 3600)),
                                   displayedComponents: .hourAndMinute)
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 30)
                
                // Action Buttons
                HStack(spacing: 20) {
                    Button {
                        // Cancel without saving
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                    
                    Button {
                        // Here you would save the updated record with the status
                        // For this example, we just dismiss
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Save")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .padding()
        }
    }
    
    // Formatter for displaying time
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

// Original necessary data structures and formatters (unchanged)
struct AttendanceRecord1: Identifiable {
    let id = UUID()
    var date: Date
    var clockIn: Date
    var clockOut: Date
}

extension DateFormatter {
    func safeShortWeekdaySymbol(at index: Int) -> String {
        let symbols = self.shortWeekdaySymbols ?? []
        return symbols.indices.contains(index) ? symbols[index] : ""
    }

    static var shortDate: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}
