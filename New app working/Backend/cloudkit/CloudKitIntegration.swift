//
//  CloudKitIntegration.swift
//  New app working
//
//  Created by AB on 3/26/25.
//

import SwiftUI
import CloudKit
import Combine

// MARK: - Simple CloudKit Helper
class CloudKitHelper {
    // Static method for initializing CloudKit
    static func initialize() {
        // Start asynchronous initialization
        Task {
            await CloudKitAppConfig.shared.initializeApp()
        }
    }
    
    // Static reference to the CloudKit configuration
    static var config: CloudKitAppConfig {
        return CloudKitAppConfig.shared
    }
}

// MARK: - CloudKit Loading View
struct CloudKitLoadingView: View {
    @ObservedObject var config = CloudKitAppConfig.shared
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(2)
                .padding()
            
            Text("Setting up your app...")
                .font(.headline)
            
            if !config.isCloudKitAvailable {
                Text("Please sign in to iCloud in Settings to use this app.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button("Retry") {
                    Task {
                        await config.initializeApp()
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

// MARK: - App Entry Point Extension
extension New_app_workingApp {
    // Helper method for app initialization with CloudKit
    func setupCloudKit() {
        CloudKitHelper.initialize()
    }
}
