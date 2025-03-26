//
//  RequestTimeOffView.swift
//  New app working
//
//  Created by AB on 1/13/25.
//

import SwiftUI


struct RequestTimeOffView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedDate = Date()
    @State private var reason = ""

    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Request Time Off")
                .font(.title)
                .bold()
                .foregroundColor(.primary)
                .padding(.top)
            
            // DatePicker with custom styling
            DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.customGreen, lineWidth: 1)
                )
            
            // TextField for reason with matching style
            TextField("Reason for time off...", text: $reason)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.customGreen, lineWidth: 1)
                )
                .foregroundColor(.primary)
                .textFieldStyle(PlainTextFieldStyle())
            
            // Submit Button styled like other action buttons
            Button(action: {
                // Functionality for submitting the request
            }) {
                Text("Submit Request")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.customGreen)
                    .cornerRadius(10)
                    .shadow(color: Color.customGreen.opacity(0.2), radius: 5, x: 0, y: 4)
                    .padding(.horizontal)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .navigationTitle("Request Time Off")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RequestTimeOffView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RequestTimeOffView()
        }
    }
}
