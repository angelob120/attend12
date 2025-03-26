//
//  MenteeManager.swift
//  New app working
//
//  Created by AB on 3/26/25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Mentee Manager
class MenteeManagerCK: ObservableObject {
    // Singleton instance
    static let shared = MenteeManagerCK()
    
    // Published properties
    @Published var myMentees: [MenteeCK] = []
    @Published var allMentees: [MenteeCK] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // References
    private let cloudService = CloudKitService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Private initializer for singleton
    private init() {
        // Initial data fetch if user is signed in
        cloudService.$isUserSignedIn
            .filter { $0 }
            .sink { [weak self] _ in
                Task {
                    await self?.fetchAllMentees()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Mentee Management
    
    /// Fetch all mentees from CloudKit
    func fetchAllMentees() async {
        guard !isLoading else { return }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let mentees = try await cloudService.fetchAllMentees()
            
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
            let mentees = try await cloudService.fetchMentees(for: monitorID)
            
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
    func addMentee(_ mentee: MenteeCK) async -> Bool {
        guard !isLoading else { return false }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let savedMentee = try await cloudService.saveMentee(mentee)
            
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
    func updateMentee(_ mentee: MenteeCK) async -> Bool {
        guard !isLoading else { return false }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let updatedMentee = try await cloudService.updateMentee(mentee)
            
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
    
    /// Remove a mentee fromMyMentees (set monitorID to nil)
    func removeFromMyMentees(_ mentee: MenteeCK) async -> Bool {
        guard !isLoading else { return false }
        
        // Create a modified mentee with no monitor
        var modifiedMentee = mentee
        if let record = mentee.record {
            record[MenteeKeys.monitorID] = nil
        }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let updatedMentee = try await cloudService.updateMentee(modifiedMentee)
            
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
    func addToMyMentees(_ mentee: MenteeCK, monitorID: UUID) async -> Bool {
        guard !isLoading else { return false }
        
        // Create a modified mentee with the monitor ID
        var modifiedMentee = mentee
        if let record = mentee.record {
            record[MenteeKeys.monitorID] = monitorID.uuidString
        }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let updatedMentee = try await cloudService.updateMentee(modifiedMentee)
            
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
    func deleteMentee(_ mentee: MenteeCK) async -> Bool {
        guard !isLoading else { return false }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            try await cloudService.deleteMentee(mentee)
            
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
    func updateMenteeProgress(_ mentee: MenteeCK, progress: Int) async -> Bool {
        guard !isLoading else { return false }
        
        // Create a modified mentee with updated progress
        var modifiedMentee = mentee
        if let record = mentee.record {
            record[MenteeKeys.progress] = progress
        }
        
        return await updateMentee(modifiedMentee)
    }
    
    /// Get a mentee by ID
    func getMentee(with id: UUID) -> MenteeCK? {
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
}

// MARK: - Helper Extension to Bridge Old Model with CloudKit Model
extension Mentee {
    func toCloudKitModel() -> MenteeCK {
        return MenteeCK(
            id: id,
            name: name,
            email: email,
            phone: phone,
            progress: progress,
            monitorID: nil  // Set this as needed
        )
    }
}

extension MenteeCK {
    func toAppModel() -> Mentee {
        return Mentee(
            name: name,
            progress: progress,
            email: email,
            phone: phone,
            imageName: "profile1",  // Default image
            attendanceRecords: []  // Attendance will be handled separately
        )
    }
}
