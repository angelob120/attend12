//
//  MyMentees.swift
//  New app working
//
//  Created by AB on 1/15/25.
//

import Foundation

let myMentees: [Mentee] = [
    Mentee(
        name: "Angelo Brown",
        progress: 90,
        email: "angelo.brown@example.com",
        phone: "123-456-7890",
        imageName: "profile1",
        attendanceRecords: generateMonthlyAttendanceData(for: Date())
    ),
    Mentee(
        name: "Emily Davis",
        progress: 85,
        email: "emily.davis@example.com",
        phone: "234-567-8901",
        imageName: "profile2",
        attendanceRecords: generateMonthlyAttendanceData(for: Date())
    )
]
