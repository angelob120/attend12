//
//  FileMakerModels.swift
//  New app working
//
//  Created by AB on 4/16/25.
//  Core model definitions for FileMaker integration

import Foundation
import CoreLocation
import SwiftUI

// MARK: - FileMaker Table Names
struct FMTable {
    static let attendance = "Attendance"
    static let mentee = "Mentees"
    static let user = "Users"
}

// MARK: - FileMaker Field Names
struct AttendanceFields {
    static let id = "id"
    static let menteeID = "menteeID"
    static let date = "date"
    static let clockInTime = "clockInTime"
    static let clockOutTime = "clockOutTime"
    static let status = "status"
    static let location = "location" // Stored as lat,long string
}

struct MenteeFields {
    static let id = "id"
    static let name = "name"
    static let email = "email"
    static let phone = "phone"
    static let progress = "progress"
    static let monitorID = "monitorID"
    static let imageName = "imageName"
}

struct UserFields {
    static let id = "id"
    static let name = "name"
    static let email = "email"
    static let phone = "phone"
    static let role = "role"
    static let status = "status"
    static let vacationDays = "vacationDays"
    static let timeOffBalance = "timeOffBalance"
    static let deviceUUID = "deviceUUID"
    static let mentorName = "mentorName"
    static let classType = "classType"
    static let timeSlot = "timeSlot"
    static let classCode = "classCode"
    static let onboardingComplete = "onboardingComplete"
}

// MARK: - Attendance Status Enum
enum AttendanceStatusFM: String, Codable, CaseIterable {
    case present
    case absent
    case tardy
    
    // Convert from AppAttendanceStatus enum used in the app
    static func fromAppStatus(_ status: AppAttendanceStatus) -> AttendanceStatusFM {
        switch status {
        case .present:
            return .present
        case .absent:
            return .absent
        case .tardy:
            return .tardy
        }
    }
    
    // Convert to AppAttendanceStatus enum used in the app
    func toAppStatus() -> AppAttendanceStatus {
        switch self {
        case .present:
            return .present
        case .absent:
            return .absent
        case .tardy:
            return .tardy
        }
    }
    
    var color: Color {
        switch self {
        case .present:
            return .green
        case .absent:
            return .red
        case .tardy:
            return .yellow
        }
    }
}

// MARK: - User Role Enum
enum UserRoleFM: String, Codable, CaseIterable {
    case student
    case mentor
    case admin
    case pending
    
    var displayName: String {
        switch self {
        case .student:
            return "Student"
        case .mentor:
            return "Mentor"
        case .admin:
            return "Admin"
        case .pending:
            return "Pending"
        }
    }
    
    var iconName: String {
        switch self {
        case .student:
            return "graduationcap.fill"
        case .mentor:
            return "person.2.fill"
        case .admin:
            return "shield.fill"
        case .pending:
            return "person.badge.plus.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .student:
            return .blue
        case .mentor:
            return .green
        case .admin:
            return .red
        case .pending:
            return .gray
        }
    }
}

// MARK: - User Status Enum
enum UserStatusFM: String, Codable, CaseIterable {
    case active
    case inactive
    case pending
    
    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Date Formatters
let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()

let dateTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    return formatter
}()

// MARK: - FileMaker Record Protocol
/// Protocol for FileMaker record compatibility
protocol FileMakerRecord {
    var id: UUID { get }
    
    // Convert to dictionary for FileMaker API
    func toFileMakerDictionary() -> [String: Any]
    
    // Create from FileMaker API response
    static func fromFileMakerDictionary(_ dictionary: [String: Any]) -> Self?
}

// MARK: - FileMaker Error
enum FileMakerError: Error {
    case recordNotFound
    case authenticationFailed
    case networkError
    case permissionError
    case invalidResponse
    case unexpectedError(Error)
}

// MARK: - Data Models

// AttendanceRecordFM Model
struct AttendanceRecordFM: Identifiable, FileMakerRecord {
    let id: UUID
    let menteeID: UUID
    let date: Date
    let clockInTime: Date
    var clockOutTime: Date // Changed from 'let' to 'var' to allow modification
    var status: AttendanceStatusFM // Changed from 'let' to 'var' to allow modification
    let location: CLLocation?
    var recordId: String? // FileMaker record ID
    
    init(id: UUID = UUID(), menteeID: UUID, date: Date, clockInTime: Date, clockOutTime: Date, status: AttendanceStatusFM, location: CLLocation? = nil, recordId: String? = nil) {
        self.id = id
        self.menteeID = menteeID
        self.date = date
        self.clockInTime = clockInTime
        self.clockOutTime = clockOutTime
        self.status = status
        self.location = location
        self.recordId = recordId
    }
    
    // Convert to FileMaker dictionary
    func toFileMakerDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            AttendanceFields.id: id.uuidString,
            AttendanceFields.menteeID: menteeID.uuidString,
            AttendanceFields.date: dateFormatter.string(from: date),
            AttendanceFields.clockInTime: dateTimeFormatter.string(from: clockInTime),
            AttendanceFields.clockOutTime: dateTimeFormatter.string(from: clockOutTime),
            AttendanceFields.status: status.rawValue
        ]
        
        // Add location if available
        if let location = location {
            dict[AttendanceFields.location] = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
        }
        
        return dict
    }
    
    // Create from FileMaker dictionary
    static func fromFileMakerDictionary(_ dictionary: [String: Any]) -> AttendanceRecordFM? {
        guard let idString = dictionary[AttendanceFields.id] as? String,
              let id = UUID(uuidString: idString),
              let menteeIDString = dictionary[AttendanceFields.menteeID] as? String,
              let menteeID = UUID(uuidString: menteeIDString),
              let dateString = dictionary[AttendanceFields.date] as? String,
              let date = dateFormatter.date(from: dateString),
              let clockInString = dictionary[AttendanceFields.clockInTime] as? String,
              let clockInTime = dateTimeFormatter.date(from: clockInString),
              let clockOutString = dictionary[AttendanceFields.clockOutTime] as? String,
              let clockOutTime = dateTimeFormatter.date(from: clockOutString),
              let statusString = dictionary[AttendanceFields.status] as? String,
              let status = AttendanceStatusFM(rawValue: statusString) else {
            return nil
        }
        
        // Parse location if available
        var location: CLLocation? = nil
        if let locationString = dictionary[AttendanceFields.location] as? String {
            let components = locationString.split(separator: ",")
            if components.count == 2,
               let latitude = Double(components[0]),
               let longitude = Double(components[1]) {
                location = CLLocation(latitude: latitude, longitude: longitude)
            }
        }
        
        // Get FileMaker recordId if available
        let recordId = dictionary["recordId"] as? String
        
        return AttendanceRecordFM(
            id: id,
            menteeID: menteeID,
            date: date,
            clockInTime: clockInTime,
            clockOutTime: clockOutTime,
            status: status,
            location: location,
            recordId: recordId
        )
    }
}

// MenteeFM Model
struct MenteeFM: Identifiable, FileMakerRecord {
    let id: UUID
    let name: String
    let email: String
    let phone: String
    let progress: Int
    let monitorID: UUID?
    let imageName: String
    var recordId: String? // FileMaker record ID
    
    init(id: UUID = UUID(), name: String, email: String, phone: String, progress: Int, monitorID: UUID? = nil, imageName: String = "profile1", recordId: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.progress = progress
        self.monitorID = monitorID
        self.imageName = imageName
        self.recordId = recordId
    }
    
    // Convert to FileMaker dictionary
    func toFileMakerDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            MenteeFields.id: id.uuidString,
            MenteeFields.name: name,
            MenteeFields.email: email,
            MenteeFields.phone: phone,
            MenteeFields.progress: progress,
            MenteeFields.imageName: imageName
        ]
        
        // Add monitorID if available
        if let monitorID = monitorID {
            dict[MenteeFields.monitorID] = monitorID.uuidString
        }
        
        return dict
    }
    
    // Create from FileMaker dictionary
    static func fromFileMakerDictionary(_ dictionary: [String: Any]) -> MenteeFM? {
        guard let idString = dictionary[MenteeFields.id] as? String,
              let id = UUID(uuidString: idString),
              let name = dictionary[MenteeFields.name] as? String,
              let email = dictionary[MenteeFields.email] as? String,
              let phone = dictionary[MenteeFields.phone] as? String,
              let progress = dictionary[MenteeFields.progress] as? Int else {
            return nil
        }
        
        // Parse monitorID if available
        var monitorID: UUID? = nil
        if let monitorIDString = dictionary[MenteeFields.monitorID] as? String {
            monitorID = UUID(uuidString: monitorIDString)
        }
        
        // Get image name (or use default)
        let imageName = dictionary[MenteeFields.imageName] as? String ?? "profile1"
        
        // Get FileMaker recordId if available
        let recordId = dictionary["recordId"] as? String
        
        return MenteeFM(
            id: id,
            name: name,
            email: email,
            phone: phone,
            progress: progress,
            monitorID: monitorID,
            imageName: imageName,
            recordId: recordId
        )
    }
}

// UserFM Model
struct UserFM: Identifiable, FileMakerRecord {
    let id: UUID
    let name: String
    let email: String
    let phone: String
    var role: UserRoleFM // Changed from 'let' to 'var' to allow modification
    var status: UserStatusFM // Changed from 'let' to 'var' to allow modification
    var vacationDays: Int // Changed from 'let' to 'var' to allow modification
    var timeOffBalance: Double // Changed from 'let' to 'var' to allow modification
    var recordId: String? // FileMaker record ID
    
    // Additional fields
    var mentorName: String?
    var classType: String?
    var timeSlot: String?
    var classCode: String?
    var deviceUUID: String?
    var onboardingComplete: Bool?
    
    init(id: UUID = UUID(), name: String, email: String, phone: String, role: UserRoleFM, status: UserStatusFM, vacationDays: Int, timeOffBalance: Double, recordId: String? = nil, mentorName: String? = nil, classType: String? = nil, timeSlot: String? = nil, classCode: String? = nil, deviceUUID: String? = nil, onboardingComplete: Bool? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.role = role
        self.status = status
        self.vacationDays = vacationDays
        self.timeOffBalance = timeOffBalance
        self.recordId = recordId
        self.mentorName = mentorName
        self.classType = classType
        self.timeSlot = timeSlot
        self.classCode = classCode
        self.deviceUUID = deviceUUID
        self.onboardingComplete = onboardingComplete
    }
    
    // Convert to FileMaker dictionary
    func toFileMakerDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            UserFields.id: id.uuidString,
            UserFields.name: name,
            UserFields.email: email,
            UserFields.phone: phone,
            UserFields.role: role.rawValue,
            UserFields.status: status.rawValue,
            UserFields.vacationDays: vacationDays,
            UserFields.timeOffBalance: timeOffBalance
        ]
        
        // Add optional fields if available
        if let mentorName = mentorName {
            dict[UserFields.mentorName] = mentorName
        }
        if let classType = classType {
            dict[UserFields.classType] = classType
        }
        if let timeSlot = timeSlot {
            dict[UserFields.timeSlot] = timeSlot
        }
        if let classCode = classCode {
            dict[UserFields.classCode] = classCode
        }
        if let deviceUUID = deviceUUID {
            dict[UserFields.deviceUUID] = deviceUUID
        }
        if let onboardingComplete = onboardingComplete {
            dict[UserFields.onboardingComplete] = onboardingComplete
        }
        
        return dict
    }
    
    // Create from FileMaker dictionary
    static func fromFileMakerDictionary(_ dictionary: [String: Any]) -> UserFM? {
        guard let idString = dictionary[UserFields.id] as? String,
              let id = UUID(uuidString: idString),
              let name = dictionary[UserFields.name] as? String,
              let email = dictionary[UserFields.email] as? String,
              let phone = dictionary[UserFields.phone] as? String,
              let roleString = dictionary[UserFields.role] as? String,
              let role = UserRoleFM(rawValue: roleString),
              let statusString = dictionary[UserFields.status] as? String,
              let status = UserStatusFM(rawValue: statusString),
              let vacationDays = dictionary[UserFields.vacationDays] as? Int,
              let timeOffBalance = dictionary[UserFields.timeOffBalance] as? Double else {
            return nil
        }
        
        // Get FileMaker recordId if available
        let recordId = dictionary["recordId"] as? String
        
        // Get optional fields
        let mentorName = dictionary[UserFields.mentorName] as? String
        let classType = dictionary[UserFields.classType] as? String
        let timeSlot = dictionary[UserFields.timeSlot] as? String
        let classCode = dictionary[UserFields.classCode] as? String
        let deviceUUID = dictionary[UserFields.deviceUUID] as? String
        let onboardingComplete = dictionary[UserFields.onboardingComplete] as? Bool
        
        return UserFM(
            id: id,
            name: name,
            email: email,
            phone: phone,
            role: role,
            status: status,
            vacationDays: vacationDays,
            timeOffBalance: timeOffBalance,
            recordId: recordId,
            mentorName: mentorName,
            classType: classType,
            timeSlot: timeSlot,
            classCode: classCode,
            deviceUUID: deviceUUID,
            onboardingComplete: onboardingComplete
        )
    }
    
    // Convert to app's AppUser1 type
    func toAppModel() -> AppUser1 {
        return AppUser1(
            name: name,
            status: status.rawValue.capitalized,
            role: role.rawValue.capitalized,
            phoneNumber: phone,
            email: email,
            monitorName: mentorName ?? "Unassigned"
        )
    }
    
    // Create from the app's AppUser1 type
    static func fromAppUser(_ user: AppUser1) -> UserFM {
        let roleFM: UserRoleFM
        switch user.role.lowercased() {
        case "admin":
            roleFM = .admin
        case "mentor":
            roleFM = .mentor
        case "pending":
            roleFM = .pending
        default:
            roleFM = .student
        }
        
        let statusFM: UserStatusFM
        switch user.status.lowercased() {
        case "active":
            statusFM = .active
        case "pending", "pending invitation":
            statusFM = .pending
        default:
            statusFM = .inactive
        }
        
        return UserFM(
            name: user.name,
            email: user.email,
            phone: user.phoneNumber,
            role: roleFM,
            status: statusFM,
            vacationDays: 10, // Default value
            timeOffBalance: 80.0, // Default value
            mentorName: user.monitorName
        )
    }
}

// MARK: - User Profile for FileMaker
struct UserProfileFM {
    // Basic user information
    var name: String = ""
    var email: String = ""
    var phone: String = ""
    var role: UserRoleFM = .student
    
    // Educational information
    var mentorName: String = ""
    var classType: String = ""
    var timeSlot: String = ""
    var classCode: String = ""
    
    // Status
    var onboardingComplete: Bool = false
    
    // Vacation and time off
    var vacationDays: Int = 96
    var timeOffBalance: Double = 768.0 // 96 days × 8 hours
    
    // Device information for automatic login
    var deviceUUID: String = ""
    
    init() {
        // Default initializer creates an empty profile
    }
    
    init(name: String, email: String, phone: String, role: UserRoleFM = .student,
         mentorName: String = "", classType: String = "", timeSlot: String = "",
         classCode: String = "", onboardingComplete: Bool = false) {
        self.name = name
        self.email = email
        self.phone = phone
        self.role = role
        self.mentorName = mentorName
        self.classType = classType
        self.timeSlot = timeSlot
        self.classCode = classCode
        self.onboardingComplete = onboardingComplete
    }
    
    /// Convert to a dictionary for storage
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "name": name,
            "email": email,
            "phone": phone,
            "role": role.rawValue,
            "mentorName": mentorName,
            "classType": classType,
            "timeSlot": timeSlot,
            "classCode": classCode,
            "onboardingComplete": onboardingComplete,
            "vacationDays": vacationDays,
            "timeOffBalance": timeOffBalance
        ]
        
        if !deviceUUID.isEmpty {
            dict["deviceUUID"] = deviceUUID
        }
        
        return dict
    }
    
    /// Create a profile from a dictionary
    static func fromDictionary(_ dict: [String: Any]) -> UserProfileFM {
        var profile = UserProfileFM()
        
        if let name = dict["name"] as? String {
            profile.name = name
        }
        
        if let email = dict["email"] as? String {
            profile.email = email
        }
        
        if let phone = dict["phone"] as? String {
            profile.phone = phone
        }
        
        if let roleString = dict["role"] as? String,
           let role = UserRoleFM(rawValue: roleString) {
            profile.role = role
        }
        
        if let mentorName = dict["mentorName"] as? String {
            profile.mentorName = mentorName
        }
        
        if let classType = dict["classType"] as? String {
            profile.classType = classType
        }
        
        if let timeSlot = dict["timeSlot"] as? String {
            profile.timeSlot = timeSlot
        }
        
        if let classCode = dict["classCode"] as? String {
            profile.classCode = classCode
        }
        
        if let onboardingComplete = dict["onboardingComplete"] as? Bool {
            profile.onboardingComplete = onboardingComplete
        }
        
        if let vacationDays = dict["vacationDays"] as? Int {
            profile.vacationDays = vacationDays
        }
        
        if let timeOffBalance = dict["timeOffBalance"] as? Double {
            profile.timeOffBalance = timeOffBalance
        }
        
        if let deviceUUID = dict["deviceUUID"] as? String {
            profile.deviceUUID = deviceUUID
        }
        
        return profile
    }
}

// MARK: - Helper Extensions for FileMaker API
extension DateFormatter {
    // FileMaker date format: 'MM/dd/yyyy'
    static var fileMakerDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter
    }
    
    // FileMaker time stamp format: 'MM/dd/yyyy HH:mm:ss'
    static var fileMakerTimeStampFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy HH:mm:ss"
        return formatter
    }
}

// MARK: - Model Conversion Extensions
extension AttendanceRecord {
    // Convert to FileMaker-compatible type
    func toFileMakerRecord(menteeID: UUID) -> AttendanceRecordFM {
        return AttendanceRecordFM(
            menteeID: menteeID,
            date: date,
            clockInTime: clockInTime,
            clockOutTime: clockOutTime,
            status: AttendanceStatusFM.fromAppStatus(status)
        )
    }
}

extension Mentee {
    func toFileMakerModel(monitorID: UUID? = nil) -> MenteeFM {
        return MenteeFM(
            name: name,
            email: email,
            phone: phone,
            progress: progress,
            monitorID: monitorID,
            imageName: imageName
        )
    }
}

extension AppUser1 {
    func toFileMakerModel() -> UserFM {
        return UserFM.fromAppUser(self)
    }
}
