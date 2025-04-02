import SwiftUI
import UIKit
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Register background tasks
        registerBackgroundTasks()
        
        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Save timer state when app terminates
        // TimerService handles this automatically
    }
    
    // MARK: - Background Tasks
    
    func registerBackgroundTasks() {
        // Register background task for timer updates
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.example.timerUpdate", using: nil) { task in
            self.handleTimerUpdate(task: task as! BGAppRefreshTask)
        }
        
        // Register background task for clock out
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.example.autoClockOut", using: nil) { task in
            self.handleAutoClockOut(task: task as! BGAppRefreshTask)
        }
    }
    
    func scheduleBackgroundTimerUpdate() {
        let request = BGAppRefreshTaskRequest(identifier: "com.example.timerUpdate")
        // Schedule for sooner than 15 minutes if possible
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule timer update: \(error)")
        }
    }
    
    func scheduleBackgroundClockOut() {
        guard let clockInDate = TimerService.shared.clockInDate else { return }
        
        let maxTimeDate = clockInDate.addingTimeInterval(TimerService.shared.maxTime)
        let now = Date()
        
        // Only schedule if we haven't reached max time yet
        if maxTimeDate > now {
            let request = BGAppRefreshTaskRequest(identifier: "com.example.autoClockOut")
            request.earliestBeginDate = maxTimeDate
            
            do {
                try BGTaskScheduler.shared.submit(request)
            } catch {
                print("Could not schedule auto clock out: \(error)")
            }
        }
    }
    
    func handleTimerUpdate(task: BGAppRefreshTask) {
        // Create a task assertion to protect this code from being suspended
        let taskAssertionID = UIBackgroundTaskIdentifier.invalid
        
        // Schedule the next update
        scheduleBackgroundTimerUpdate()
        
        // Check if the timer is running
        if TimerService.shared.isTimerRunning {
            // Update elapsed time calculation
            if let clockInDate = TimerService.shared.clockInDate {
                let elapsedTime = Date().timeIntervalSince(clockInDate)
                
                // If we've reached max time, clock out
                if elapsedTime >= TimerService.shared.maxTime {
                    // Schedule auto clock out
                    scheduleBackgroundClockOut()
                }
            }
        }
        
        // Call the completion handler
        task.setTaskCompleted(success: true)
    }
    
    func handleAutoClockOut(task: BGAppRefreshTask) {
        // Create a task assertion to protect this code from being suspended
        let taskAssertionID = UIBackgroundTaskIdentifier.invalid
        
        // Only perform if the timer is still running
        if TimerService.shared.isTimerRunning {
            // Check if we've reached max time
            if let clockInDate = TimerService.shared.clockInDate {
                let elapsedTime = Date().timeIntervalSince(clockInDate)
                
                if elapsedTime >= TimerService.shared.maxTime {
                    // For auto-clock out after maximum time, we need to bypass QR code
                    // requirement, as this happens automatically for safety reasons
                    
                    // Set a flag in UserDefaults that indicates auto clock-out happened
                    UserDefaults.standard.set(true, forKey: "autoClockOutOccurred")
                    UserDefaults.standard.set(Date(), forKey: "autoClockOutTime")
                    
                    // Perform clock out
                    TimerService.shared.stopTimer()
                    
                    // Create a special notification for auto-clock out
                    let content = UNMutableNotificationContent()
                    content.title = "Auto Clock Out"
                    content.body = "You have been automatically clocked out after 4 hours. This is a safety feature."
                    content.sound = .default
                    
                    let request = UNNotificationRequest(
                        identifier: "autoClockOutAlert",
                        content: content,
                        trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                    )
                    
                    UNUserNotificationCenter.current().add(request)
                    
                    // Try to update CloudKit
                    Task {
                        do {
                            let attendance = AttendanceRecordCK(
                                menteeID: UUID(), // Replace with actual user ID
                                date: Date(),
                                clockInTime: clockInDate,
                                clockOutTime: Date(),
                                status: .present
                            )
                            _ = try await CloudKitService.shared.updateAttendance(attendance)
                        } catch {
                            print("Error updating CloudKit: \(error)")
                        }
                    }
                }
            }
        }
        
        // Call the completion handler
        task.setTaskCompleted(success: true)
    }
}

// MARK: - Scene Delegate
class SceneDelegate: NSObject, UIWindowSceneDelegate {
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Schedule background tasks when the scene enters background
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        // Schedule timer update
        appDelegate.scheduleBackgroundTimerUpdate()
        
        // Schedule auto clock out if timer is running
        if TimerService.shared.isTimerRunning {
            appDelegate.scheduleBackgroundClockOut()
        }
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Cancel any background tasks as they're not needed when app is in foreground
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: "com.example.timerUpdate")
    }
}
