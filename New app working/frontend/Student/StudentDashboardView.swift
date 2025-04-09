//
//  StudentDashboardView.swift
//  New app working
//
//  Created by AB on 1/9/25.
//  Modified to include a fixed 91% Attendance progress bar
//  followed by a Vacation progress bar showing remaining days off.
//

import SwiftUI

// MARK: - Custom Color Extensions
extension Color {
    /// Main custom green (hex #347E76)
    static let customGreen = Color(red: 52/255, green: 126/255, blue: 118/255)
    
    /// Lighter icon color (example: #D3E6E3)
    static let iconColor = Color(red: 211/255, green: 230/255, blue: 227/255)
}

// MARK: - Attendance Progress Bar View
struct AttendanceProgressBar: View {
    // The attendance percentage as a fraction (e.g., 0.91 for 91%)
    let percentage: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Attendance: \(Int(percentage * 100))%")
                .font(.headline)
                .foregroundColor(.primary)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track for the attendance progress
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: geometry.size.width, height: 20)
                        .foregroundColor(Color.gray.opacity(0.3))
                    // Filled portion representing the 91% attendance
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: geometry.size.width * CGFloat(percentage), height: 20)
                        .foregroundColor(Color.customGreen)
                        .animation(.easeInOut, value: percentage)
                }
            }
            .frame(height: 20)
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.customGreen, lineWidth: 1)
        )
    }
}

// MARK: - Vacation Progress Bar View
struct VacationProgressBar: View {
    // Remaining vacation hours available (update as needed)
    let remainingHours: Double
    // Total vacation hours available (160 hours = 40 days if 4 hours equal one day)
    let totalHours: Double = 160

    // Calculated progress fraction for the progress bar (from 0.0 to 1.0)
    var progress: Double {
        min(max(remainingHours / totalHours, 0.0), 1.0)
    }
    
    // Number of vacation days left (assuming 4 hours per day)
    var remainingDays: Int {
        Int(remainingHours / 4)
    }
    
    // Total vacation days available
    var totalDays: Int {
        Int(totalHours / 4)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Vacation: \(remainingDays) / \(totalDays) days left")
                .font(.headline)
                .foregroundColor(.primary)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: geometry.size.width, height: 20)
                        .foregroundColor(Color.gray.opacity(0.3))
                    // Filled portion representing the percentage of vacation days remaining
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: geometry.size.width * CGFloat(progress), height: 20)
                        .foregroundColor(Color.customGreen)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 20)
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.customGreen, lineWidth: 1)
        )
    }
}

// MARK: - StudentDashboardView
struct StudentDashboardView: View {
    @Environment(\.colorScheme) var colorScheme
    
    // Use a shared CloudKit configuration
    @EnvironmentObject var cloudKitConfig: CloudKitAppConfig
    
    // Timer service for tracking clock in/out
    @ObservedObject private var timerService = TimerService.shared
    
    // AttendanceManager for processing attendance actions
    @ObservedObject private var attendanceManager = AttendanceManager.shared
    
    @State private var selectedEvent: Event? = nil
    @State private var showQRScanner = false
    @State private var showCamera = false // For camera verification option
    @State private var attendanceError: String? = nil
    @State private var scanResult: String? = nil
    @State private var showInvalidCodeAlert = false
    @State private var showRolePicker = false // For role switching
    
    @StateObject private var scannerManager = QRCodeScannerManager()
    
    // For demo purposes: initial remaining vacation hours (96 hours equals 24 days)
    @State private var remainingTimeOffHours: Double = 96

    let maxTime: TimeInterval = 4 * 60 * 60 // 4 hours in seconds
    
    // Computed property to get the current month and year for the calendar section
    var currentMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: Date())
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Timer Circle (progress indicator) for Clocked In/Out status
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 10)
                            .foregroundColor(Color.customGreen.opacity(0.2))
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(timerService.progressPercentage()))
                            .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .foregroundColor(Color.customGreen)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut, value: timerService.elapsedTime)
                        
                        VStack(spacing: 4) {
                            Text(timerService.formattedElapsedTime())
                                .font(.title)
                                .bold()
                                .foregroundColor(.primary)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                            
                            Text(timerService.isTimerRunning ? "Clocked In" : "Clocked Out")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                    .frame(width: 200, height: 200)
                    .shadow(color: Color.customGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    // Attendance Progress Bar (fixed 91% attendance)
                    AttendanceProgressBar(percentage: 0.91)
                    
                    // Vacation Progress Bar displaying the remaining vacation days left.
                    VacationProgressBar(remainingHours: remainingTimeOffHours)
                    
                    // Calendar Section showing the current Month and Year
                    NavigationLink(destination: DetailedCalendarView()) {
                        VStack(spacing: 10) {
                            Text(currentMonthYear)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            let daysOfWeek = ["Mon", "Tus", "Wen", "Thu", "Fri"]
                            HStack(spacing: 0) {
                                ForEach(0..<5, id: \.self) { index in
                                    VStack {
                                        Text("\(14 + index)")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text(daysOfWeek[index])
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.customGreen, lineWidth: 1)
                        )
                    }
                    
                    // Event List Section
                    VStack(spacing: 10) {
                        ForEach(Event.sampleData) { event in
                            EventRow(event: event)
                                .onTapGesture {
                                    selectedEvent = event
                                }
                        }
                    }
                    
                    // Clock In/Out Button
                    HStack {
                        Spacer()
                        Button(action: {
                            // Both clock in and clock out require QR code scanning.
                            attendanceError = nil // Clear any previous errors
                            showQRScanner = true
                        }) {
                            Text(timerService.isTimerRunning ? "Clock Out" : "Clock In")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 150, height: 50)
                                .background(Color.customGreen)
                                .cornerRadius(10)
                                .shadow(color: Color.customGreen.opacity(0.1), radius: 5, x: 0, y: 4)
                        }
                        Spacer()
                    }
                    .sheet(isPresented: $showQRScanner) {
                        QRScannerView(scannerManager: scannerManager) { result in
                            processQRCodeScan(result)
                        }
                    }
                    
                    // Info about the clock in/out process
                    HStack {
                        Spacer()
                        VStack(alignment: .center, spacing: 4) {
                            Text("Status")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(timerService.isTimerRunning ?
                                "QR scan required to clock out" :
                                "QR scan required to clock in")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        Spacer()
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(.systemBackground))
                .sheet(item: $selectedEvent) { event in
                    event.detailView
                }
                .alert(isPresented: $showInvalidCodeAlert) {
                    Alert(
                        title: Text("Invalid Code"),
                        message: Text("The attendance code you entered is invalid. Please try again."),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.customGreen, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Dashboard")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "gear")
                            .foregroundColor(.iconColor)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: NotificationsView()) {
                        Image(systemName: "bell")
                            .foregroundColor(.iconColor)
                    }
                }
            }
        }
    }
    
    // Process QR Code Scan
    private func processQRCodeScan(_ code: String) {
        if verifyAttendanceCode(code) {
            DispatchQueue.main.async {
                showQRScanner = false
                attendanceError = nil // Clear any previous errors
                
                // Either clock in or clock out based on the current state
                if timerService.isTimerRunning {
                    clockOut()
                } else {
                    clockIn()
                }
            }
        } else {
            DispatchQueue.main.async {
                attendanceError = "Invalid attendance code"
                showInvalidCodeAlert = true
                showQRScanner = false
            }
        }
    }
    
    // Verifies the attendance code locally for added reliability
    private func verifyAttendanceCode(_ code: String) -> Bool {
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        let dateString = formatter.string(from: today)
        
        // Valid codes: today's date (MM-dd-yyyy), "9146", or "0000" for manual entry
        return code == dateString || code == "9146" || code == "0000"
    }
    
    // Clock In functionality using TimerService and AttendanceManager
    private func clockIn() {
        timerService.startTimer()
        attendanceError = nil
        Task {
            if let userId = cloudKitConfig.userManager.currentUser?.id {
                let success = await attendanceManager.clockIn(menteeID: userId)
                if !success {
                    DispatchQueue.main.async {
                        attendanceError = "Clock in recorded locally only"
                    }
                }
            }
        }
    }
    
    // Clock Out functionality using TimerService and AttendanceManager
    private func clockOut() {
        timerService.stopTimer()
        attendanceError = nil
        Task {
            let success = await attendanceManager.clockOut()
            if !success {
                DispatchQueue.main.async {
                    attendanceError = "Clock out recorded locally only"
                }
            }
        }
    }
}

// MARK: - EventRow (unchanged)
struct EventRow: View {
    let event: Event

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.date)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(event.day)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .bold()
                    .foregroundColor(.primary)
                Text(event.subtitle)
                    .foregroundColor(.primary)
            }
            Spacer()
            Image(systemName: "ellipsis")
                .rotationEffect(.degrees(90))
                .foregroundColor(.primary)
        }
        .padding()
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.customGreen, lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}
