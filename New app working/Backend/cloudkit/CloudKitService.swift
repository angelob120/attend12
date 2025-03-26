//
//  CloudKitService.swift
//  New app working
//
//  Created by AB on 3/26/25.
//

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
    
    @Published var isUserSignedIn = false
    @Published var userName: String = ""
    @Published var permissionStatus: Bool = false
    
    // Private singleton initializer
    private init() {
        container = CKContainer.default()
        publicDB = container.publicCloudDatabase
        privateDB = container.privateCloudDatabase
        sharedDB = container.sharedCloudDatabase
        
        // Check iCloud status when initialized
        Task {
            await checkiCloudAccountStatus()
            await requestApplicationPermission()
            await fetchUserIdentity()
        }
    }
    
    // MARK: - iCloud Account Status
    func checkiCloudAccountStatus() async {
        do {
            let status = try await container.accountStatus()
            
            DispatchQueue.main.async {
                switch status {
                case .available:
                    self.isUserSignedIn = true
                case .noAccount, .restricted, .couldNotDetermine:
                    self.isUserSignedIn = false
                default:
                    self.isUserSignedIn = false
                }
            }
        } catch {
            print("Error checking iCloud Account Status: \(error)")
            DispatchQueue.main.async {
                self.isUserSignedIn = false
            }
        }
    }
    
    // MARK: - Request Permissions
    func requestApplicationPermission() async {
        do {
            let status = try await container.requestApplicationPermission(.userDiscoverability)
            DispatchQueue.main.async {
                self.permissionStatus = status == .granted
            }
        } catch {
            print("Error requesting permission: \(error)")
            DispatchQueue.main.async {
                self.permissionStatus = false
            }
        }
    }
    
    // MARK: - Fetch User Identity
    func fetchUserIdentity() async {
        do {
            let userID = try await container.userRecordID()
            let identity = try await container.userIdentity(forUserRecordID: userID)
            
            if let name = identity?.nameComponents?.givenName {
                DispatchQueue.main.async {
                    self.userName = name
                }
            }
        } catch {
            print("Error fetching user identity: \(error)")
        }
    }
    
    // MARK: - CRUD Operations
    
    // Save attendance record
    func saveAttendance(_ attendance: AttendanceRecordCK) async throws -> AttendanceRecordCK {
        let record = CKRecord(attendance: attendance)
        
        do {
            let savedRecord = try await privateDB.save(record)
            var updatedAttendance = attendance
            updatedAttendance.record = savedRecord
            return updatedAttendance
        } catch {
            throw CloudKitError.unexpectedError(error)
        }
    }
    
    // Fetch attendance records for a mentee
    func fetchAttendanceRecords(for menteeID: UUID) async throws -> [AttendanceRecordCK] {
        let predicate = NSPredicate(format: "\(AttendanceKeys.menteeID) == %@", menteeID.uuidString)
        let query = CKQuery(recordType: RecordType.attendance, predicate: predicate)
        
        do {
            let (results, _) = try await privateDB.records(matching: query)
            var attendanceRecords: [AttendanceRecordCK] = []
            
            for (_, result) in results {
                switch result {
                case .success(let record):
                    if let attendance = record.toAttendanceRecord() {
                        attendanceRecords.append(attendance)
                    }
                case .failure(let error):
                    print("Error fetching record: \(error)")
                }
            }
            
            return attendanceRecords.sorted(by: { $0.date.compare($1.date) == .orderedDescending })
        } catch {
            throw CloudKitError.unexpectedError(error)
        }
    }
    
    // Fetch attendance records by date range
    func fetchAttendanceRecords(from startDate: Date, to endDate: Date) async throws -> [AttendanceRecordCK] {
        let predicate = NSPredicate(format: "\(AttendanceKeys.date) >= %@ AND \(AttendanceKeys.date) <= %@", startDate as NSDate, endDate as NSDate)
        let query = CKQuery(recordType: RecordType.attendance, predicate: predicate)
        
        do {
            let (results, _) = try await privateDB.records(matching: query)
            var attendanceRecords: [AttendanceRecordCK] = []
            
            for (_, result) in results {
                switch result {
                case .success(let record):
                    if let attendance = record.toAttendanceRecord() {
                        attendanceRecords.append(attendance)
                    }
                case .failure(let error):
                    print("Error fetching record: \(error)")
                }
            }
            
            return attendanceRecords.sorted(by: { $0.date.compare($1.date) == .orderedAscending })
        } catch {
            throw CloudKitError.unexpectedError(error)
        }
    }
    
    // Update attendance record
    func updateAttendance(_ attendance: AttendanceRecordCK) async throws -> AttendanceRecordCK {
        guard let record = attendance.record else {
            throw CloudKitError.recordNotFound
        }
        
        // Update record with new values
        record[AttendanceKeys.date] = attendance.date
        record[AttendanceKeys.clockInTime] = attendance.clockInTime
        record[AttendanceKeys.clockOutTime] = attendance.clockOutTime
        record[AttendanceKeys.status] = attendance.status.recordValue
        
        if let location = attendance.location {
            record[AttendanceKeys.location] = location
        }
        
        do {
            let updatedRecord = try await privateDB.save(record)
            var updatedAttendance = attendance
            updatedAttendance.record = updatedRecord
            return updatedAttendance
        } catch {
            throw CloudKitError.unexpectedError(error)
        }
    }
    
    // Delete attendance record
    func deleteAttendance(_ attendance: AttendanceRecordCK) async throws {
        guard let recordID = attendance.record?.recordID else {
            throw CloudKitError.recordNotFound
        }
        
        do {
            try await privateDB.deleteRecord(withID: recordID)
        } catch {
            throw CloudKitError.unexpectedError(error)
        }
    }
    
    // MARK: - Mentee Operations
    
    // Save mentee
    func saveMentee(_ mentee: MenteeCK) async throws -> MenteeCK {
        let record = CKRecord(mentee: mentee)
        
        do {
            let savedRecord = try await privateDB.save(record)
            var updatedMentee = mentee
            updatedMentee.record = savedRecord
            return updatedMentee
        } catch {
            throw CloudKitError.unexpectedError(error)
        }
    }
    
    // Fetch all mentees
    func fetchAllMentees() async throws -> [MenteeCK] {
        let query = CKQuery(recordType: RecordType.mentee, predicate: NSPredicate(value: true))
        
        do {
            let (results, _) = try await privateDB.records(matching: query)
            var mentees: [MenteeCK] = []
            
            for (_, result) in results {
                switch result {
                case .success(let record):
                    if let mentee = record.toMentee() {
                        mentees.append(mentee)
                    }
                case .failure(let error):
                    print("Error fetching record: \(error)")
                }
            }
            
            return mentees.sorted(by: { $0.name < $1.name })
        } catch {
            throw CloudKitError.unexpectedError(error)
        }
    }
    
    // Fetch mentees for monitor
    func fetchMentees(for monitorID: UUID) async throws -> [MenteeCK] {
        let predicate = NSPredicate(format: "\(MenteeKeys.monitorID) == %@", monitorID.uuidString)
        let query = CKQuery(recordType: RecordType.mentee, predicate: predicate)
        
        do {
            let (results, _) = try await privateDB.records(matching: query)
            var mentees: [MenteeCK] = []
            
            for (_, result) in results {
                switch result {
                case .success(let record):
                    if let mentee = record.toMentee() {
                        mentees.append(mentee)
                    }
                case .failure(let error):
                    print("Error fetching record: \(error)")
                }
            }
            
            return mentees.sorted(by: { $0.name < $1.name })
        } catch {
            throw CloudKitError.unexpectedError(error)
        }
    }
    
    // Update mentee
    func updateMentee(_ mentee: MenteeCK) async throws -> MenteeCK {
        guard let record = mentee.record else {
            throw CloudKitError.recordNotFound
        }
        
        record[MenteeKeys.name] = mentee.name
        record[MenteeKeys.email] = mentee.email
        record[MenteeKeys.phone] = mentee.phone
        record[MenteeKeys.progress] = mentee.progress
        
        if let monitorID = mentee.monitorID {
            record[MenteeKeys.monitorID] = monitorID.uuidString
        } else {
            record[MenteeKeys.monitorID] = nil
        }
        
        do {
            let updatedRecord = try await privateDB.save(record)
            var updatedMentee = mentee
            updatedMentee.record = updatedRecord
            return updatedMentee
        } catch {
            throw CloudKitError.unexpectedError(error)
        }
    }
    
    // Delete mentee
    func deleteMentee(_ mentee: MenteeCK) async throws {
        guard let recordID = mentee.record?.recordID else {
            throw CloudKitError.recordNotFound
        }
        
        do {
            try await privateDB.deleteRecord(withID: recordID)
        } catch {
            throw CloudKitError.unexpectedError(error)
        }
    }
    
    // MARK: - User Operations
    
    // Save user
    func saveUser(_ user: UserCK) async throws -> UserCK {
        let record = CKRecord(user: user)
        
        do {
            let savedRecord = try await privateDB.save(record)
            var updatedUser = user
            updatedUser.record = savedRecord
            return updatedUser
        } catch {
            throw CloudKitError.unexpectedError(error)
        }
    }
    
    // Fetch user by ID
    func fetchUser(with id: UUID) async throws -> UserCK? {
        let predicate = NSPredicate(format: "\(UserKeys.id) == %@", id.uuidString)
        let query = CKQuery(recordType: RecordType.user, predicate: predicate)
        
        do {
            let (results, _) = try await privateDB.records(matching: query, resultsLimit: 1)
            
            for (_, result) in results {
                switch result {
                case .success(let record):
                    return record.toUser()
                case .failure(let error):
                    print("Error fetching record: \(error)")
                    return nil
                }
            }
            
            return nil
        } catch {
            throw CloudKitError.unexpectedError(error)
        }
    }
    
    // Fetch all users
    func fetchAllUsers() async throws -> [UserCK] {
        let query = CKQuery(recordType: RecordType.user, predicate: NSPredicate(value: true))
        
        do {
            let (results, _) = try await privateDB.records(matching: query)
            var users: [UserCK] = []
            
            for (_, result) in results {
                switch result {
                case .success(let record):
                    if let user = record.toUser() {
                        users.append(user)
                    }
                case .failure(let error):
                    print("Error fetching record: \(error)")
                }
            }
            
            return users.sorted(by: { $0.name < $1.name })
        } catch {
            throw CloudKitError.unexpectedError(error)
        }
    }
    
    // Update user
    func updateUser(_ user: UserCK) async throws -> UserCK {
        guard let record = user.record else {
            throw CloudKitError.recordNotFound
        }
        
        record[UserKeys.name] = user.name
        record[UserKeys.email] = user.email
        record[UserKeys.phone] = user.phone
        record[UserKeys.role] = user.role.recordValue
        record[UserKeys.status] = user.status.recordValue
        record[UserKeys.vacationDays] = user.vacationDays
        record[UserKeys.timeOffBalance] = user.timeOffBalance
        
        do {
            let updatedRecord = try await privateDB.save(record)
            var updatedUser = user
            updatedUser.record = updatedRecord
            return updatedUser
        } catch {
            throw CloudKitError.unexpectedError(error)
        }
    }
    
    // Delete user
    func deleteUser(_ user: UserCK) async throws {
        guard let recordID = user.record?.recordID else {
            throw CloudKitError.recordNotFound
        }
        
        do {
            try await privateDB.deleteRecord(withID: recordID)
        } catch {
            throw CloudKitError.unexpectedError(error)
        }
    }
}
