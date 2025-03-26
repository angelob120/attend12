//
//  TransferMenteeSheet.swift
//  New app working
//
//  Created by AB on 1/15/25.
//

import SwiftUI

struct TransferMenteeSheet: View {
    @EnvironmentObject var menteeManager: MenteeManager
    let mentee: Mentee
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 20) {
            Text("Manage Mentee")
                .font(.title2)
                .bold()
                .padding(.top, 20)

            // Remove Button
            Button(action: {
                menteeManager.removeFromMyMentees(mentee)
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Remove from My Mentees")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(10)
            }

            // Add Button
            Button(action: {
                menteeManager.addToMyMentees(mentee)
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Add to My Mentees")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
            }

            Spacer()
        }
        .padding()
    }
}
