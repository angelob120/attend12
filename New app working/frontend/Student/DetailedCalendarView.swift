//
//  DetailedCalendarView.swift
//  New app working
//
//  Created by AB on 1/9/25.
//

import SwiftUI


// MARK: - Custom Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct DetailedCalendarView: View {
    @Environment(\.colorScheme) var colorScheme
    // currentDate represents the month being displayed.
    @State private var currentDate = Date()
    
    // State variables for presenting sheets (pop-ups)
    @State private var showAlertSheet: Bool = false
    @State private var showTimeOffSheet: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
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
                                    let dayNumber = Calendar.current.component(.day, from: dayDate)
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
                                    .frame(width: 40, height: 40)
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
                
                // MARK: - Time Off Left Section (Same height as action buttons)
                HStack {
                    Text("Time Off Left:")
                        .bold()
                        .foregroundColor(.white)
                    Spacer()
                    Text("50 Hours - 12 days")
                        .foregroundColor(.white)
                    Text("(90%)")
                        .foregroundColor(.white)
                }
                .padding()
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Color.customGreen)
                .cornerRadius(10)
                .shadow(color: Color.customGreen.opacity(0.3), radius: 5, x: 0, y: 4)
                
                // MARK: - Action Buttons (Sheet Triggers)
                VStack(spacing: 10) {
                    Button(action: { showAlertSheet = true }) {
                        ActionButton(label: "Alert time off", color: .customGreen)
                    }
                    Button(action: { showTimeOffSheet = true }) {
                        ActionButton(label: "Time Off Details", color: .customGreen)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Calendar Details")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
        // Sheet modifiers for pop-up views
        .sheet(isPresented: $showAlertSheet) {
            RequestTimeOffView()
        }
        .sheet(isPresented: $showTimeOffSheet) {
            DetailedAttendanceListView()
        }
    }
    
    // MARK: - Helper Functions
    
    /// Generates a 2D array of optional Dates representing full weeks (Sun-Sat) for the current month.
    /// Dates falling outside the current month are represented by nil.
    func generateWeeks() -> [[Date?]] {
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
}

// MARK: - LegendItem with Multiple Shapes
struct LegendItem: View {
    let color: Color
    let text: String
    
    @ViewBuilder
    var shape: some View {
        if text == "Absences" {
            Rectangle()
                .fill(color)
                .frame(width: 10, height: 10)
        } else if text == "Tardies" {
            Triangle()
                .fill(color)
                .frame(width: 10, height: 10)
        } else {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
        }
    }
    
    var body: some View {
        HStack(spacing: 5) {
            shape
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - ActionButton
struct ActionButton: View {
    let label: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 50)
        .background(color)
        .cornerRadius(10)
        .shadow(color: color.opacity(0.2), radius: 5, x: 0, y: 4)
        .padding(.horizontal)
    }
}

struct DetailedCalendarView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                DetailedCalendarView()
            }
            .preferredColorScheme(.dark)
            
            NavigationView {
                DetailedCalendarView()
            }
            .preferredColorScheme(.light)
        }
    }
}
