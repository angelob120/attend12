//
//  CloudKitService.swift
//  New app working
//
//  Created by AB on 3/26/25.
//  Modified to work without iCloud

import Foundation
import CloudKit
import Combine
import CoreLocation

// MARK: - CloudKit Error
enum CloudKitError: Error {
    case recordNotFound
    case iCloudAccountNotFound
    case networkError
    case permissionError
    case unexpectedRecordType
    case unexpectedError(Error)
}

// MARK: - CloudKit Service
class CloudKitService: ObservableObject {
    static let shared = CloudKitService()
    
    private let container: CKContainer
    private let publicDB: CKDatabase
    private let privateDB: CKDatabase
    private let sharedDB: CKDatabase
    
    @Published var isUserSignedIn = true // Always true to bypass iCloud requirement
    @Published var userName: String = "Demo User" // Default user name
    @Published var permissionStatus: Bool = true // Default permission status
    
    // Local storage for records when CloudKit is unavailable
    private var localAttendanceRecords: [UUID: AttendanceRecordCK] = [:]
    private var localMenteeRecords: [UUID: MenteeCK] = [:]
    private var localUserRecords: [UUID: UserCK] = [:]
    
    // Private singleton initializer
    private init() {
        container = CKContainer.default()
        publicDB = container.publicCloudDatabase
        privateDB = container.privateCloudDatabase
        sharedDB = container.sharedCloudDatabase
        
        // Create some initial data
        setupLocalData()
    }
    
    // MARK: - Setup Local Data
    
    private func setupLocalData() {
        // Create a demo user
        let demoUserID = UUID()
        let demoUser = UserCK(
            id: demoUserID,
            name: "Demo User",
            email: "demo@example.com",
            phone: "123-456-7890",
            role: .student,
            status: .active,
            vacationDays: 10,
            timeOffBalance: 80.0
        )
        localUserRecords[demoUserID] = demoUser
        
        // Create a demo mentor
        let mentorID = UUID()
        let mentor = UserCK(
            id: mentorID,
            name: "Demo Mentor",
            email: "mentor@example.com",
            phone: "987-654-3210",
            role: .mentor,
            status: .active,
            vacationDays: 15,
            timeOffBalance: 120.0
        )
        localUserRecords[mentorID] = mentor
        
        // Create a demo admin
        let adminID = UUID()
        let admin = UserCK(
            id: adminID,
            name: "Demo Admin",
            email: "admin@example.com",
            phone: "555-555-5555",
            role: .admin,
            status: .active,
            vacationDays: 20,
            timeOffBalance: 160.0
        )
        localUserRecords[adminID] = admin
        
        // Create some demo mentees
        let menteeIDs = [UUID(), UUID(), UUID(), UUID()]
        let menteeNames = ["Angelo Brown", "Emily Davis", "Michael Johnson", "Jane Smith"]
        let menteeEmails = ["angelo@example.com", "emily@example.com", "michael@example.com", "jane@example.com"]
        let menteePhones = ["123-456-7890", "234-567-8901", "345-678-9012", "456-789-0123"]
        let menteeProgress = [90, 85, 75, 95]
        
        for i in 0..<menteeIDs.count {
            let mentee = MenteeCK(
                id: menteeIDs[i],
                name: menteeNames[i],
                email: menteeEmails[i],
                phone: menteePhones[i],
                progress: menteeProgress[i],
                monitorID: i < 2 ? mentorID : nil // First two mentees assigned to mentor
            )
            localMenteeRecords[menteeIDs[i]] = mentee
            
            // Create attendance records for each mentee
            createAttendanceRecordsForMentee(menteeIDs[i])
        }
    }
    
    private func createAttendanceRecordsForMentee(_ menteeID: UUID) {
        let calendar = Calendar.current
        let today = Date()
        
        // Create records for the past 5 days
        for day in 1...5 {
            if let date = calendar.date(byAdding: .day, value: -day, to: today) {
                // Skip weekends
                let weekday = calendar.component(.weekday, from: date)
                if weekday != 1 && weekday != 7 {
                    // Randomly decide status
                    let statuses: [AttendanceStatusCK] = [.present, .present, .present, .tardy, .absent]
                    let randomStatus = statuses[Int.random(in: 0..<statuses.count)]
                    
                    // Create clock-in and clock-out times
                    let clockInHour = randomStatus == .tardy ? 9 + Int.random(in: 0...1) : 9
                    let clockInMinute = randomStatus == .tardy ? Int.random(in: 15...45) : Int.random(in: 0...10)
                    
                    let clockInTime = calendar.date(bySettingHour: clockInHour, minute: clockInMinute, second: 0, of: date) ?? date
                    let clockOutTime = calendar.date(bySettingHour: 17, minute: Int.random(in: 0...30), second: 0, of: date) ?? date
                    
                    let attendanceRecord = AttendanceRecordCK(
                        id: UUID(),
                        menteeID: menteeID,
                        date: date,
                        clockInTime: clockInTime,
                        clockOutTime: clockOutTime,
                        status: randomStatus
                    )
                    
                    localAttendanceRecords[attendanceRecord.id] = attendanceRecord
                }
            }
        }
    }
    
    // MARK: - iCloud Account Status (Bypassed)
    func checkiCloudAccountStatus() async {
        DispatchQueue.main.async {
            self.isUserSignedIn = true // Always set to true
        }
    }
    
    // MARK: - Request Permissions (Bypassed)
    func requestApplicationPermission() async {
        DispatchQueue.main.async {
            self.permissionStatus = true // Always set to true
        }
    }
    
    // MARK: - Fetch User Identity (returns mock data)
    func fetchUserIdentity() async {
        DispatchQueue.main.async {
            self.userName = "Demo User" // Always use demo user
        }
    }
    
    // MARK: - CRUD Operations
    
    // Save attendance record to local storage
    func saveAttendance(_ attendance: AttendanceRecordCK) async throws -> AttendanceRecordCK {
        var updatedAttendance = attendance
        
        // If this is a new record, generate a CKRecord-like object
        if updatedAttendance.record == nil {
            let record = CKRecord(recordType: "Attendance")
            record["id"] = attendance.id.uuidString
            record["menteeID"] = attendance.menteeID.uuidString
            record["date"] = attendance.date
            record["clockInTime"] = attendance.clockInTime
            record["clockOutTime"] = attendance.clockOutTime
            record["status"] = attendance.status.recordValue
            
            updatedAttendance.record = record
        }
        
        // Store in local dictionary
        localAttendanceRecords[attendance.id] = updatedAttendance
        
        return updatedAttendance
    }
    
    // Fetch attendance records for a mentee from local storage
    func fetchAttendanceRecords(for menteeID: UUID) async throws -> [AttendanceRecordCK] {
        let records = localAttendanceRecords.values.filter { $0.menteeID == menteeID }
        return records.sorted(by: { $0.date.compare($1.date) == .orderedDescending })
    }
    
    // Fetch attendance records by date range from local storage
    func fetchAttendanceRecords(from startDate: Date, to endDate: Date) async throws -> [AttendanceRecordCK] {
        let records = localAttendanceRecords.values.filter { record in
            let recordDate = record.date
            return recordDate >= startDate && recordDate <= endDate
        }
        return records.sorted(by: { $0.date.compare($1.date) == .orderedAscending })
    }
    
    // Update attendance record in local storage
    func updateAttendance(_ attendance: AttendanceRecordCK) async throws -> AttendanceRecordCK {
        guard let _ = localAttendanceRecords[attendance.id] else {
            throw CloudKitError.recordNotFound
        }
        
        // Update in local storage
        localAttendanceRecords[attendance.id] = attendance
        
        return attendance
    }
    
    // Delete attendance record from local storage
    func deleteAttendance(_ attendance: AttendanceRecordCK) async throws {
        guard localAttendanceRecords[attendance.id] != nil else {
            throw CloudKitError.recordNotFound
        }
        
        // Remove from local storage
        localAttendanceRecords.removeValue(forKey: attendance.id)
    }
    
    // MARK: - Mentee Operations
    
    // Save mentee to local storage
    func saveMentee(_ mentee: MenteeCK) async throws -> MenteeCK {
        var updatedMentee = mentee
        
        // If this is a new record, generate a CKRecord-like object
        if updatedMentee.record == nil {
            let record = CKRecord(recordType: "Mentee")
            record["id"] = mentee.id.uuidString
            record["name"] = mentee.name
            record["email"] = mentee.email
            record["phone"] = mentee.phone
            record["progress"] = mentee.progress
            
            if let monitorID = mentee.monitorID {
                record["monitorID"] = monitorID.uuidString
            }
            
            updatedMentee.record = record
        }
        
        // Store in local dictionary
        localMenteeRecords[mentee.id] = updatedMentee
        
        return updatedMentee
    }
    
    // Fetch all mentees from local storage
    func fetchAllMentees() async throws -> [MenteeCK] {
        let mentees = Array(localMenteeRecords.values)
        return mentees.sorted(by: { $0.name < $1.name })
    }
    
    // Fetch mentees for monitor from local storage
    func fetchMentees(for monitorID: UUID) async throws -> [MenteeCK] {
        let mentees = localMenteeRecords.values.filter { $0.monitorID == monitorID }
        return mentees.sorted(by: { $0.name < $1.name })
    }
    
    // Update mentee in local storage
    func updateMentee(_ mentee: MenteeCK) async throws -> MenteeCK {
        guard localMenteeRecords[mentee.id] != nil else {
            throw CloudKitError.recordNotFound
        }
        
        // Update in local storage
        localMenteeRecords[mentee.id] = mentee
        
        return mentee
    }
    
    // Delete mentee from local storage
    func deleteMentee(_ mentee: MenteeCK) async throws {
        guard localMenteeRecords[mentee.id] != nil else {
            throw CloudKitError.recordNotFound
        }
        
        // Remove from local storage
        localMenteeRecords.removeValue(forKey: mentee.id)
    }
    
    // MARK: - User Operations
    
    // Save user to local storage
    func saveUser(_ user: UserCK) async throws -> UserCK {
        var updatedUser = user
        
        // If this is a new record, generate a CKRecord-like object
        if updatedUser.record == nil {
            let record = CKRecord(recordType: "User")
            record["id"] = user.id.uuidString
            record["name"] = user.name
            record["email"] = user.email
            record["phone"] = user.phone
            record["role"] = user.role.recordValue
            record["status"] = user.status.recordValue
            record["vacationDays"] = user.vacationDays
            record["timeOffBalance"] = user.timeOffBalance
            
            updatedUser.record = record
        }
        
        // Store in local dictionary
        localUserRecords[user.id] = updatedUser
        
        return updatedUser
    }
    
    // Fetch user by ID from local storage
    func fetchUser(with id: UUID) async throws -> UserCK? {
        return localUserRecords[id]
    }
    
    // Fetch all users from local storage
    func fetchAllUsers() async throws -> [UserCK] {
        let users = Array(localUserRecords.values)
        return users.sorted(by: { $0.name < $1.name })
    }
    
    // Update user in local storage
    func updateUser(_ user: UserCK) async throws -> UserCK {
        guard localUserRecords[user.id] != nil else {
            throw CloudKitError.recordNotFound
        }
        
        // Update in local storage
        localUserRecords[user.id] = user
        
        return user
    }
    
    // Delete user from local storage
    func deleteUser(_ user: UserCK) async throws {
        guard localUserRecords[user.id] != nil else {
            throw CloudKitError.recordNotFound
        }
        
        // Remove from local storage
        localUserRecords.removeValue(forKey: user.id)
    }
}
