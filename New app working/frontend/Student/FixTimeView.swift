//
//  FixTimeView.swift
//  New app working
//
//  Created by AB on 1/13/25.
//

import SwiftUI

struct FixTimeView: View {
    @State private var clockInTime: String = ""   // State for Clock-In Time
    @State private var clockOutTime: String = ""  // State for Clock-Out Time
    @State private var showAlert: Bool = false    // State for Alert
    @State private var alertMessage: String = ""  // Alert Message

    var body: some View {
        VStack(spacing: 20) {
            Text("Fix Time")
                .font(.title)
                .bold()
                .foregroundColor(.primary)

            Text("Adjust your clock-in and clock-out times below.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()

            // Clock-In Time Input
            TimeInputField(label: "Clock-In Time (HH:MM AM/PM)", text: $clockInTime)

            // Clock-Out Time Input
            TimeInputField(label: "Clock-Out Time (HH:MM AM/PM)", text: $clockOutTime)

            // Submit Button
            Button(action: submitFix) {
                Text("Submit Fix")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.blue) // Changed from Green to Blue
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .navigationTitle("Fix Time")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground)) // Adapts to Light & Dark Mode
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Submission Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - Submit Function
    private func submitFix() {
        if validateTimeFormat(clockInTime) && validateTimeFormat(clockOutTime) {
            alertMessage = "Clock-In: \(clockInTime)\nClock-Out: \(clockOutTime)\n\nYour time has been submitted."
        } else {
            alertMessage = "Please enter both times in the correct format (e.g., 08:30 AM)."
        }
        showAlert = true
    }

    // MARK: - Time Format Validation
    private func validateTimeFormat(_ time: String) -> Bool {
        let timeFormat = "^(0[1-9]|1[0-2]):[0-5][0-9]\\s?(AM|PM|am|pm)$"
        return time.range(of: timeFormat, options: .regularExpression) != nil
    }
}

// MARK: - TimeInputField (Reusable Component)
struct TimeInputField: View {
    let label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.subheadline)
                .bold()
                .foregroundColor(.primary)
            TextField("Enter \(label)", text: $text)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .foregroundColor(.primary)
                .keyboardType(.default)
                .autocapitalization(.none)
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview
struct FixTimeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FixTimeView()
        }
        .preferredColorScheme(.dark) // Preview in Dark Mode
        NavigationView {
            FixTimeView()
        }
        .preferredColorScheme(.light) // Preview in Light Mode
    }
}
