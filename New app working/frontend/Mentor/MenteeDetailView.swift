//
//  MenteeDetailView.swift
//  New app working
//
//  Created by AB on 1/15/25.
//  Updated to match admin's student attendance view

import SwiftUI


struct MenteeDetailView: View {
    @EnvironmentObject var menteeManager: MenteeManager
    let mentee: Mentee
    @State private var showTransferSheet = false
    
    // Calendar State
    @State private var currentDate = Date()
    @State private var attendanceData: [Date: AttendanceType] = [:]
    @State private var selectedDay: Date? = nil
    @State private var showTimeSheet = false
    
    // Enum to represent attendance types (from DetailedCalendarView)
    enum AttendanceType {
        case present
        case tardy
        case absent
    }

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
                
                // MARK: - Calendar Section (matching admin view)
                VStack(spacing: 20) {
                    // Header text
                    Text("Attendance Calendar")
                        .font(.headline)
                        .padding(.top, 10)
                
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
                                        // Wrap each day cell in a Button so that when tapped it will open the time sheet.
                                        Button(action: {
                                            selectedDay = dayDate
                                            showTimeSheet = true
                                        }) {
                                            let dayNumber = Calendar.current.component(.day, from: dayDate)
                                            VStack(spacing: 2) {
                                                ZStack {
                                                    if Calendar.current.isDateInToday(dayDate) {
                                                        Circle()
                                                            .foregroundColor(.customGreen)
                                                            .frame(width: 35, height: 35)
                                                            .shadow(color: Color.customGreen.opacity(0.3), radius: 5, x: 0, y: 4)
                                                    }
                                                    Text("\(dayNumber)")
                                                        .foregroundColor(Calendar.current.isDateInToday(dayDate) ? .white : .primary)
                                                        .font(.headline)
                                                }
                                                .frame(width: 40, height: 35)
                                                
                                                // Attendance icon
                                                attendanceIcon(for: dayDate)
                                                    .frame(width: 15, height: 15)
                                            }
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
                }
                
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
        .sheet(isPresented: $showTimeSheet) {
            // Pass the selected day to the time attendance sheet
            AttendanceTimeSheet(selectedDay: selectedDay ?? Date())
        }
        .onAppear {
            // Generate attendance data on appear
            generateAttendanceData()
        }
        .onChange(of: currentDate) { _ in
            // Regenerate data when month changes
            generateAttendanceData()
        }
    }
    
    // MARK: - Calendar Helper Functions
    
    /// Generates a 2D array of optional Dates representing full weeks (Sun-Sat) for the current month.
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

// MARK: - Time Sheet for Clock In/Out Detail
struct AttendanceTimeSheet1: View {
    let selectedDay: Date
    @Environment(\.dismiss) var dismiss
    
    @State private var clockIn: Date
    @State private var clockOut: Date
    
    init(selectedDay: Date) {
        self.selectedDay = selectedDay
        let calendar = Calendar.current
        // Create a default clock-in time (e.g., at 9:00 AM on the selected day)
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDay)
        components.hour = 9
        components.minute = 0
        let defaultClockIn = calendar.date(from: components) ?? selectedDay
        let defaultClockOut = defaultClockIn.addingTimeInterval(4 * 3600) // 4 hours later
        
        _clockIn = State(initialValue: defaultClockIn)
        _clockOut = State(initialValue: defaultClockOut)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Clock In Time")) {
                    DatePicker("Clock In", selection: $clockIn, displayedComponents: [.hourAndMinute])
                }
                Section(header: Text("Clock Out Time (Max 4 hours later)")) {
                    DatePicker(
                        "Clock Out",
                        selection: $clockOut,
                        in: clockIn...clockIn.addingTimeInterval(4 * 3600),
                        displayedComponents: [.hourAndMinute]
                    )
                }
                
                Section {
                    Button("Save Changes") {
                        // Here would be the code to save changes
                        dismiss()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.green)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("\(formattedDate(selectedDay))")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // Helper function to format the selected date.
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
