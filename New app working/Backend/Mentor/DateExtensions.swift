//
//  DateExtensions.swift
//  New app working
//
//  Created by AB on 1/15/25.
//

import Foundation

extension Date {
    
    /// Returns the total number of days in the current month
    var totalDaysInMonth1: Int {
        Calendar.current.range(of: .day, in: .month, for: self)?.count ?? 30
    }

    /// Returns the weekday of the first day of the month (1 = Sunday, 7 = Saturday)
    var firstDayOfMonthWeekday1: Int {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        guard let firstOfMonth = Calendar.current.date(from: components) else { return 1 }
        return Calendar.current.component(.weekday, from: firstOfMonth)
    }

    /// Returns a date with a specified day of the current month
    func dateBySetting1(day: Int) -> Date? {
        var components = Calendar.current.dateComponents([.year, .month], from: self)
        components.day = day
        return Calendar.current.date(from: components)
    }
}
