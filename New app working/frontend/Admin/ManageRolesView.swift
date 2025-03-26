//
//  ManageRolesView.swift
//  New app working
//
//  Created by AB on 1/9/25.
//

import SwiftUI

struct ManageRolesView: View {
    @ObservedObject var userManager: CustomUserManager
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack {
                if userManager.pendingInvites.isEmpty {
                    Text("No incoming requests")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List {
                        ForEach(userManager.pendingInvites) { user in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(user.name)
                                    .font(.headline)
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)

                                HStack {
                                    Button(action: {
                                        userManager.acceptInvite(for: user, role: "Student")
                                    }) {
                                        Text("Become Student")
                                            .padding(8)
                                            .frame(maxWidth: .infinity)
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }

                                    Button(action: {
                                        userManager.acceptInvite(for: user, role: "Mentor")
                                    }) {
                                        Text("Become Mentor")
                                            .padding(8)
                                            .frame(maxWidth: .infinity)
                                            .background(Color.green)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }

                                    Button(action: {
                                        userManager.acceptInvite(for: user, role: "Admin")
                                    }) {
                                        Text("Become Admin")
                                            .padding(8)
                                            .frame(maxWidth: .infinity)
                                            .background(Color.orange)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                }

                                Button(action: {
                                    userManager.declineInvite(for: user)
                                }) {
                                    Text("Decline")
                                        .padding(8)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.red)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                                .padding(.top, 5)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }

                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Centered Title
                ToolbarItem(placement: .principal) {
                    Text("Incoming Requests")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .toolbarBackground(Color.customGreen, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

struct ManageRolesView_Previews: PreviewProvider {
    static var previews: some View {
        ManageRolesView(userManager: CustomUserManager())
    }
}
