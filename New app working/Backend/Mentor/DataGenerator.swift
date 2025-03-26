//  DataGenerator.swift
//  New app working
//
//  Created by AB on 1/15/25.
//

import Foundation

func generateMonthlyAttendanceData1(for month: Date) -> [AttendanceRecord] {
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
