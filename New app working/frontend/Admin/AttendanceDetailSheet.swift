//
//  AttendanceDetailSheet.swift
//  New app working
//
//  Created by AB on 1/29/25.
//

import SwiftUI

struct AttendanceRecord2 {
    let date: Date
    let clockIn: Date
    let clockOut: Date
    let color: Color  // Ensure color is included
}

struct AttendanceDetailSheet: View {
    let record: AttendanceRecord1
    
    var body: some View {
        VStack {
            Text("Attendance Details")
                .font(.title)
                .padding()

            Text("Date: \(formattedDate(record.date))")
                .font(.headline)
                .padding(.bottom)

            VStack(spacing: 10) {
                HStack {
                    Text("Clock In:")
                        .font(.subheadline)
                    Spacer()
                    Text(formattedTime(record.clockIn))
                }
                .padding()

                HStack {
                    Text("Clock Out:")
                        .font(.subheadline)
                    Spacer()
                    Text(formattedTime(record.clockOut))
                }
                .padding()
            }
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.2)))
            .padding()
            
            Spacer()
        }
        .padding()
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct AttendanceDetailSheet_Previews: PreviewProvider {
    static var previews: some View {
        AttendanceDetailSheet(record: AttendanceRecord1(
            date: Date(),
            clockIn: Date(),
            clockOut: Date().addingTimeInterval(3600)
        ))
    }
}
