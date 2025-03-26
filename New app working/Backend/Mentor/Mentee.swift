//  Mentee.swift
//  New app working
//
//  Created by AB on 1/15/25.
//

import Foundation

struct Mentee: Identifiable {
    let id = UUID()
    let name: String
    let progress: Int
    let email: String
    let phone: String
    let imageName: String
    let attendanceRecords: [AttendanceRecord]
}

struct AttendanceRecord: Identifiable {
    let id = UUID()
    let date: Date
    let status: AttendanceStatus
    let clockInTime: Date
    let clockOutTime: Date
}

enum AttendanceStatus: CaseIterable {
    case present
    case absent
    case tardy
}

// MARK: - Generate Filler Data for the Month (Weekdays Only)
func generateMonthlyAttendanceData(for month: Date) -> [AttendanceRecord] {
    var records: [AttendanceRecord] = []
    let calendar = Calendar.current
    let totalDays = month.totalDaysInMonth

    for day in 1...totalDays {
        if let date = month.dateBySetting(day: day), !calendar.isDateInWeekend(date) {
            let randomStatus = AttendanceStatus.allCases.randomElement()!
            let clockInTime = calendar.date(bySettingHour: 9, minute: Int.random(in: 0...59), second: 0, of: date) ?? date
            let clockOutTime = calendar.date(bySettingHour: 17, minute: Int.random(in: 0...59), second: 0, of: date) ?? date
            
            records.append(AttendanceRecord(date: date, status: randomStatus, clockInTime: clockInTime, clockOutTime: clockOutTime))
        }
    }
    return records
}

extension Date {
    
    /// Returns the total number of days in the current month
    var totalDaysInMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: self)?.count ?? 30
    }

    /// Returns the weekday of the first day of the month (1 = Sunday, 7 = Saturday)
    var firstDayOfMonthWeekday: Int {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        guard let firstOfMonth = Calendar.current.date(from: components) else { return 1 }
        return Calendar.current.component(.weekday, from: firstOfMonth)
    }

    /// Returns a date with a specified day of the current month
    func dateBySetting(day: Int) -> Date? {
        var components = Calendar.current.dateComponents([.year, .month], from: self)
        components.day = day
        return Calendar.current.date(from: components)
    }
}
