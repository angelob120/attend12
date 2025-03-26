//
//  RequestTimeForm.swift
//  New app working
//
//  Created by AB on 1/13/25.
//

import SwiftUI

struct RequestTimeForm: View {
    @State private var currentMonth = Date()
    @State private var selectedDates: Set<Date> = []  // Set to store multiple selected dates

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                calendarHeader

                weekdayHeader

                calendarGrid

                submitButton

                Spacer()
            }
            .padding()
            .navigationTitle("Request Time Off")
        }
    }

    // MARK: - Calendar Header (Month Navigation)

    private var calendarHeader: some View {
        HStack {
            Button(action: { changeMonth(by: -1) }) {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(monthYearFormatter.string(from: currentMonth))
                .font(.title2)
                .bold()
            Spacer()
            Button(action: { changeMonth(by: 1) }) {
                Image(systemName: "chevron.right")
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        HStack {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.subheadline)
                    .bold()
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let daysInMonth = currentMonth.requestDaysInMonth
        let firstWeekday = currentMonth.requestFirstWeekdayOfMonth
        let totalCells = daysInMonth + firstWeekday - 1
        let weeks = Int(ceil(Double(totalCells) / 7.0))

        return VStack(spacing: 10) {
            ForEach(0..<weeks, id: \.self) { week in
                HStack(spacing: 10) {
                    ForEach(0..<7, id: \.self) { day in
                        calendarDay(for: week, day: day, firstWeekday: firstWeekday, daysInMonth: daysInMonth)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private func calendarDay(for week: Int, day: Int, firstWeekday: Int, daysInMonth: Int) -> some View {
        let dayNumber = week * 7 + day - firstWeekday + 2

        return Group {
            if dayNumber > 0 && dayNumber <= daysInMonth {
                let date = currentMonth.requestGetDate(day: dayNumber)

                ZStack {
                    if selectedDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: date) }) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 35, height: 35)
                    }

                    Text("\(dayNumber)")
                        .foregroundColor(selectedDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: date) }) ? .white : .black)
                        .font(.headline)
                }
                .frame(width: 40, height: 40)
                .onTapGesture {
                    toggleDateSelection(date)
                }
            } else {
                Spacer()
                    .frame(width: 40, height: 40)
            }
        }
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button(action: submitRequest) {
            Text("Submit Request")
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(selectedDates.isEmpty ? Color.gray : Color.blue)
                .cornerRadius(10)
        }
        .disabled(selectedDates.isEmpty)
        .padding()
    }

    // MARK: - Helper Functions

    private func toggleDateSelection(_ date: Date) {
        if let existingDate = selectedDates.first(where: { Calendar.current.isDate($0, inSameDayAs: date) }) {
            selectedDates.remove(existingDate)
        } else {
            selectedDates.insert(date)
        }
    }

    private func changeMonth(by value: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }

    private func submitRequest() {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        for date in selectedDates.sorted() {
            print("Requested Time Off: \(formatter.string(from: date))")
        }

        // Clear selection after submission
        selectedDates.removeAll()
    }

    // MARK: - Formatters and Helpers

    private var weekdays: [String] {
        ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    }

    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }
}

// MARK: - Date Extensions

extension Date {
    var requestDay: Int {
        Calendar.current.component(.day, from: self)
    }

    var requestDaysInMonth: Int {
        Calendar.current.range(of: .day, in: .month, for: self)?.count ?? 30
    }

    var requestFirstWeekdayOfMonth: Int {
        let components = Calendar.current.dateComponents([.year, .month], from: self)
        let firstOfMonth = Calendar.current.date(from: components)!
        return Calendar.current.component(.weekday, from: firstOfMonth)
    }

    func requestGetDate(day: Int) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(bySetting: .day, value: day, of: calendar.date(from: components)!)!
    }
}
