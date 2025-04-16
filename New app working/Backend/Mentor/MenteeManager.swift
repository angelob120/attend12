//
//  MenteeManager.swift
//  New app working
//
//  Created by AB on 1/15/25.
//

import Foundation

class MenteeManager: ObservableObject {
    @Published var myMentees: [Mentee] = SampleMenteeData.myMentees
    @Published var allMentees: [Mentee] = SampleMenteeData.allMentees

    /// Remove mentee from My Mentees
    func removeFromMyMentees1(_ mentee: Mentee) {
        myMentees.removeAll { $0.id == mentee.id }
        if !allMentees.contains(where: { $0.id == mentee.id }) {
            allMentees.append(mentee)
        }
    }

    /// Add mentee to My Mentees
    func addToMyMentees1(_ mentee: Mentee) {
        if !myMentees.contains(where: { $0.id == mentee.id }) {
            myMentees.append(mentee)
        }
        allMentees.removeAll { $0.id == mentee.id }
    }
}
