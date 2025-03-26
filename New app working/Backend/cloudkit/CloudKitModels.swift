//
//  CloudKitModels.swift
//  New app working
//
//  Created by AB on 3/26/25.
//

import Foundation
import CloudKit
import CoreLocation

// MARK: - CKRecord Keys
struct RecordType {
    static let attendance = "Attendance"
    static let mentee = "Mentee"
    static let user = "User"
}

struct AttendanceKeys {
    static let id = "id"
    static let menteeID = "menteeID"
    static let date = "date"
    static let clockInTime = "clockInTime"
    static let clockOutTime = "clockOutTime"
    static let status = "status"
    static let location = "location"
}

struct MenteeKeys {
    static let id = "id"
    static let name = "name"
    static let email = "email"
    static let phone = "phone"
    static let progress = "progress"
    static let monitorID = "monitorID"
}

struct UserKeys {
    static let id = "id"
    static let name = "name"
    static let email = "email"
    static let phone = "phone"
    static let role = "role"
    static let status = "status"
    static let vacationDays = "vacationDays"
    static let timeOffBalance = "timeOffBalance"
}

// MARK: - Attendance Status Enum with CK Support
enum AttendanceStatusCK: String, Codable, CaseIterable {
    case present
    case absent
    case tardy
    
    var recordValue: String {
        return self.rawValue
    }
    
    static func from(recordValue: String) -> AttendanceStatusCK? {
        return AttendanceStatusCK(rawValue: recordValue)
    }
}

// MARK: - User Role Enum with CK Support
enum UserRoleCK: String, Codable {
    case student
    case mentor
    case admin
    
    var recordValue: String {
        return self.rawValue
    }
    
    static func from(recordValue: String) -> UserRoleCK? {
        return UserRoleCK(rawValue: recordValue)
    }
}

// MARK: - User Status Enum with CK Support
enum UserStatusCK: String, Codable {
    case active
    case pending
    case inactive
    
    var recordValue: String {
        return self.rawValue
    }
    
    static func from(recordValue: String) -> UserStatusCK? {
        return UserStatusCK(rawValue: recordValue)
    }
}

// MARK: - CKRecord Extensions
extension CKRecord {
    // Create Attendance Record
    convenience init(attendance: AttendanceRecordCK) {
        self.init(recordType: "Attendance")
        
        self[AttendanceKeys.id] = attendance.id.uuidString
        self[AttendanceKeys.menteeID] = attendance.menteeID.uuidString
        self[AttendanceKeys.date] = attendance.date
        self[AttendanceKeys.clockInTime] = attendance.clockInTime
        self[AttendanceKeys.clockOutTime] = attendance.clockOutTime
        self[AttendanceKeys.status] = attendance.status.recordValue
        
        if let location = attendance.location {
            self[AttendanceKeys.location] = location
        }
    }
    
    // Create Mentee Record
    convenience init(mentee: MenteeCK) {
        self.init(recordType: "Mentee")
        
        self[MenteeKeys.id] = mentee.id.uuidString
        self[MenteeKeys.name] = mentee.name
        self[MenteeKeys.email] = mentee.email
        self[MenteeKeys.phone] = mentee.phone
        self[MenteeKeys.progress] = mentee.progress
        
        if let monitorID = mentee.monitorID {
            self[MenteeKeys.monitorID] = monitorID.uuidString
        }
    }
    
    // Create User Record
    convenience init(user: UserCK) {
        self.init(recordType: "User")
        
        self[UserKeys.id] = user.id.uuidString
        self[UserKeys.name] = user.name
        self[UserKeys.email] = user.email
        self[UserKeys.phone] = user.phone
        self[UserKeys.role] = user.role.recordValue
        self[UserKeys.status] = user.status.recordValue
        self[UserKeys.vacationDays] = user.vacationDays
        self[UserKeys.timeOffBalance] = user.timeOffBalance
    }
    
    // Convert CKRecord to AttendanceRecordCK
    func toAttendanceRecord() -> AttendanceRecordCK? {
        guard let idString = self[AttendanceKeys.id] as? String,
              let id = UUID(uuidString: idString),
              let menteeIDString = self[AttendanceKeys.menteeID] as? String,
              let menteeID = UUID(uuidString: menteeIDString),
              let date = self[AttendanceKeys.date] as? Date,
              let clockInTime = self[AttendanceKeys.clockInTime] as? Date,
              let clockOutTime = self[AttendanceKeys.clockOutTime] as? Date,
              let statusString = self[AttendanceKeys.status] as? String,
              let status = AttendanceStatusCK.from(recordValue: statusString) else {
            return nil
        }
        
        let location = self[AttendanceKeys.location] as? CLLocation
        
        return AttendanceRecordCK(
            id: id,
            menteeID: menteeID,
            date: date,
            clockInTime: clockInTime,
            clockOutTime: clockOutTime,
            status: status,
            location: location,
            record: self
        )
    }
    
    // Convert CKRecord to MenteeCK
    func toMentee() -> MenteeCK? {
        guard let idString = self[MenteeKeys.id] as? String,
              let id = UUID(uuidString: idString),
              let name = self[MenteeKeys.name] as? String,
              let email = self[MenteeKeys.email] as? String,
              let phone = self[MenteeKeys.phone] as? String,
              let progress = self[MenteeKeys.progress] as? Int else {
            return nil
        }
        
        var monitorID: UUID? = nil
        if let monitorIDString = self[MenteeKeys.monitorID] as? String {
            monitorID = UUID(uuidString: monitorIDString)
        }
        
        return MenteeCK(
            id: id,
            name: name,
            email: email,
            phone: phone,
            progress: progress,
            monitorID: monitorID,
            record: self
        )
    }
    
    // Convert CKRecord to UserCK
    func toUser() -> UserCK? {
        guard let idString = self[UserKeys.id] as? String,
              let id = UUID(uuidString: idString),
              let name = self[UserKeys.name] as? String,
              let email = self[UserKeys.email] as? String,
              let phone = self[UserKeys.phone] as? String,
              let roleString = self[UserKeys.role] as? String,
              let role = UserRoleCK.from(recordValue: roleString),
              let statusString = self[UserKeys.status] as? String,
              let status = UserStatusCK.from(recordValue: statusString),
              let vacationDays = self[UserKeys.vacationDays] as? Int,
              let timeOffBalance = self[UserKeys.timeOffBalance] as? Double else {
            return nil
        }
        
        return UserCK(
            id: id,
            name: name,
            email: email,
            phone: phone,
            role: role,
            status: status,
            vacationDays: vacationDays,
            timeOffBalance: timeOffBalance,
            record: self
        )
    }
}

// MARK: - Data Models
struct AttendanceRecordCK: Identifiable {
    let id: UUID
    let menteeID: UUID
    let date: Date
    let clockInTime: Date
    let clockOutTime: Date
    let status: AttendanceStatusCK
    let location: CLLocation?
    var record: CKRecord?
    
    init(id: UUID = UUID(), menteeID: UUID, date: Date, clockInTime: Date, clockOutTime: Date, status: AttendanceStatusCK, location: CLLocation? = nil, record: CKRecord? = nil) {
        self.id = id
        self.menteeID = menteeID
        self.date = date
        self.clockInTime = clockInTime
        self.clockOutTime = clockOutTime
        self.status = status
        self.location = location
        self.record = record
    }
}

struct MenteeCK: Identifiable {
    let id: UUID
    let name: String
    let email: String
    let phone: String
    let progress: Int
    let monitorID: UUID?
    var record: CKRecord?
    
    init(id: UUID = UUID(), name: String, email: String, phone: String, progress: Int, monitorID: UUID? = nil, record: CKRecord? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.progress = progress
        self.monitorID = monitorID
        self.record = record
    }
}

struct UserCK: Identifiable {
    let id: UUID
    let name: String
    let email: String
    let phone: String
    let role: UserRoleCK
    let status: UserStatusCK
    let vacationDays: Int
    let timeOffBalance: Double
    var record: CKRecord?
    
    init(id: UUID = UUID(), name: String, email: String, phone: String, role: UserRoleCK, status: UserStatusCK, vacationDays: Int, timeOffBalance: Double, record: CKRecord? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.role = role
        self.status = status
        self.vacationDays = vacationDays
        self.timeOffBalance = timeOffBalance
        self.record = record
    }
}
