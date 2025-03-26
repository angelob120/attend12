//
//  AttendanceLegendItem.swift
//  New app working
//
//  Created by AB on 1/15/25.
//

import SwiftUI

struct AttendanceLegendItem: View {
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .foregroundColor(color)
                .frame(width: 10, height: 10)
            Text(text)
                .font(.subheadline)
        }
    }
}
