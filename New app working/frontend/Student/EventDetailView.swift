//
//  EventDetailView.swift
//  New app working
//
//  Created by AB on 1/9/25.
//

import SwiftUI

struct EventDetailView: View {
    let event: Event

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // White card with custom green outline
                VStack(spacing: 15) {
                    
                    // Placeholder Image for the event
                    Image("eventPlaceholder") // Replace with an actual image asset if available
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .overlay(
                            Text("Event Image")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.customGreen.opacity(0.7))
                                .cornerRadius(8),
                            alignment: .center
                        )
                    
                    // Event Title (using custom green) and Subtitle
                    Text(event.title)
                        .font(.title)
                        .bold()
                        .foregroundColor(Color.customGreen)
                    
                    Text(event.subtitle)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    // Date and Day information
                    HStack {
                        Text("Date:")
                            .font(.body)
                            .bold()
                            .foregroundColor(Color.customGreen)
                        Spacer()
                        Text(event.date)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    
                    HStack {
                        Text("Day:")
                            .font(.body)
                            .bold()
                            .foregroundColor(Color.customGreen)
                        Spacer()
                        Text(event.day)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    
                    // Description Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Description")
                            .font(.headline)
                            .foregroundColor(Color.customGreen)
                        Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed euismod, nunc a elementum facilisis, arcu urna tempor dolor, non ultricies velit nulla a odio. Nulla facilisi. Cras et velit sed nisl bibendum varius.")
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.customGreen, lineWidth: 1)
                )
                .shadow(color: Color.customGreen.opacity(0.1), radius: 5, x: 0, y: 2)
                
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground)) // Adapts to Light & Dark Mode
        }
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EventDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EventDetailView(event: Event.sampleData.first!)
        }
        .preferredColorScheme(.dark)
        
        NavigationView {
            EventDetailView(event: Event.sampleData.first!)
        }
        .preferredColorScheme(.light)
    }
}
