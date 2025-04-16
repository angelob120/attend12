//
//  FileMakerService.swift
//  New app working
//
//  Created by AB on 4/16/25.
//  Replacement for CloudKitService.swift

import Foundation
import Combine

// MARK: - FileMaker Error
enum FileMakerError: Error {
    case recordNotFound
    case authenticationFailed
    case networkError
    case permissionError
    case invalidResponse
    case unexpectedError(Error)
}

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
    
    // Published properties (similar to CloudKit)
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
    
    // MARK: - Setup Local Data (Similar to CloudKit implementation)
    
    private func setupLocalData() {
        // Same as the existing CloudKit implementation
        // This serves as a fallback when offline
        
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
        
        // Add more sample data as needed
        // (similar to the CloudKit implementation)
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
        let recordData: [String: Any] = [
            "id": user.id.uuidString,
            "name": user.name,
            "email": user.email,
            "phone": user.phone,
            "role": user.role.rawValue,
            "status": user.status.rawValue,
            "vacationDays": user.vacationDays,
            "timeOffBalance": user.timeOffBalance
        ]
        
        // Additional fields
        let additionalData: [String: Any] = [
            "fieldData": recordData
        ]
        
        let url = URL(string: "\(serverAddress)/fmi/data/v1/databases/\(databaseName)/layouts/Users/records")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            // Convert to JSON data
            let jsonData = try JSONSerialization.data(withJSONObject: additionalData)
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw FileMakerError.networkError
            }
            
            if httpResponse.statusCode == 200 {
                // For simplicity, we'll just store the user in local storage and return it
                // In a real implementation, you would parse the response from FileMaker
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
                    return parseUserData(userData)
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
                           let user = parseUserData(userData) {
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
        
        // First, find the record ID
        let queryString = "?query=\(URLQueryItem(name: "id", value: user.id.uuidString).percentEncodedValue)"
        let findUrl = URL(string: "\(serverAddress)/fmi/data/v1/databases/\(databaseName)/layouts/Users/records\(queryString)")!
        
        var findRequest = URLRequest(url: findUrl)
        findRequest.httpMethod = "GET"
        findRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (findData, findResponse) = try await URLSession.shared.data(for: findRequest)
            
            guard let findHttpResponse = findResponse as? HTTPURLResponse else {
                throw FileMakerError.networkError
            }
            
            if findHttpResponse.statusCode == 200 {
                // Parse the response to get the record ID
                if let responseDict = try JSONSerialization.jsonObject(with: findData) as? [String: Any],
                   let response = responseDict["response"] as? [String: Any],
                   let dataArray = response["data"] as? [[String: Any]],
                   let firstRecord = dataArray.first,
                   let recordId = firstRecord["recordId"] as? String {
                    
                    // Now we can update the record
                    let updateUrl = URL(string: "\(serverAddress)/fmi/data/v1/databases/\(databaseName)/layouts/Users/records/\(recordId)")!
                    
                    var updateRequest = URLRequest(url: updateUrl)
                    updateRequest.httpMethod = "PATCH"
                    updateRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    updateRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    // Convert UserFM to FileMaker-compatible format
                    let recordData: [String: Any] = [
                        "name": user.name,
                        "email": user.email,
                        "phone": user.phone,
                        "role": user.role.rawValue,
                        "status": user.status.rawValue,
                        "vacationDays": user.vacationDays,
                        "timeOffBalance": user.timeOffBalance
                    ]
                    
                    let updateData: [String: Any] = [
                        "fieldData": recordData
                    ]
                    
                    let jsonData = try JSONSerialization.data(withJSONObject: updateData)
                    updateRequest.httpBody = jsonData
                    
                    let (_, updateResponse) = try await URLSession.shared.data(for: updateRequest)
                    
                    guard let updateHttpResponse = updateResponse as? HTTPURLResponse else {
                        throw FileMakerError.networkError
                    }
                    
                    if updateHttpResponse.statusCode == 200 {
                        // Update local cache
                        localUserRecords[user.id] = user
                        return user
                    } else {
                        throw FileMakerError.unexpectedError(NSError(domain: "FileMakerError", code: updateHttpResponse.statusCode))
                    }
                } else {
                    throw FileMakerError.recordNotFound
                }
            } else {
                throw FileMakerError.unexpectedError(NSError(domain: "FileMakerError", code: findHttpResponse.statusCode))
            }
        } catch {
            if let fmError = error as? FileMakerError {
                throw fmError
            }
            throw FileMakerError.unexpectedError(error)
        }
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
        
        // First, find the record ID
        let queryString = "?query=\(URLQueryItem(name: "id", value: user.id.uuidString).percentEncodedValue)"
        let findUrl = URL(string: "\(serverAddress)/fmi/data/v1/databases/\(databaseName)/layouts/Users/records\(queryString)")!
        
        var findRequest = URLRequest(url: findUrl)
        findRequest.httpMethod = "GET"
        findRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (findData, findResponse) = try await URLSession.shared.data(for: findRequest)
            
            guard let findHttpResponse = findResponse as? HTTPURLResponse else {
                throw FileMakerError.networkError
            }
            
            if findHttpResponse.statusCode == 200 {
                // Parse the response to get the record ID
                if let responseDict = try JSONSerialization.jsonObject(with: findData) as? [String: Any],
                   let response = responseDict["response"] as? [String: Any],
                   let dataArray = response["data"] as? [[String: Any]],
                   let firstRecord = dataArray.first,
                   let recordId = firstRecord["recordId"] as? String {
                    
                    // Now we can delete the record
                    let deleteUrl = URL(string: "\(serverAddress)/fmi/data/v1/databases/\(databaseName)/layouts/Users/records/\(recordId)")!
                    
                    var deleteRequest = URLRequest(url: deleteUrl)
                    deleteRequest.httpMethod = "DELETE"
                    deleteRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    
                    let (_, deleteResponse) = try await URLSession.shared.data(for: deleteRequest)
                    
                    guard let deleteHttpResponse = deleteResponse as? HTTPURLResponse else {
                        throw FileMakerError.networkError
                    }
                    
                    if deleteHttpResponse.statusCode == 200 {
                        // Remove from local cache
                        localUserRecords.removeValue(forKey: user.id)
                        return
                    } else {
                        throw FileMakerError.unexpectedError(NSError(domain: "FileMakerError", code: deleteHttpResponse.statusCode))
                    }
                } else {
                    throw FileMakerError.recordNotFound
                }
            } else {
                throw FileMakerError.unexpectedError(NSError(domain: "FileMakerError", code: findHttpResponse.statusCode))
            }
        } catch {
            if let fmError = error as? FileMakerError {
                throw fmError
            }
            throw FileMakerError.unexpectedError(error)
        }
    }
    
    // MARK: - Helper methods
    
    /// Parse user data from FileMaker response
    private func parseUserData(_ userData: [String: Any]) -> UserFM? {
        guard let idString = userData["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = userData["name"] as? String,
              let email = userData["email"] as? String,
              let phone = userData["phone"] as? String,
              let roleString = userData["role"] as? String,
              let role = UserRoleFM(rawValue: roleString),
              let statusString = userData["status"] as? String,
              let status = UserStatusFM(rawValue: statusString),
              let vacationDays = userData["vacationDays"] as? Int,
              let timeOffBalance = userData["timeOffBalance"] as? Double else {
            return nil
        }
        
        return UserFM(
            id: id,
            name: name,
            email: email,
            phone: phone,
            role: role,
            status: status,
            vacationDays: vacationDays,
            timeOffBalance: timeOffBalance
        )
    }
    
    // MARK: - Similar methods for Attendance and Mentee
    
    // Implement similar CRUD operations for attendance and mentee records
    // These would follow the same pattern as the user operations above
    
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
