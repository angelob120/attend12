//
//  MyMenteesView.swif.swift
//  New app working
//
//  Created by AB on 1/15/25.
//

import SwiftUI

struct MyMenteesView: View {
    @EnvironmentObject var menteeManager: MenteeManager

    var body: some View {
        List {
            ForEach(menteeManager.myMentees) { mentee in
                NavigationLink(destination: MenteeDetailView(mentee: mentee)) {
                    MenteeRow(mentee: mentee)
                }
            }
        }
        .navigationTitle("My Mentees")
    }
}
