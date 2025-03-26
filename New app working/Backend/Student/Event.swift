//
//  Event.swift
//  New app working
//
//  Created by AB on 1/13/25.
//

import SwiftUI

// MARK: - Event Model

struct Event: Identifiable {
    let id = UUID()
    let date: String
    let day: String
    let title: String
    let subtitle: String
    let isHighlighted: Bool
    let detailView: AnyView
}

// MARK: - Sample Data with Linked Detail Views

extension Event {
    static let sampleData: [Event] = [
        Event(
            date: "SEP:3",
            day: "WED",
            title: "Networking Event",
            subtitle: "Professional networking event.",
            isHighlighted: true,
            detailView: AnyView(NetworkingEventDetailView())
        ),
        Event(
            date: "SEP:4",
            day: "THU",
            title: "Workshop",
            subtitle: "Interactive learning session.",
            isHighlighted: false,
            detailView: AnyView(WorkshopDetailView())
        ),
        Event(
            date: "SEP:5",
            day: "FRI",
            title: "Presentation",
            subtitle: "Project showcase.",
            isHighlighted: true,
            detailView: AnyView(PresentationDetailView())
        )
    ]
}

// MARK: - Networking Event Detail View

struct NetworkingEventDetailView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Networking Event")
                .font(.largeTitle)
                .bold()
            
            Text("Join us for a professional networking event where you'll meet industry leaders and peers.")
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
        }
        .padding()
        .navigationTitle("Networking Event")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Workshop Detail View

struct WorkshopDetailView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Workshop")
                .font(.largeTitle)
                .bold()
            
            Text("Participate in hands-on learning with interactive sessions designed to improve your skills.")
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
        }
        .padding()
        .navigationTitle("Workshop")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Presentation Detail View

struct PresentationDetailView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Presentation")
                .font(.largeTitle)
                .bold()
            
            Text("Showcase your project and receive feedback from mentors and peers.")
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
        }
        .padding()
        .navigationTitle("Presentation")
        .navigationBarTitleDisplayMode(.inline)
    }
}
