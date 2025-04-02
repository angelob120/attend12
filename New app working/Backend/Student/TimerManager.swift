//
//  TimerManager.swift
//  New app working
//
//  Created by AB on 4/1/25.
//


import Foundation
import SwiftUI
import UserNotifications

// MARK: - Timer Service
class TimerService: ObservableObject {
    // Singleton instance
    static let shared = TimerService()
    
    // Published properties
    @Published var isTimerRunning = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var clockInDate: Date?
    
    // Constants
    let maxTime: TimeInterval = 4 * 60 * 60 // 4 hours
    private let timerKey = "clockInTimerData"
    private let userDefaults = UserDefaults.standard
    
    // Timer reference
    private var timer: Timer?
    
    // Private initializer for singleton
    private init() {
        // Restore timer state if the app was terminated
        restoreTimerState()
        
        // Set up notification for background time tracking
        setupNotificationSettings()
        
        // Add observer for app foreground event to update the timer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        // Add observer for app background event to save the timer state
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Timer Controls
    
    /// Start the timer and save state to UserDefaults
    func startTimer() {
        guard !isTimerRunning else { return }
        
        let now = Date()
        clockInDate = now
        isTimerRunning = true
        elapsedTime = 0
        
        // Create repeating timer
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // If we've reached max time, stop the timer
            if self.elapsedTime >= self.maxTime {
                self.stopTimer()
                self.scheduleAutoClockOutNotification()
            } else {
                self.updateElapsedTime()
            }
        }
        
        // Save the timer state to UserDefaults
        saveTimerState()
        
        // Schedule a notification for when the timer reaches max time
        scheduleMaxTimeNotification()
    }
    
    /// Stop the timer and clear state from UserDefaults
    func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
        clockInDate = nil
        elapsedTime = 0
        
        // Clear the timer state from UserDefaults
        clearTimerState()
        
        // Remove any pending notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Schedule confirmation notification
        let content = UNMutableNotificationContent()
        content.title = "Clock Out Successful"
        content.body = "You have been successfully clocked out."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "clockOutConfirmation",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Update the elapsed time based on the clock in date
    private func updateElapsedTime() {
        guard let clockInDate = clockInDate else { return }
        
        elapsedTime = min(Date().timeIntervalSince(clockInDate), maxTime)
        
        // Save the state periodically (every minute) to reduce writes
        if Int(elapsedTime) % 60 == 0 {
            saveTimerState()
        }
    }
    
    // MARK: - State Persistence
    
    /// Save the timer state to UserDefaults
    private func saveTimerState() {
        let timerData: [String: Any] = [
            "isRunning": isTimerRunning,
            "clockInDate": clockInDate as Any,
            "elapsedTime": elapsedTime
        ]
        
        userDefaults.set(timerData, forKey: timerKey)
    }
    
    /// Restore the timer state from UserDefaults
    private func restoreTimerState() {
        guard let timerData = userDefaults.dictionary(forKey: timerKey),
              let isRunning = timerData["isRunning"] as? Bool,
              isRunning == true else {
            return
        }
        
        // Extract the clock in date
        if let clockInDate = timerData["clockInDate"] as? Date {
            self.clockInDate = clockInDate
            
            // Calculate elapsed time from clock in date
            elapsedTime = min(Date().timeIntervalSince(clockInDate), maxTime)
            
            // Only restart the timer if we haven't reached max time
            if elapsedTime < maxTime {
                isTimerRunning = true
                
                // Start the timer again
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                    guard let self = self else { return }
                    
                    if self.elapsedTime >= self.maxTime {
                        self.stopTimer()
                        self.scheduleAutoClockOutNotification()
                    } else {
                        self.updateElapsedTime()
                    }
                }
            } else {
                // We've already reached max time, stop the timer
                stopTimer()
                scheduleAutoClockOutNotification()
            }
        }
    }
    
    /// Clear the timer state from UserDefaults
    private func clearTimerState() {
        userDefaults.removeObject(forKey: timerKey)
    }
    
    // MARK: - Notification Handling
    
    /// Set up notification settings
    private func setupNotificationSettings() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission denied: \(error.localizedDescription)")
            }
        }
    }
    
    /// Schedule notification for when timer reaches max time
    private func scheduleMaxTimeNotification() {
        guard let clockInDate = clockInDate else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Clock Out Reminder"
        content.body = "You've reached the maximum time limit of 4 hours and have been automatically clocked out."
        content.sound = .default
        
        // Calculate when 4 hours will be reached
        let maxTimeDate = clockInDate.addingTimeInterval(maxTime)
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: maxTimeDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // Create the request
        let request = UNNotificationRequest(identifier: "maxTimeReached", content: content, trigger: trigger)
        
        // Add the request to the notification center
        UNUserNotificationCenter.current().add(request)
    }
    
    /// Schedule a notification for auto clock out
    private func scheduleAutoClockOutNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Auto Clock Out"
        content.body = "You've been automatically clocked out after reaching 4 hours."
        content.sound = .default
        
        // Create the request with immediate trigger
        let request = UNNotificationRequest(
            identifier: "autoClockOut",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        
        // Add the request to the notification center
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - App Lifecycle Observers
    
    @objc private func appWillEnterForeground() {
        // Update elapsed time if timer is running
        if isTimerRunning, let clockInDate = clockInDate {
            elapsedTime = min(Date().timeIntervalSince(clockInDate), maxTime)
            
            // If we've reached max time, stop the timer
            if elapsedTime >= maxTime {
                stopTimer()
            }
        }
    }
    
    @objc private func appDidEnterBackground() {
        // Save timer state when app goes to background
        if isTimerRunning {
            saveTimerState()
        }
    }
    
    // MARK: - Helper Functions
    
    /// Format elapsed time as HH:MM:SS
    func formattedElapsedTime() -> String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    /// Get percentage of max time completed (0.0 to 1.0)
    func progressPercentage() -> Double {
        return min(elapsedTime / maxTime, 1.0)
    }
}
