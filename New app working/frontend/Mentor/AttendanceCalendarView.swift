//
//  AttendanceCalendarView.swift
//  New app working
//
//  Created by AB on 1/15/25.
//

import SwiftUI

struct AttendanceCalendarView: View {
    let attendanceRecords: [AttendanceRecord]
    @State private var selectedDate = Date()
    @State private var showAttendanceDetail = false
    @State private var selectedRecord: AttendanceRecord?
    
    var body: some View {
        VStack(spacing: 20) {
            
            // MARK: - Month Navigation
            HStack {
                Button(action: { changeMonth(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(monthYearFormatter.string(from: selectedDate))
                    .font(.title2)
                    .bold()
                
                Spacer()
                
                Button(action: { changeMonth(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // MARK: - Weekday Headers
            HStack {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.subheadline)
                        .bold()
                        .frame(maxWidth: .infinity)
                }
            }
            
            // MARK: - Calendar Grid
            let daysInMonth = selectedDate.totalDaysInMonth
            let firstWeekday = selectedDate.firstDayOfMonthWeekday
            let totalCells = daysInMonth + firstWeekday - 1
            let weeks = Int(ceil(Double(totalCells) / 7.0))
            
            VStack(spacing: 10) {
                ForEach(0..<weeks, id: \.self) { week in
                    HStack(spacing: 10) {
                        ForEach(0..<7, id: \.self) { day in
                            let dayNumber = week * 7 + day - firstWeekday + 2
                            
                            if dayNumber > 0 && dayNumber <= daysInMonth {
                                if let date = selectedDate.dateBySetting(day: dayNumber) {
                                    let status = attendanceStatus(for: date)
                                    
                                    ZStack {
                                        Circle()
                                            .fill(color(for: status))
                                            .frame(width: 35, height: 35)
                                        
                                        Text("\(dayNumber)")
                                            .foregroundColor(.white)
                                            .font(.headline)
                                    }
                                    .frame(width: 40, height: 40)
                                    .onTapGesture {
                                        if let record = attendanceRecords.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                                            selectedRecord = record
                                            showAttendanceDetail = true
                                        }
                                    }
                                }
                            } else {
                                Text("")  // Empty cell for alignment
                                    .frame(width: 40, height: 40)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            // MARK: - Legend
            HStack(spacing: 20) {
                AttendanceLegendItem(color: .blue, text: "Present")
                AttendanceLegendItem(color: .red, text: "Absent")
                AttendanceLegendItem(color: .yellow, text: "Tardy")
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showAttendanceDetail) {
            if let record = selectedRecord {
                AttendanceDetailView(record: record)
            }
        }
    }
    
    // MARK: - Helper Functions
    private func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func attendanceStatus(for date: Date) -> AppAttendanceStatus? {
        return attendanceRecords.first { Calendar.current.isDate($0.date, inSameDayAs: date) }?.status
    }
    
    private func color(for status: AppAttendanceStatus?) -> Color {
        switch status {
        case .present:
            return .blue
        case .absent:
            return .red
        case .tardy:
            return .yellow
        case nil:
            return .gray.opacity(0.3)
        }
    }
    
    private var weekdays: [String] {
        ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    }
    
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
}

struct AttendanceDetailView: View {
    let record: AttendanceRecord
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Attendance Details")
                .font(.title)
                .bold()
                
            Text("Date: \(record.date, formatter: dateFormatter)")
                .font(.headline)
                
            Text("Clock In: \(record.clockInTime, formatter: timeFormatter)")
                .font(.headline)
                
            Text("Clock Out: \(record.clockOutTime, formatter: timeFormatter)")
                .font(.headline)
                
            Spacer()
        }
        .padding()
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}
