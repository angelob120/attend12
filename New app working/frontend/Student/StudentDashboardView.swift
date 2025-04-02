//
//  StudentDashboardView.swift
//  New app working
//
//  Created by AB on 1/9/25.
//  Modified to handle invalid attendance codes properly

import SwiftUI

// MARK: - Custom Color Extensions
extension Color {
    /// Main custom green (hex #347E76)
    static let customGreen = Color(red: 52/255, green: 126/255, blue: 118/255)
    
    /// Lighter icon color (example: #D3E6E3)
    static let iconColor = Color(red: 211/255, green: 230/255, blue: 227/255)
}

struct StudentDashboardView: View {
    @Environment(\.colorScheme) var colorScheme
    
    // Use a local reference to the shared CloudKit configuration
    @EnvironmentObject var cloudKitConfig: CloudKitAppConfig
    
    // Use the TimerService instead of local timer state
    @ObservedObject private var timerService = TimerService.shared
    
    // Use the AttendanceManager for clock in/out
    @ObservedObject private var attendanceManager = AttendanceManager.shared
    
    @State private var selectedEvent: Event? = nil
    @State private var showQRScanner = false
    @State private var showCamera = false // Add this for camera verification option
    @State private var attendanceError: String? = nil
    @State private var scanResult: String? = nil
    @State private var showInvalidCodeAlert = false

    @StateObject private var scannerManager = QRCodeScannerManager()

    let maxTime: TimeInterval = 4 * 60 * 60 // 4 hours in seconds
    
    // Computed property to get the current month and year
    var currentMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: Date())
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Timer Circle (Progress Bar) with Clocked In/Out Status
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
                    
                    // Error Message Display
                    if let error = attendanceError {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    // Mentor Details (Remaining Time Off) with Green Outline
                    VStack(spacing: 10) {
                        DetailRow(label: "Remaining Time Off:", value: "96 Hours 20 days")
                    }
                    
                    // Calendar Section showing Month and Year
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
                    
                    // Event List
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
                            // Both clock in and clock out require QR code scanning
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
                    
                    // Info about clock in/out process
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
        // Verify the attendance code
        if verifyAttendanceCode(code) {
            DispatchQueue.main.async {
                showQRScanner = false
                attendanceError = nil // Clear any previous errors
                
                // Either clock in or clock out based on current state
                if timerService.isTimerRunning {
                    clockOut()
                } else {
                    clockIn()
                }
            }
        } else {
            DispatchQueue.main.async {
                // Show error alert instead of just setting the error message
                attendanceError = "Invalid attendance code"
                showInvalidCodeAlert = true
                showQRScanner = false
            }
        }
    }
    
    // Local verification method to make this more reliable
    private func verifyAttendanceCode(_ code: String) -> Bool {
        // Check if the code matches today's date or is the valid numeric code
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        let dateString = formatter.string(from: today)
        
        // Valid codes are today's date (MM-dd-yyyy), "9146", or "0000" for manual entry
        return code == dateString || code == "9146" || code == "0000"
    }
    
    // Clock In function using our TimerService
    private func clockIn() {
        // Start the timer with the persistent service
        timerService.startTimer()
        
        // Clear any error messages
        attendanceError = nil
        
        // Use AttendanceManager to handle the clock in
        Task {
            if let userId = cloudKitConfig.userManager.currentUser?.id {
                let success = await attendanceManager.clockIn(menteeID: userId)
                if !success {
                    // If CloudKit update fails, show error but keep timer running
                    DispatchQueue.main.async {
                        attendanceError = "Clock in recorded locally only"
                    }
                }
            }
        }
    }
    
    // Clock Out Function using our TimerService
    private func clockOut() {
        // Stop timer with the persistent service
        timerService.stopTimer()
        
        // Clear any error messages
        attendanceError = nil
        
        // Use AttendanceManager to handle the clock out
        Task {
            let success = await attendanceManager.clockOut()
            if !success {
                // If CloudKit update fails, show error
                DispatchQueue.main.async {
                    attendanceError = "Clock out recorded locally only"
                }
            }
        }
    }
}

// MARK: - DetailRow
struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .bold()
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .foregroundColor(.primary)
        }
        .padding()
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.customGreen, lineWidth: 1)
        )
    }
}

// MARK: - EventRow
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
