//
//  VacationDaysSheet.swift
//  New app working
//
//  Created by AB on 2/4/25.
//

import SwiftUI

struct VacationDaysSheet: View {
    @Binding var vacationStartDate: Date
    @Binding var vacationEndDate: Date
    @ObservedObject var userManager: CustomUserManager // Ensure this matches the correct declaration
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Declare Vacation Days")
                        .font(.headline)
                        .padding(.bottom, 5)

                    DatePicker("Start Date", selection: $vacationStartDate, displayedComponents: .date)
                    
                    DatePicker("End Date", selection: $vacationEndDate, displayedComponents: .date)
                        .onChange(of: vacationStartDate) { newValue in
                            if vacationEndDate < newValue {
                                vacationEndDate = newValue
                            }
                        }

                    Button {
                        userManager.declareVacationDays(startDate: vacationStartDate, endDate: vacationEndDate)
                        dismiss()
                    } label: {
                        Label("Apply Vacation Days", systemImage: "calendar.badge.plus")
                            .foregroundColor(.green)
                    }
                }
                .padding(.vertical, 10)
            }
            .navigationTitle("Vacation Days")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}
