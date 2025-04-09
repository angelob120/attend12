//
//  All Mentees.swift
//  New app working
//
//  Created by AB on 1/15/25.
//

import Foundation

let allMentees: [Mentee] = [
    Mentee(
        name: "Angelo Brown",
        progress: 90,
        email: "angelo.brown@example.com",
        phone: "123-456-7890",
        imageName: "profile1",
        attendanceRecords: [
            AttendanceRecord(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, status: .present, clockInTime: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date())!, clockOutTime: Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date())!),
            AttendanceRecord(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, status: .absent, clockInTime: Calendar.current.date(bySettingHour: 9, minute: 30, second: 0, of: Date())!, clockOutTime: Calendar.current.date(bySettingHour: 16, minute: 45, second: 0, of: Date())!)
        ]
    ),
    Mentee(
        name: "Emily Davis",
        progress: 85,
        email: "emily.davis@example.com",
        phone: "234-567-8901",
        imageName: "profile2",
        attendanceRecords: [
            AttendanceRecord(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, status: .present, clockInTime: Calendar.current.date(bySettingHour: 9, minute: 15, second: 0, of: Date())!, clockOutTime: Calendar.current.date(bySettingHour: 17, minute: 30, second: 0, of: Date())!),
            AttendanceRecord(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, status: .present, clockInTime: Calendar.current.date(bySettingHour: 8, minute: 45, second: 0, of: Date())!, clockOutTime: Calendar.current.date(bySettingHour: 17, minute: 15, second: 0, of: Date())!)
        ]
    ),
    Mentee(
        name: "Michael Johnson",
        progress: 75,
        email: "michael.johnson@example.com",
        phone: "345-678-9012",
        imageName: "profile3",
        attendanceRecords: [
            AttendanceRecord(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, status: .absent, clockInTime: Calendar.current.date(bySettingHour: 9, minute: 20, second: 0, of: Date())!, clockOutTime: Calendar.current.date(bySettingHour: 16, minute: 50, second: 0, of: Date())!),
            AttendanceRecord(date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, status: .present, clockInTime: Calendar.current.date(bySettingHour: 9, minute: 10, second: 0, of: Date())!, clockOutTime: Calendar.current.date(bySettingHour: 17, minute: 10, second: 0, of: Date())!)
        ]
    ),
    Mentee(
        name: "Jane Smith",
        progress: 95,
        email: "jane.smith@example.com",
        phone: "456-789-0123",
        imageName: "profile4",
        attendanceRecords: [
            AttendanceRecord(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, status: .present, clockInTime: Calendar.current.date(bySettingHour: 9, minute: 5, second: 0, of: Date())!, clockOutTime: Calendar.current.date(bySettingHour: 17, minute: 25, second: 0, of: Date())!),
            AttendanceRecord(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, status: .present, clockInTime: Calendar.current.date(bySettingHour: 9, minute: 35, second: 0, of: Date())!, clockOutTime: Calendar.current.date(bySettingHour: 17, minute: 40, second: 0, of: Date())!)
        ]
    )
]
