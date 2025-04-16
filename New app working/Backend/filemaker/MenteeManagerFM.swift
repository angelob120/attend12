//
//  MenteeManagerFM.swift
//  New app working
//
//  Created by AB on 4/16/25.
//  Replacement for MenteeManagerCK.swift

import Foundation
import SwiftUI
import Combine

// MARK: - Mentee Manager
class MenteeManagerFM: ObservableObject {
    // Singleton instance
    static let shared = MenteeManagerFM()
    
    // Published properties
    @Published var myMentees: [MenteeFM] = []
    @Published var allMentees: [MenteeFM] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // References
    private let fileMakerService = FileMakerService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Private initializer for singleton
    private init() {
        // Initial data fetch if user is signed in
        fileMakerService.$isUserSignedIn
            .filter { $0 }
            .sink { [weak self] _ in
                Task {
                    await self?.fetchAllMentees()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Mentee Management
    
    /// Fetch all mentees from FileMaker
    func fetchAllMentees() async {
        guard !isLoading else { return }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let mentees = try await fileMakerService.fetchAllMentees()
            
            DispatchQueue.main.async {
                self.allMentees = mentees
                // Filter out mentees that are already in myMentees
                self.allMentees.removeAll(where: { mentee in
                    self.myMentees.contains(where: { $0.id == mentee.id })
                })
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.error = "Failed to fetch mentees: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// Fetch mentees for a specific mentor/monitor
    func fetchMyMentees(for monitorID: UUID) async {
        guard !isLoading else { return }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let mentees = try await fileMakerService.fetchMentees(for: monitorID)
            
            DispatchQueue.main.async {
                self.myMentees = mentees
                // Remove these mentees from allMentees to avoid duplication
                self.allMentees.removeAll(where: { mentee in
                    self.myMentees.contains(where: { $0.id == mentee.id })
                })
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.error = "Failed to fetch your mentees: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// Add a new mentee
    func addMentee(_ mentee: MenteeFM) async -> Bool {
        guard !isLoading else { return false }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let savedMentee = try await fileMakerService.saveMentee(mentee)
            
            DispatchQueue.main.async {
                if let monitorID = mentee.monitorID {
                    // If the mentee has a monitor, add to myMentees
                    self.myMentees.append(savedMentee)
                } else {
                    // Otherwise add to allMentees
                    self.allMentees.append(savedMentee)
                }
                self.isLoading = false
            }
            
            return true
        } catch {
            DispatchQueue.main.async {
                self.error = "Failed to add mentee: \(error.localizedDescription)"
                self.isLoading = false
            }
            
            return false
        }
    }
    
    /// Update an existing mentee
    func updateMentee(_ mentee: MenteeFM) async -> Bool {
        guard !isLoading else { return false }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let updatedMentee = try await fileMakerService.updateMentee(mentee)
            
            DispatchQueue.main.async {
                // Update in myMentees if exists
                if let index = self.myMentees.firstIndex(where: { $0.id == updatedMentee.id }) {
                    self.myMentees[index] = updatedMentee
                }
                // Update in allMentees if exists
                else if let index = self.allMentees.firstIndex(where: { $0.id == updatedMentee.id }) {
                    self.allMentees[index] = updatedMentee
                }
                
                self.isLoading = false
            }
            
            return true
        } catch {
            DispatchQueue.main.async {
                self.error = "Failed to update mentee: \(error.localizedDescription)"
                self.isLoading = false
            }
            
            return false
        }
    }
    
    /// Remove a mentee from MyMentees (set monitorID to nil)
    func removeFromMyMentees(_ mentee: MenteeFM) async -> Bool {
        guard !isLoading else { return false }
        
        // Create a modified mentee with no monitor
        var modifiedMentee = mentee
        modifiedMentee.monitorID = nil
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let updatedMentee = try await fileMakerService.updateMentee(modifiedMentee)
            
            DispatchQueue.main.async {
                // Remove from myMentees
                self.myMentees.removeAll { $0.id == updatedMentee.id }
                
                // Add to allMentees
                if !self.allMentees.contains(where: { $0.id == updatedMentee.id }) {
                    self.allMentees.append(updatedMentee)
                }
                
                self.isLoading = false
            }
            
            return true
        } catch {
            DispatchQueue.main.async {
                self.error = "Failed to remove mentee: \(error.localizedDescription)"
                self.isLoading = false
            }
            
            return false
        }
    }
    
    /// Add a mentee to MyMentees (set monitorID)
    func addToMyMentees(_ mentee: MenteeFM, monitorID: UUID) async -> Bool {
        guard !isLoading else { return false }
        
        // Create a modified mentee with the monitor ID
        var modifiedMentee = mentee
        modifiedMentee.monitorID = monitorID
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let updatedMentee = try await fileMakerService.updateMentee(modifiedMentee)
            
            DispatchQueue.main.async {
                // Add to myMentees
                if !self.myMentees.contains(where: { $0.id == updatedMentee.id }) {
                    self.myMentees.append(updatedMentee)
                }
                
                // Remove from allMentees
                self.allMentees.removeAll { $0.id == updatedMentee.id }
                
                self.isLoading = false
            }
            
            return true
        } catch {
            DispatchQueue.main.async {
                self.error = "Failed to add mentee to your list: \(error.localizedDescription)"
                self.isLoading = false
            }
            
            return false
        }
    }
    
    /// Delete a mentee completely
    func deleteMentee(_ mentee: MenteeFM) async -> Bool {
        guard !isLoading else { return false }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            try await fileMakerService.deleteMentee(mentee)
            
            DispatchQueue.main.async {
                // Remove from myMentees if exists
                self.myMentees.removeAll { $0.id == mentee.id }
                
                // Remove from allMentees if exists
                self.allMentees.removeAll { $0.id == mentee.id }
                
                self.isLoading = false
            }
            
            return true
        } catch {
            DispatchQueue.main.async {
                self.error = "Failed to delete mentee: \(error.localizedDescription)"
                self.isLoading = false
            }
            
            return false
        }
    }
    
    /// Update mentee progress
    func updateMenteeProgress(_ mentee: MenteeFM, progress: Int) async -> Bool {
        guard !isLoading else { return false }
        
        // Create a modified mentee with updated progress
        var modifiedMentee = mentee
        modifiedMentee.progress = progress
        
        return await updateMentee(modifiedMentee)
    }
    
    /// Get a mentee by ID
    func getMentee(with id: UUID) -> MenteeFM? {
        // Check in myMentees first
        if let mentee = myMentees.first(where: { $0.id == id }) {
            return mentee
        }
        
        // Then check in allMentees
        return allMentees.first(where: { $0.id == id })
    }
    
    /// Reset state (for logout)
    func reset() {
        myMentees = []
        allMentees = []
        error = nil
    }
    
    // MARK: - Compatibility Methods
    
    /// Convert existing Mentee to FileMaker model and add to database
    func addMentee(_ mentee: Mentee, monitorID: UUID? = nil) async -> Bool {
        let menteeFM = MenteeFM(
            name: mentee.name,
            email: mentee.email,
            phone: mentee.phone,
            progress: mentee.progress,
            monitorID: monitorID,
            imageName: mentee.imageName
        )
        
        return await addMentee(menteeFM)
    }
    
    /// Remove mentee from MyMentees (compatibility with MenteeManager)
    func removeFromMyMentees(_ mentee: Mentee) async -> Bool {
        guard let menteeFM = myMentees.first(where: { $0.name == mentee.name }) else {
            // If we can't find the mentee, we consider the operation successful
            return true
        }
        
        return await removeFromMyMentees(menteeFM)
    }
    
    /// Add mentee to MyMentees (compatibility with MenteeManager)
    func addToMyMentees(_ mentee: Mentee, monitorID: UUID) async -> Bool {
        // First, check if the mentee already exists in allMentees
        if let existingMentee = allMentees.first(where: { $0.name == mentee.name }) {
            return await addToMyMentees(existingMentee, monitorID: monitorID)
        }
        
        // Otherwise, create a new mentee
        let menteeFM = MenteeFM(
            name: mentee.name,
            email: mentee.email,
            phone: mentee.phone,
            progress: mentee.progress,
            monitorID: monitorID,
            imageName: mentee.imageName
        )
        
        return await addMentee(menteeFM)
    }
    
    /// Get the app's Mentee model from a FileMaker mentee
    func getAppMentee(from menteeFM: MenteeFM, includeAttendance: Bool = false) async -> Mentee {
        var attendanceRecords: [AttendanceRecord] = []
        
        if includeAttendance {
            // Fetch attendance records for this mentee
            do {
                let records = try await fileMakerService.fetchAttendanceRecords(for: menteeFM.id)
                attendanceRecords = records.map { record in
                    AttendanceRecord(
                        date: record.date,
                        status: record.status.toAppStatus(),
                        clockInTime: record.clockInTime,
                        clockOutTime: record.clockOutTime
                    )
                }
            } catch {
                print("Failed to fetch attendance records: \(error.localizedDescription)")
            }
        }
        
        // Convert to app's Mentee model
        return Mentee(
            name: menteeFM.name,
            progress: menteeFM.progress,
            email: menteeFM.email,
            phone: menteeFM.phone,
            imageName: menteeFM.imageName,
            attendanceRecords: attendanceRecords
        )
    }
    
    /// Convert a list of FileMaker mentees to app's Mentee models
    func getAppMentees(from menteesFM: [MenteeFM]) async -> [Mentee] {
        var mentees: [Mentee] = []
        
        for menteeFM in menteesFM {
            let mentee = await getAppMentee(from: menteeFM)
            mentees.append(mentee)
        }
        
        return mentees
    }
}

// MARK: - Compatibility Extension for MenteeManager

extension MenteeManager {
    /// Migrate data to FileMaker
    func migrateToFileMaker() {
        // Transfer myMentees to FileMaker
        for mentee in myMentees {
            let menteeFM = mentee.toFileMakerModel()
            
            Task {
                _ = try? await FileMakerService.shared.saveMentee(menteeFM)
            }
        }
        
        // Transfer allMentees to FileMaker
        for mentee in allMentees {
            let menteeFM = mentee.toFileMakerModel()
            
            Task {
                _ = try? await FileMakerService.shared.saveMentee(menteeFM)
            }
        }
    }
    
    /// Provide compatibility with new FileMaker implementation
    func removeFromMyMentees(_ mentee: Mentee) {
        // Call the FileMaker implementation
        Task {
            _ = await MenteeManagerFM.shared.removeFromMyMentees(mentee)
        }
        
        // Also update the local state for immediate UI updates
        myMentees.removeAll { $0.id == mentee.id }
        if !allMentees.contains(where: { $0.id == mentee.id }) {
            allMentees.append(mentee)
        }
    }
    
    /// Provide compatibility with new FileMaker implementation
    func addToMyMentees(_ mentee: Mentee) {
        // Get current user ID (assuming it's the monitor)
        guard let currentUser = UserManagerFM.shared.currentUser else {
            return
        }
        
        // Call the FileMaker implementation
        Task {
            _ = await MenteeManagerFM.shared.addToMyMentees(mentee, monitorID: currentUser.id)
        }
        
        // Also update the local state for immediate UI updates
        if !myMentees.contains(where: { $0.id == mentee.id }) {
            myMentees.append(mentee)
        }
        allMentees.removeAll { $0.id == mentee.id }
    }
}
