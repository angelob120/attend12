//
//  CloudKitAppExtension.swift
//  New app working
//
//  Created by AB on 3/26/25.
//  Modified to work without iCloud

import SwiftUI

// MARK: - CloudKit Extension for New_app_workingApp
extension New_app_workingApp {
    /// Configure CloudKit during app startup
    func configureCloudKit() {
        // Start asynchronous initialization without requiring iCloud
        Task {
            await CloudKitAppConfig.shared.initializeApp()
        }
    }
}

// MARK: - Loading View for CloudKit Initialization
struct LoadingView: View {
    @EnvironmentObject var cloudKitConfig: CloudKitAppConfig
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(2)
                .padding()
            
            Text("Setting up your app...")
                .font(.headline)
            
            if !cloudKitConfig.isCloudKitAvailable {
                // This is now a fallback message, but with the modified code,
                // isCloudKitAvailable should always be true
                Text("Continuing in offline mode...")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button("Continue") {
                    Task {
                        await cloudKitConfig.initializeApp()
                    }
                }
                .padding()
                .background(Color.customGreen)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
