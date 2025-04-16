//
//  FileMakerService.swift
//  New app working
//
//  Created by AB on 4/16/25.
//  Core service for FileMaker integration

import Foundation
import Combine
import CoreLocation

// MARK: - FileMaker Service
class FileMakerService: ObservableObject {
    static let shared = FileMakerService()
    
    // FileMaker Server Configuration
    private let serverAddress: String
    private let databaseName: String
    private let username: String
    private let password: String
    
    // Session token for authentication
    private var sessionToken: String?
    
    // Published properties
    @Published var isUserSignedIn = false
    @Published var userName: String = "Demo User"
    @Published var permissionStatus: Bool = false
    
    // Local storage for records when FileMaker is unavailable
    private var localAttendanceRecords: [UUID: AttendanceRecord] = [:]
    private var localMenteeRecords: [UUID: Mentee] = [:]
    private var localUserRecords: [UUID: UserFM] = [:]
    
    // Private singleton initializer
    private init() {
        // Load configuration from environment or plist file
        // For now, we'll use hardcoded values
        self.serverAddress = "https://your-filemaker-server.com"
        self.databaseName = "StudentAttendanceApp"
        self.username = "apiuser"
        self.password = "apipassword"
        
        // Create some initial data
        setupLocalData()
    }
    
    // MARK: - Setup Local Data
    
    private func setupLocalData() {
        // Create a demo user
        let demoUserID = UUID()
        let demoUser = UserFM(
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
        let mentor = UserFM(
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
    }
    
    // MARK: - Authentication
    
    /// Authenticate with the FileMaker server and get a session token
    func authenticate() async throws {
        let url = URL(string: "\(serverAddress)/fmi/data/v1/databases/\(databaseName)/sessions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Set basic auth header for initial authentication
        let loginString = "\(username):\(password)"
        if let loginData = loginString.data(using: .utf8) {
            let base64LoginString = loginData.base64EncodedString()
            request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw FileMakerError.networkError
            }
            
            if httpResponse.statusCode == 200 {
                // Parse the response to get the token
                if let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let response = responseDict["response"] as? [String: Any],
                   let token = response["token"] as? String {
                    
                    sessionToken = token
                    
                    DispatchQueue.main.async {
                        self.isUserSignedIn = true
                    }
                    return
                }
            }
            
            throw FileMakerError.authenticationFailed
        } catch {
            if let fmError = error as? FileMakerError {
                throw fmError
            }
            throw FileMakerError.unexpectedError(error)
        }
    }
    
    /// Check if the current token is valid
    func validateSession() async -> Bool {
        guard let token = sessionToken else {
            return false
        }
        
        // Make a simple request to verify the token is still valid
        let url = URL(string: "\(serverAddress)/fmi/data/v1/databases/\(databaseName)/layouts")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
    
    // MARK: - CRUD Operations for Users
    
    /// Create a new user in FileMaker
    func saveUser(_ user: UserFM) async throws -> UserFM {
        // Ensure we have a valid session
        if !(await validateSession()) {
            try await authenticate()
        }
        
        guard let token = sessionToken else {
            throw FileMakerError.authenticationFailed
        }
        
        // Convert UserFM to FileMaker-compatible format
        let recordData = user.toFileMakerDictionary()
        
        // Additional data for the request
        let requestData: [String: Any] = [
            "fieldData": recordData
        ]
        
        let url = URL(string: "\(serverAddress)/fmi/data/v1/databases/\(databaseName)/layouts/Users/records")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            // Convert to JSON data
            let jsonData = try JSONSerialization.data(withJSONObject: requestData)
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw FileMakerError.networkError
            }
            
            if httpResponse.statusCode == 200 {
                // For simplicity in demo implementation, we'll just store locally
                // In a real implementation, you would parse the response
                localUserRecords[user.id] = user
                return user
            } else {
                throw FileMakerError.unexpectedError(NSError(domain: "FileMakerError", code: httpResponse.statusCode))
            }
        } catch {
            if let fmError = error as? FileMakerError {
                throw fmError
            }
            throw FileMakerError.unexpectedError(error)
        }
    }
    
    /// Fetch a user by ID
    func fetchUser(with id: UUID) async throws -> UserFM? {
        // Check local cache first (for demo implementation)
        if let user = localUserRecords[id] {
            return user
        }
        
        // Ensure we have a valid session
        if !(await validateSession()) {
            try await authenticate()
        }
        
        guard let token = sessionToken else {
            throw FileMakerError.authenticationFailed
        }
        
        // Query for the user with the specified ID
        let queryString = "?query=\(URLQueryItem(name: "id", value: id.uuidString).percentEncodedValue)"
        let url = URL(string: "\(serverAddress)/fmi/data/v1/databases/\(databaseName)/layouts/Users/records\(queryString)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw FileMakerError.networkError
            }
            
            if httpResponse.statusCode == 200 {
                // Parse the response
                if let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let response = responseDict["response"] as? [String: Any],
                   let dataArray = response["data"] as? [[String: Any]],
                   let userData = dataArray.first?["fieldData"] as? [String: Any] {
                    
                    // Extract user data and create UserFM object
                    return UserFM.fromFileMakerDictionary(userData)
                }
                
                // No matching record found
                return nil
            } else {
                throw FileMakerError.unexpectedError(NSError(domain: "FileMakerError", code: httpResponse.statusCode))
            }
        } catch {
            if let fmError = error as? FileMakerError {
                throw fmError
            }
            throw FileMakerError.unexpectedError(error)
        }
    }
    
    /// Fetch all users
    func fetchAllUsers() async throws -> [UserFM] {
        // In demo mode, return local users
        if localUserRecords.count > 0 {
            return Array(localUserRecords.values)
        }
        
        // Ensure we have a valid session
        if !(await validateSession()) {
            try await authenticate()
        }
        
        guard let token = sessionToken else {
            throw FileMakerError.authenticationFailed
        }
        
        let url = URL(string: "\(serverAddress)/fmi/data/v1/databases/\(databaseName)/layouts/Users/records")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw FileMakerError.networkError
            }
            
            if httpResponse.statusCode == 200 {
                // Parse the response
                if let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let response = responseDict["response"] as? [String: Any],
                   let dataArray = response["data"] as? [[String: Any]] {
                    
                    var users: [UserFM] = []
                    
                    for item in dataArray {
                        if let userData = item["fieldData"] as? [String: Any],
                           let user = UserFM.fromFileMakerDictionary(userData) {
                            users.append(user)
                        }
                    }
                    
                    return users
                }
                
                return []
            } else {
                throw FileMakerError.unexpectedError(NSError(domain: "FileMakerError", code: httpResponse.statusCode))
            }
        } catch {
            if let fmError = error as? FileMakerError {
                throw fmError
            }
            throw FileMakerError.unexpectedError(error)
        }
    }
    
    /// Update an existing user
    func updateUser(_ user: UserFM) async throws -> UserFM {
        // Ensure we have a valid session
        if !(await validateSession()) {
            try await authenticate()
        }
        
        guard let token = sessionToken else {
            throw FileMakerError.authenticationFailed
        }
        
        // For demo mode, just update local cache
        localUserRecords[user.id] = user
        
        // In a real implementation, you would find the record in FileMaker
        // and update it using a PATCH request
        
        return user
    }
    
    /// Delete a user
    func deleteUser(_ user: UserFM) async throws {
        // Ensure we have a valid session
        if !(await validateSession()) {
            try await authenticate()
        }
        
        guard let token = sessionToken else {
            throw FileMakerError.authenticationFailed
        }
        
        // For demo mode, just remove from local cache
        localUserRecords.removeValue(forKey: user.id)
        
        // In a real implementation, you would find the record in FileMaker
        // and delete it using a DELETE request
    }
    
    // MARK: - Attendance Record Management
    
    /// Fetch attendance records for a specific mentee
    func fetchAttendanceRecords(for menteeID: UUID) async throws -> [AttendanceRecordFM] {
        // This would normally query the FileMaker database
        // For simplicity during migration, we'll use mock data
        
        // Return mock records for now
        return generateMockAttendanceRecords(for: menteeID)
    }
    
    /// Fetch attendance by date range
    func fetchAttendanceRecords(from startDate: Date, to endDate: Date) async throws -> [AttendanceRecordFM] {
        // This would normally query the FileMaker database
        // For simplicity during migration, we'll use mock data
        
        let records = generateMockAttendanceRecords(for: UUID())
        
        // Filter by date range
        return records.filter { record in
            record.date >= startDate && record.date <= endDate
        }
    }
    
    /// Save attendance record
    func saveAttendance(_ record: AttendanceRecordFM) async throws -> AttendanceRecordFM {
        // This would normally save to the FileMaker database
        // For simplicity during migration, we'll return the record
        
        // In a real implementation, this would make an API call to FileMaker
        // and return the saved record with any updates
        
        return record
    }
    
    /// Update attendance record
    func updateAttendance(_ record: AttendanceRecordFM) async throws -> AttendanceRecordFM {
        // This would normally update the FileMaker database
        // For simplicity during migration, we'll return the record
        
        // In a real implementation, this would make an API call to FileMaker
        // and return the updated record
        
        return record
    }
    
    /// Delete attendance record
    func deleteAttendance(_ record: AttendanceRecordFM) async throws {
        // This would normally delete from the FileMaker database
        // For simplicity during migration, we'll do nothing
        
        // In a real implementation, this would make an API call to FileMaker
    }
    
    // MARK: - Mentee Management
    
    /// Fetch all mentees
    func fetchAllMentees() async throws -> [MenteeFM] {
        // Return mock data
        return generateMockMentees()
    }
    
    /// Fetch mentees for a specific mentor
    func fetchMentees(for mentorID: UUID) async throws -> [MenteeFM] {
        // Return subset of mock data
        let allMentees = generateMockMentees()
        return allMentees.filter { $0.monitorID == mentorID }
    }
    
    /// Save mentee
    func saveMentee(_ mentee: MenteeFM) async throws -> MenteeFM {
        return mentee
    }
    
    /// Update mentee
    func updateMentee(_ mentee: MenteeFM) async throws -> MenteeFM {
        return mentee
    }
    
    /// Delete mentee
    func deleteMentee(_ mentee: MenteeFM) async throws {
        // Would normally delete from FileMaker
    }
    
    // MARK: - Mock Data Generation
    
    /// Generate mock attendance records for testing
    private func generateMockAttendanceRecords(for menteeID: UUID) -> [AttendanceRecordFM] {
        var records: [AttendanceRecordFM] = []
        
        // Create some records for the past 30 days
        let calendar = Calendar.current
        let today = Date()
        
        for day in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: -day, to: today) {
                // Skip weekends
                let weekday = calendar.component(.weekday, from: date)
                if weekday == 1 || weekday == 7 { // Sunday = 1, Saturday = 7
                    continue
                }
                
                // Randomize status with bias toward present
                let statusRandom = Double.random(in: 0...1)
                let status: AttendanceStatusFM
                if statusRandom < 0.1 {
                    status = .absent
                } else if statusRandom < 0.2 {
                    status = .tardy
                } else {
                    status = .present
                }
                
                // Create clock in/out times
                let dayStart = calendar.startOfDay(for: date)
                let clockInTime = calendar.date(byAdding: .hour, value: 9, to: dayStart)!
                let clockOutTime = calendar.date(byAdding: .hour, value: 17, to: dayStart)!
                
                // Create record
                let record = AttendanceRecordFM(
                    menteeID: menteeID,
                    date: date,
                    clockInTime: clockInTime,
                    clockOutTime: clockOutTime,
                    status: status
                )
                
                records.append(record)
            }
        }
        
        return records
    }
    
    /// Generate mock mentees for testing
    private func generateMockMentees() -> [MenteeFM] {
        let mentorID = UUID()
        
        return [
            MenteeFM(
                name: "John Smith",
                email: "john@example.com",
                phone: "555-123-4567",
                progress: 85,
                monitorID: mentorID,
                imageName: "profile1"
            ),
            MenteeFM(
                name: "Jane Doe",
                email: "jane@example.com",
                phone: "555-987-6543",
                progress: 92,
                monitorID: mentorID,
                imageName: "profile2"
            ),
            MenteeFM(
                name: "Bob Johnson",
                email: "bob@example.com",
                phone: "555-456-7890",
                progress: 78,
                monitorID: nil,
                imageName: "profile3"
            ),
            MenteeFM(
                name: "Alice Williams",
                email: "alice@example.com",
                phone: "555-654-3210",
                progress: 95,
                monitorID: nil,
                imageName: "profile4"
            )
        ]
    }
    
    // MARK: - Identity and User Management
    
    /// Fetch user identity
    func fetchUserIdentity() async {
        // In a real implementation, this would fetch the current user's identity from FileMaker
        DispatchQueue.main.async {
            self.userName = "Demo User" // Default value
        }
    }
}

// MARK: - URL Query Helper
extension URLQueryItem {
    var percentEncodedValue: String {
        guard let value = value else { return "" }
        return value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
    }
}
