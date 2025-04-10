//
//  AddUserView.swift
//  New app working
//
//  Created by AB on 1/9/25.
//

import SwiftUI


struct AddUserView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var userManager: CustomUserManager

    @State private var name: String = ""
    @State private var phoneNumber: String = ""
    @State private var email: String = ""
    @State private var monitorName: String = ""
    @State private var selectedRole: String = "Pending"
    @State private var selectedClassType: String = "Regular Class"
    @State private var selectedTimeSlot: String = "AM"
    @State private var vacationStartDate: Date = Date()
    @State private var vacationEndDate: Date = Date()
    @State private var generatedClassCode: String = ""
    @State private var eventTitle: String = ""
    @State private var eventDescription: String = ""
    @State private var uploadedImage: Image? = nil
    @State private var isImageUploaderPresented: Bool = false
    @State private var isVacationSheetPresented: Bool = false
    
    // New notification states
    @State private var notificationTitle: String = ""
    @State private var notificationMessage: String = ""
    @State private var selectedRecipient: AdminNotificationItem.NotificationRecipient = .allUsers
    @State private var specificUser: String = ""
    @State private var selectedGroup: String = ""
    @State private var isScheduled: Bool = false
    @State private var scheduledDate: Date = Date()

    let classTypes = ["Regular Class", "Renaissance Class"]
    let timeSlots = ["AM", "PM"]
    let roleOptions = ["Pending", "Student", "Mentor", "Admin"]
    
    // List of user groups for notifications
    let userGroups = ["Mentors", "Students", "Admins"]

    var body: some View {
        NavigationView {
            Form {
                // MARK: - User Information Section
                Section {
                    TextField("Full Name", text: $name)
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                    TextField("Email Address", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Monitor Name", text: $monitorName)

                    Picker("Select Role", selection: $selectedRole) {
                        ForEach(roleOptions, id: \.self) { role in
                            Text(role)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    Button(action: {
                        let newUser = AppUser1(
                            name: name,
                            status: "Pending Invitation",
                            role: selectedRole,
                            phoneNumber: phoneNumber.isEmpty ? "N/A" : phoneNumber,
                            email: email,
                            monitorName: monitorName.isEmpty ? "Unassigned" : monitorName
                        )
                        userManager.allUsers.append(newUser)
                        sendEmailInvite(to: email, name: name)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Send Invite")
                        }
                        .foregroundColor(.blue)
                    }
                    .disabled(name.isEmpty || email.isEmpty)
                } header: {
                    Text("User Information")
                }

                // MARK: - Class Selection
                Section {
                    Picker("Select Class Type", selection: $selectedClassType) {
                        ForEach(classTypes, id: \.self) { classType in
                            Text(classType)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    Picker("Select Time Slot", selection: $selectedTimeSlot) {
                        ForEach(timeSlots, id: \.self) { slot in
                            Text(slot)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                } header: {
                    Text("Class Type & Time Slot")
                }

                // MARK: - Class Code Generation
                Section {
                    if !generatedClassCode.isEmpty {
                        Text("Generated Code: \(generatedClassCode)")
                            .foregroundColor(.blue)
                    }

                    Button(action: {
                        generatedClassCode = generateClassCode()
                    }) {
                        HStack {
                            Image(systemName: "number")
                            Text("Generate Class Code")
                        }
                        .foregroundColor(.purple)
                    }
                } header: {
                    Text("Generate Class Code")
                }

                // MARK: - Vacation Days
                Section {
                    Button {
                        isVacationSheetPresented.toggle()
                    } label: {
                        HStack {
                            Image(systemName: "calendar.badge.plus")
                            Text("Apply Vacation Days")
                        }
                        .foregroundColor(.green)
                    }
                } header: {
                    Text("Declare Vacation Days")
                }
                .sheet(isPresented: $isVacationSheetPresented) {
                    VacationDaysSheet(vacationStartDate: $vacationStartDate, vacationEndDate: $vacationEndDate, userManager: userManager)
                }

                // MARK: - Add Event
                Section {
                    TextField("Event Title", text: $eventTitle)

                    TextEditor(text: $eventDescription)
                        .frame(height: 150)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .padding(.vertical, 5)

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

                    Button(action: {
                        publishEvent(title: eventTitle, description: eventDescription, image: uploadedImage)
                        eventTitle = ""
                        eventDescription = ""
                        uploadedImage = nil
                    }) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Publish Event")
                        }
                        .foregroundColor(.blue)
                    }
                    .disabled(eventTitle.isEmpty || eventDescription.isEmpty || uploadedImage == nil)
                } header: {
                    Text("Add Event")
                }
                
                // MARK: - Add Notification Section (New)
                Section {
                    TextField("Notification Title", text: $notificationTitle)
                    
                    TextEditor(text: $notificationMessage)
                        .frame(height: 150)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    
                    // Recipient Selection
                    Menu {
                        Button(action: {
                            selectedRecipient = .allUsers
                        }) {
                            Text("All Users")
                            Image(systemName: "person.3.fill")
                        }
                        
                        Button(action: {
                            selectedRecipient = .students
                        }) {
                            Text("All Students")
                            Image(systemName: "graduationcap.fill")
                        }
                        
                        Button(action: {
                            selectedRecipient = .mentors
                        }) {
                            Text("All Mentors")
                            Image(systemName: "person.2.fill")
                        }
                        
                        Button(action: {
                            selectedRecipient = .admins
                        }) {
                            Text("All Admins")
                            Image(systemName: "shield.fill")
                        }
                        
                        Button(action: {
                            selectedRecipient = .userGroup("")
                        }) {
                            Text("User Group")
                            Image(systemName: "rectangles.group.fill")
                        }
                        
                        Button(action: {
                            selectedRecipient = .specificUser("")
                        }) {
                            Text("Specific User")
                            Image(systemName: "person.fill")
                        }
                    } label: {
                        HStack {
                            Text("Send To:")
                            Spacer()
                            Text(recipientLabel(for: selectedRecipient))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Conditional fields based on recipient selection
                    switch selectedRecipient {
                    case .userGroup:
                        HStack {
                            Text("Select Group")
                            Spacer()
                            Picker("Group", selection: $selectedGroup) {
                                ForEach(userGroups, id: \.self) { group in
                                    Text(group).tag(group)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(MenuPickerStyle())
                        }
                    case .specificUser:
                        HStack {
                            Text("User Name")
                            Spacer()
                            TextField("Enter Name", text: $specificUser)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.secondary)
                        }
                    default:
                        EmptyView()
                    }
                    
                    // Scheduling section
                    Toggle("Schedule Notification", isOn: $isScheduled)
                    
                    if isScheduled {
                        DatePicker("Send Date", selection: $scheduledDate, in: Date()...)
                            .datePickerStyle(CompactDatePickerStyle())
                    }
                    
                    // Send Notification Button
                    Button(action: sendNotification) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text(isScheduled ? "Schedule Notification" : "Send Notification")
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .disabled(notificationTitle.isEmpty || notificationMessage.isEmpty)
                } header: {
                    Text("Send Notification")
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Centered Title
                ToolbarItem(placement: .principal) {
                    Text("Add User")
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

    // MARK: - Mock Email Invite Function
    func sendEmailInvite(to email: String, name: String) {
        print("Sending invite to \(email) for \(name) to join cohort.")
    }

    // MARK: - Generate Class Code
    func generateClassCode() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<8).map { _ in letters.randomElement()! })
    }

    // MARK: - Publish Event
    func publishEvent(title: String, description: String, image: Image?) {
        print("Publishing event: \(title) - \(description)")
        if let _ = image {
            print("With image attached")
        }
    }
    
    // MARK: - Helper method to get a label for the selected recipient
    private func recipientLabel(for recipient: AdminNotificationItem.NotificationRecipient) -> String {
        switch recipient {
        case .allUsers:
            return "All Users"
        case .students:
            return "All Students"
        case .mentors:
            return "All Mentors"
        case .admins:
            return "All Admins"
        case .userGroup(let group):
            return group.isEmpty ? "User Group" : group
        case .specificUser(let name):
            return name.isEmpty ? "Specific User" : name
        }
    }
    
    // MARK: - Send Notification Function
    private func sendNotification() {
        // Determine recipient based on selection
        let finalRecipient: AdminNotificationItem.NotificationRecipient
        switch selectedRecipient {
        case .userGroup:
            finalRecipient = .userGroup(selectedGroup)
        case .specificUser:
            finalRecipient = .specificUser(specificUser)
        default:
            finalRecipient = selectedRecipient
        }
        
        // Determine notification status
        let status: AdminNotificationItem.NotificationStatus = isScheduled ? .scheduled : .sent
        
        // Create notification item
        let newNotification = AdminNotificationItem(
            title: notificationTitle,
            message: notificationMessage,
            recipient: finalRecipient,
            date: isScheduled ? scheduledDate : Date(),
            status: status
        )
        
        // In a real app, this would be sent to a backend or notification service
        print("Created notification: \(newNotification)")
        
        // Reset fields after sending
        notificationTitle = ""
        notificationMessage = ""
        selectedRecipient = .allUsers
        specificUser = ""
        selectedGroup = ""
        isScheduled = false
        scheduledDate = Date()
    }
}

// MARK: - ImageUploaderView
struct ImageUploaderView: View {
    @Binding var selectedImage: Image?
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            Text("Image Uploader")
                .font(.headline)

            Button("Select Image") {
                // Implement image selection functionality
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
