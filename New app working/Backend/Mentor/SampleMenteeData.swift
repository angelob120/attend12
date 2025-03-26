//
//  SampleMenteeData.swift
//  New app working
//
//  Created by AB on 1/15/25.
//

import Foundation

struct SampleMenteeData {
    static let myMentees: [Mentee] = [
        Mentee(
            name: "Angelo Brown",
            progress: 90,
            email: "angelo@example.com",
            phone: "123-456-7890",
            imageName: "profile1",  // 🔹 Provide a valid image name
            attendanceRecords: generateMonthlyAttendanceData(for: Date())
        ),
        Mentee(
            name: "Jane Doe",
            progress: 80,
            email: "jane@example.com",
            phone: "123-555-7890",
            imageName: "profile2",
            attendanceRecords: generateMonthlyAttendanceData(for: Date())
        )
    ]

    static let allMentees: [Mentee] = [
        Mentee(
            name: "Mark Smith",
            progress: 75,
            email: "mark@example.com",
            phone: "555-456-7890",
            imageName: "profile3",
            attendanceRecords: generateMonthlyAttendanceData(for: Date())
        ),
        Mentee(
            name: "Emily White",
            progress: 85,
            email: "emily@example.com",
            phone: "999-555-7890",
            imageName: "profile4",
            attendanceRecords: generateMonthlyAttendanceData(for: Date())
        )
    ]
}
