//
//  CloudKitAppExtension.swift
//  New app working
//
//  Created by AB on 3/26/25.
//

import SwiftUI

// MARK: - CloudKit Extension for New_app_workingApp
extension New_app_workingApp {
    /// Configure CloudKit during app startup
    func configureCloudKit() {
        // Start asynchronous initialization
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
                Text("Please sign in to iCloud in Settings to use this app.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button("Retry") {
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
