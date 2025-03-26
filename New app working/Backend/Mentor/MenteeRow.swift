//
//  MenteeRow.swift
//  New app working
//
//  Created by AB on 1/15/25.
//

import SwiftUI

struct MenteeRow: View {
    let mentee: Mentee

    var body: some View {
        HStack {
            // Profile Image
            Image(systemName: "person.crop.circle.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                .padding(.trailing, 10)

            // Mentee Name
            Text(mentee.name)
                .font(.headline)

            Spacer()

            // Progress Percentage
            Text("\(mentee.progress)%")
                .foregroundColor(.green)
                .font(.headline)

            // Chevron Icon
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

