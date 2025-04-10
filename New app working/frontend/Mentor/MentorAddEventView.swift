//
//  MentorAddEventView.swift
//  New app working
//
//  Created by AB on 4/10/25.
//

import SwiftUI

struct MentorAddEventView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var eventTitle: String = ""
    @State private var eventDescription: String = ""
    @State private var eventDate: Date = Date()
    @State private var uploadedImage: Image? = nil
    @State private var isImageUploaderPresented: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                // Event Title Section
                Section {
                    TextField("Event Title", text: $eventTitle)
                    
                    TextEditor(text: $eventDescription)
                        .frame(height: 150)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .padding(.vertical, 5)
                } header: {
                    Text("Event Details")
                }
                
                // Date Selection Section
                Section {
                    DatePicker("Event Date", selection: $eventDate, displayedComponents: .date)
                } header: {
                    Text("Date")
                }
                
                // Image Upload Section
                Section {
                    if let uploadedImage = uploadedImage {
                        uploadedImage
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                            .cornerRadius(8)
                            .padding(.vertical, 5)
                    }
                    
                    Button(action: {
                        isImageUploaderPresented = true
                    }) {
                        HStack {
                            Image(systemName: "photo")
                            Text("Upload Image")
                        }
                        .foregroundColor(.blue)
                    }
                    .sheet(isPresented: $isImageUploaderPresented) {
                        ImageUploaderView(selectedImage: $uploadedImage)
                    }
                } header: {
                    Text("Event Image")
                }
                
                // Publish Button Section
                Section {
                    Button(action: publishEvent) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Publish Event")
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .disabled(eventTitle.isEmpty || eventDescription.isEmpty || uploadedImage == nil)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Centered Title
                ToolbarItem(placement: .principal) {
                    Text("Add Event")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                // Trailing Cancel Button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Color.iconColor)
                }
            }
            .toolbarBackground(Color.customGreen, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    // MARK: - Publish Event Function
    private func publishEvent() {
        // Format the date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM:d"
        let formattedDate = dateFormatter.string(from: eventDate)
        
        dateFormatter.dateFormat = "EEE"
        let dayAbbreviation = dateFormatter.string(from: eventDate).uppercased()
        
        // Create an event (this would typically involve saving to a backend)
        let newEvent = Event(
            date: formattedDate,
            day: dayAbbreviation,
            title: eventTitle,
            subtitle: eventDescription,
            isHighlighted: false,
            detailView: AnyView(EventDetailView(event: Event(
                date: formattedDate,
                day: dayAbbreviation,
                title: eventTitle,
                subtitle: eventDescription,
                isHighlighted: false,
                detailView: AnyView(Text("Event Detail Placeholder"))
            )))
        )
        
        // In a real app, you would save this to a backend or state management system
        print("Publishing event: \(eventTitle)")
        
        // Reset form and dismiss
        presentationMode.wrappedValue.dismiss()
    }
}

// Reuse the ImageUploaderView from AddUserView
struct ImageUploaderView1: View {
    @Binding var selectedImage: Image?
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            Text("Image Uploader")
                .font(.headline)

            Button("Select Image") {
                // Implement image selection functionality
                // For now, just set a placeholder image
                selectedImage = Image(systemName: "photo")
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)

            Spacer()

            Button("Done") {
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
        }
    }
}

// Preview
struct MentorAddEventView_Previews: PreviewProvider {
    static var previews: some View {
        MentorAddEventView()
    }
}
