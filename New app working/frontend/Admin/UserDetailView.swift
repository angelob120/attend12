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

                // Attendance Calendar
                Text("Attendance Calendar")
                    .font(.title2)
                    .padding(.top, 20)

                AlignedAttendanceCalendarView(
                    attendanceRecords1: $attendanceRecords1,
                    selectedRecord: $selectedRecord,
                    showEditSheet: $showEditSheet
                )
                .padding()

                Spacer()

                // Bottom Vertical Button Stack
                VStack(spacing: 12) {
                    // Edit Attendance
                    Button(action: {
                        if selectedRecord != nil {
                            showEditSheet = true
                        }
                    }) {
                        Text("Edit Attendance")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(selectedRecord == nil ? Color.gray : Color.blue)
                            .cornerRadius(8)
                    }
                    .disabled(selectedRecord == nil)

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
                        Button("Promote to Teacher") {
                            print("Promote to Teacher tapped")
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
    }
}

// MARK: - AlignedAttendanceCalendarView
struct AlignedAttendanceCalendarView: View {
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    @Binding var attendanceRecords1: [AttendanceRecord1]
    @Binding var selectedRecord: AttendanceRecord1?
    @Binding var showEditSheet: Bool
    @State private var calendarDates: [Date] = []

    private let dateFormatter = DateFormatter()
    private let dayOfWeekFormatter = DateFormatter()

    init(
        attendanceRecords1: Binding<[AttendanceRecord1]>,
        selectedRecord: Binding<AttendanceRecord1?>,
        showEditSheet: Binding<Bool>
    ) {
        self._attendanceRecords1 = attendanceRecords1
        self._selectedRecord = selectedRecord
        self._showEditSheet = showEditSheet

        dateFormatter.dateFormat = "d"
        dayOfWeekFormatter.dateFormat = "EEEEE"
    }

    private func generateAlignedDatesForCurrentMonth() {
        let calendar = Calendar.current
        let today = Date()

        guard
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today)),
            let rangeOfDays = calendar.range(of: .day, in: .month, for: today)
        else { return }

        let totalDaysInMonth = rangeOfDays.count
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let daysToSubtract = firstWeekday - 1
        let startDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: monthStart) ?? monthStart

        guard let lastDayOfMonth = calendar.date(byAdding: .day, value: totalDaysInMonth - 1, to: monthStart) else {
            return
        }

        let lastWeekday = calendar.component(.weekday, from: lastDayOfMonth)
        let daysToAdd = 7 - lastWeekday
        let endDate = calendar.date(byAdding: .day, value: daysToAdd, to: lastDayOfMonth) ?? lastDayOfMonth

        var tempDates: [Date] = []
        var currentDate = startDate
        while currentDate <= endDate {
            tempDates.append(currentDate)
            if let next = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = next
            } else {
                break
            }
        }
        self.calendarDates = tempDates
    }

    private func colorForWeekday(_ weekday: Int) -> Color {
        switch weekday {
        case 2:
            return .blue
        case 3:
            return .yellow
        case 4:
            return .red
        case 5:
            return .blue
        case 6:
            return .yellow
        default:
            return .gray
        }
    }

    var body: some View {
        VStack {
            // Days of the week header
            HStack {
                ForEach(0..<7, id: \.self) { index in
                    Text(dayOfWeekFormatter.safeShortWeekdaySymbol(at: index))
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar Grid
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(calendarDates, id: \.self) { date in
                    let calendar = Calendar.current
                    let isInCurrentMonth = calendar.isDate(date, equalTo: Date(), toGranularity: .month)
                    let weekday = calendar.component(.weekday, from: date)

                    if isInCurrentMonth {
                        if weekday != 1 && weekday != 7 {
                            let record = attendanceRecords1.first {
                                calendar.isDate($0.date, inSameDayAs: date)
                            }
                            VStack {
                                Text(dateFormatter.string(from: date))
                                    .frame(width: 30, height: 30)
                                    .background(
                                        Circle()
                                            .frame(width: 34, height: 34)
                                            .foregroundColor(colorForWeekday(weekday))
                                    )
                                    .foregroundColor(.white)
                            }
                            .frame(height: 40)
                            .onTapGesture {
                                if let record = record {
                                    selectedRecord = record
                                }
                            }
                        } else {
                            Text(dateFormatter.string(from: date))
                                .foregroundColor(.secondary)
                                .frame(height: 40)
                        }
                    } else {
                        Text("")
                            .frame(height: 40)
                    }
                }
            }
        }
        .onAppear {
            generateAlignedDatesForCurrentMonth()
        }
    }
}

// MARK: - Edit Attendance Sheet
struct EditAttendanceSheet: View {
    @State var record: AttendanceRecord1
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            Text("Edit Attendance for \(record.date, formatter: DateFormatter.shortDate)")
                .font(.title2)
                .padding()

            DatePicker("Clock In Time", selection: $record.clockIn, displayedComponents: .hourAndMinute)
                .datePickerStyle(WheelDatePickerStyle())
                .padding()

            DatePicker(
                "Clock Out Time",
                selection: $record.clockOut,
                in: record.clockIn...(record.clockIn.addingTimeInterval(4 * 3600)),
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(WheelDatePickerStyle())
            .padding()

            Button {
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
            .padding()
        }
        .frame(maxWidth: 400)
        .padding()
    }
}

// MARK: - Safe Extension for Short Weekday Symbols
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

// MARK: - AttendanceRecord1
struct AttendanceRecord1: Identifiable {
    let id = UUID()
    var date: Date
    var clockIn: Date
    var clockOut: Date
}
