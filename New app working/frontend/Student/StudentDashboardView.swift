//
//  StudentDashboardView.swift
//  New app working
//
//  Created by AB on 1/9/25.
//

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
    private let cloudKitConfig = CloudKitAppConfig.shared
    
    @State private var isPunchedIn = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer? = nil
    @State private var selectedEvent: Event? = nil
    @State private var showQRScanner = false
    @State private var showCamera = false
    @State private var attendanceError: String? = nil
    @State private var scanResult: String? = nil

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
                            .trim(from: 0, to: CGFloat(min(elapsedTime / maxTime, 1)))
                            .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .foregroundColor(Color.customGreen)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut, value: elapsedTime)
                        
                        VStack(spacing: 4) {
                            Text(formatTime(elapsedTime))
                                .font(.title)
                                .bold()
                                .foregroundColor(.primary)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                            
                            Text(isPunchedIn ? "Clocked In" : "Clocked Out")
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
                            if isPunchedIn {
                                clockOut()
                            } else {
                                showQRScanner = true
                            }
                        }) {
                            Text(isPunchedIn ? "Clock Out" : "Clock In")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 150, height: 50)
                                .background(isPunchedIn ? Color.gray : Color.customGreen)
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
                    .sheet(isPresented: $showCamera) {
                        CameraCaptureView {
                            startTimer()
                        }
                    }
                    
                    // New Button: Send Test Record
                    HStack {
                        Spacer()
                        Button(action: {
                            sendTestRecord()
                        }) {
                            Text("Send Test Record")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 150, height: 50)
                                .background(Color.blue)
                                .cornerRadius(10)
                                .shadow(color: Color.blue.opacity(0.1), radius: 5, x: 0, y: 4)
                        }
                        Spacer()
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(.systemBackground))
                .sheet(item: $selectedEvent) { event in
                    event.detailView
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
                    NavigationLink(destination: NotificationsView1()) {
                        Image(systemName: "bell")
                            .foregroundColor(.iconColor)
                    }
                }
            }
        }
    }
    
    // Process QR Code Scan
    private func processQRCodeScan(_ code: String) {
        Task {
            do {
                // Verify the attendance code
                let isValid = await cloudKitConfig.verifyAttendanceCode(code: code)
                
                if isValid {
                    // Show camera for additional verification
                    DispatchQueue.main.async {
                        showQRScanner = false
                        showCamera = true
                    }
                } else {
                    // Invalid code
                    DispatchQueue.main.async {
                        attendanceError = "Invalid attendance code"
                        showQRScanner = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    attendanceError = "Error verifying attendance: \(error.localizedDescription)"
                    showQRScanner = false
                }
            }
        }
    }
    
    // Start Timer and Clock In
    private func startTimer() {
        Task {
            do {
                // Clock in the user
                let success = await cloudKitConfig.clockInCurrentUser()
                
                if success {
                    DispatchQueue.main.async {
                        // Start the timer
                        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                            if elapsedTime < maxTime {
                                elapsedTime += 1
                            } else {
                                clockOut()
                            }
                        }
                        
                        isPunchedIn = true
                        showCamera = false
                        attendanceError = nil
                    }
                } else {
                    DispatchQueue.main.async {
                        attendanceError = "Failed to clock in. Please try again."
                        showCamera = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    attendanceError = "Error clocking in: \(error.localizedDescription)"
                    showCamera = false
                }
            }
        }
    }
    
    // Clock Out Function
    private func clockOut() {
        Task {
            do {
                // Clock out the user
                let success = await cloudKitConfig.clockOutCurrentUser()
                
                DispatchQueue.main.async {
                    if success {
                        // Stop and reset the timer
                        timer?.invalidate()
                        timer = nil
                        elapsedTime = 0
                        isPunchedIn = false
                        attendanceError = nil
                    } else {
                        attendanceError = "Failed to clock out. Please try again."
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    attendanceError = "Error clocking out: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // Format Time Function (HH:mm:ss)
    func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // New Function: Send Test Record to CloudKit
    private func sendTestRecord() {
        Task {
            do {
                // Create a dummy attendance record (replace UUID() with an actual menteeID if available)
                let testAttendance = AttendanceRecordCK(
                    menteeID: UUID(),
                    date: Date(),
                    clockInTime: Date(),
                    clockOutTime: Date().addingTimeInterval(3600), // 1 hour shift
                    status: .present
                )
                let savedRecord = try await CloudKitService.shared.saveAttendance(testAttendance)
                print("Test record saved successfully: \(savedRecord.id.uuidString)")
            } catch {
                print("Error saving test record: \(error.localizedDescription)")
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

// MARK: - NotificationsView (Placeholder)
struct NotificationsView: View {
    var body: some View {
        Text("Notifications")
            .font(.largeTitle)
            .foregroundColor(.primary)
            .navigationTitle("Notifications")
    }
}
