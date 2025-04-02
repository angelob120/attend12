//
//  AttendanceManager.swift
//  New app working
//
//  Created by AB on 3/26/25.
//

import Foundation
import SwiftUI
import Combine
import CoreLocation

// MARK: - Attendance Manager
class AttendanceManager: ObservableObject {
    // Singleton instance
    static let shared = AttendanceManager()
    
    // Published properties
    @Published var attendanceRecords: [AttendanceRecordCK] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentUserAttendance: AttendanceRecordCK?
    @Published var isClockedIn = false
    
    // References
    private let cloudService = CloudKitService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Private initializer for singleton
    private init() {
        // Setup any observation needed
        setupObservers()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observe user's clock in status changes
        $currentUserAttendance
            .map { $0 != nil }
            .assign(to: \.isClockedIn, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Attendance Record Management
    
    /// Fetch attendance records for a specific mentee
    func fetchAttendanceRecords(for menteeID: UUID) async {
        guard !isLoading else { return }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let records = try await cloudService.fetchAttendanceRecords(for: menteeID)
            
            DispatchQueue.main.async {
                self.attendanceRecords = records
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.error = "Failed to fetch attendance records: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// Fetch attendance by date range
    func fetchAttendanceRecords(from startDate: Date, to endDate: Date) async {
        guard !isLoading else { return }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let records = try await cloudService.fetchAttendanceRecords(from: startDate, to: endDate)
            
            DispatchQueue.main.async {
                self.attendanceRecords = records
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.error = "Failed to fetch attendance records: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// Clock in a mentee
    func clockIn(menteeID: UUID, location: CLLocation? = nil) async -> Bool {
        guard !isLoading, !isClockedIn else { return false }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let now = Date()
            
            // Create new attendance record
            let attendanceRecord = AttendanceRecordCK(
                menteeID: menteeID,
                date: now,
                clockInTime: now,
                clockOutTime: now.addingTimeInterval(8 * 3600), // Default 8-hour shift
                status: .present,
                location: location
            )
            
            // Save the record to CloudKit
            let savedRecord = try await cloudService.saveAttendance(attendanceRecord)
            
            DispatchQueue.main.async {
                self.currentUserAttendance = savedRecord
                self.attendanceRecords.append(savedRecord)
                self.isLoading = false
            }
            
            return true
        } catch {
            DispatchQueue.main.async {
                self.error = "Failed to clock in: \(error.localizedDescription)"
                self.isLoading = false
            }
            
            return false
        }
    }
    
    /// Clock out a mentee
    func clockOut() async -> Bool {
        guard !isLoading, isClockedIn, let currentAttendance = currentUserAttendance else { return false }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            // Update the record with actual clock out time
            var updatedAttendance = currentAttendance
            updatedAttendance.record?[AttendanceKeys.clockOutTime] = Date()
            
            // Calculate tardiness
            let startOfDay = Calendar.current.startOfDay(for: currentAttendance.date)
            let expectedClockIn = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: startOfDay)!
            
            // If clocked in after 9:15 AM, mark as tardy
            if currentAttendance.clockInTime.timeIntervalSince(expectedClockIn) > 15 * 60 {
                updatedAttendance.record?[AttendanceKeys.status] = AttendanceStatusCK.tardy.recordValue
            }
            
            // Save the updated record
            if let record = updatedAttendance.record {
                let _ = try await cloudService.updateAttendance(updatedAttendance)
                
                DispatchQueue.main.async {
                    self.currentUserAttendance = nil
                    
                    // Update the record in the array
                    if let index = self.attendanceRecords.firstIndex(where: { $0.id == updatedAttendance.id }) {
                        self.attendanceRecords[index] = updatedAttendance
                    }
                    
                    self.isLoading = false
                }
                
                return true
            } else {
                throw CloudKitError.recordNotFound
            }
        } catch {
            DispatchQueue.main.async {
                self.error = "Failed to clock out: \(error.localizedDescription)"
                self.isLoading = false
            }
            
            return false
        }
    }
    
    /// Mark a user as absent
    func markAbsent(menteeID: UUID, date: Date) async -> Bool {
        guard !isLoading else { return false }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            // Create an absence record
            let startOfDay = Calendar.current.startOfDay(for: date)
            let defaultClockIn = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: startOfDay)!
            let defaultClockOut = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: startOfDay)!
            
            let absentRecord = AttendanceRecordCK(
                menteeID: menteeID,
                date: startOfDay,
                clockInTime: defaultClockIn,
                clockOutTime: defaultClockOut,
                status: .absent
            )
            
            // Save the record to CloudKit
            let savedRecord = try await cloudService.saveAttendance(absentRecord)
            
            DispatchQueue.main.async {
                self.attendanceRecords.append(savedRecord)
                self.isLoading = false
            }
            
            return true
        } catch {
            DispatchQueue.main.async {
                self.error = "Failed to mark as absent: \(error.localizedDescription)"
                self.isLoading = false
            }
            
            return false
        }
    }
    
    /// Update an attendance record
    func updateAttendance(record: AttendanceRecordCK) async -> Bool {
        guard !isLoading else { return false }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let updatedRecord = try await cloudService.updateAttendance(record)
            
            DispatchQueue.main.async {
                // Update the record in the array
                if let index = self.attendanceRecords.firstIndex(where: { $0.id == updatedRecord.id }) {
                    self.attendanceRecords[index] = updatedRecord
                }
                
                // Update current user's attendance if it matches
                if self.currentUserAttendance?.id == updatedRecord.id {
                    self.currentUserAttendance = updatedRecord
                }
                
                self.isLoading = false
            }
            
            return true
        } catch {
            DispatchQueue.main.async {
                self.error = "Failed to update attendance: \(error.localizedDescription)"
                self.isLoading = false
            }
            
            return false
        }
    }
    
    /// Delete an attendance record
    func deleteAttendance(record: AttendanceRecordCK) async -> Bool {
        guard !isLoading else { return false }
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            try await cloudService.deleteAttendance(record)
            
            DispatchQueue.main.async {
                // Remove the record from the array
                self.attendanceRecords.removeAll(where: { $0.id == record.id })
                
                // Clear current user's attendance if it matches
                if self.currentUserAttendance?.id == record.id {
                    self.currentUserAttendance = nil
                }
                
                self.isLoading = false
            }
            
            return true
        } catch {
            DispatchQueue.main.async {
                self.error = "Failed to delete attendance: \(error.localizedDescription)"
                self.isLoading = false
            }
            
            return false
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get monthly attendance summary for UI
    func getMonthlyAttendanceSummary(for menteeID: UUID, month: Date) -> (present: Int, absent: Int, tardy: Int) {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month))!
        let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!
        
        let filteredRecords = attendanceRecords.filter { record in
            record.menteeID == menteeID &&
            record.date >= monthStart &&
            record.date <= monthEnd
        }
        
        let presentCount = filteredRecords.filter { $0.status == .present }.count
        let absentCount = filteredRecords.filter { $0.status == .absent }.count
        let tardyCount = filteredRecords.filter { $0.status == .tardy }.count
        
        return (present: presentCount, absent: absentCount, tardy: tardyCount)
    }
    
    /// Get attendance record for a specific date and mentee
    func getAttendanceRecord(for menteeID: UUID, on date: Date) -> AttendanceRecordCK? {
        let calendar = Calendar.current
        return attendanceRecords.first { record in
            record.menteeID == menteeID &&
            calendar.isDate(record.date, inSameDayAs: date)
        }
    }
    
    /// Calculate total hours worked in a date range
    func calculateHoursWorked(for menteeID: UUID, from startDate: Date, to endDate: Date) -> (hours: Int, minutes: Int) {
        let filteredRecords = attendanceRecords.filter { record in
            record.menteeID == menteeID &&
            record.date >= startDate &&
            record.date <= endDate &&
            record.status != .absent // Don't count absences
        }
        
        let totalSeconds = filteredRecords.reduce(0) { sum, record in
            sum + record.clockOutTime.timeIntervalSince(record.clockInTime)
        }
        
        let totalMinutes = Int(totalSeconds / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        return (hours: hours, minutes: minutes)
    }
    
    /// Get attendance status for a QR code or numeric code
    func verifyAttendanceCode(code: String) -> Bool {
        // In a real app, you might verify the code against a server or local database
        // For this example, let's use a simple approach
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        let dateString = formatter.string(from: today)
        
        // Check if the code matches today's date or is one of the valid numeric codes
        // "0000" is specifically for manual clock in
        return code == dateString || code == "9146" || code == "0000"
    }
    
    /// Get the current clock status for display
    func getCurrentClockStatus() -> (isClocked: Bool, time: TimeInterval, status: String) {
        guard let currentAttendance = currentUserAttendance else {
            return (isClocked: false, time: 0, status: "Clocked Out")
        }
        
        let elapsedTime = Date().timeIntervalSince(currentAttendance.clockInTime)
        return (isClocked: true, time: elapsedTime, status: "Clocked In")
    }
    
    /// Reset the state (for logout)
    func reset() {
        attendanceRecords = []
        currentUserAttendance = nil
        error = nil
    }
}
