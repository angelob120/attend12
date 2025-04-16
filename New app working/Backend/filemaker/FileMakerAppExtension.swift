//
//  FileMakerAppExtension.swift
//  New app working
//
//  Created by AB on 4/16/25.
//

import SwiftUI

// MARK: - FileMaker Extension for New_app_workingApp
extension New_app_workingApp {
    /// Configure FileMaker during app startup
    func configureFileMaker() {
        // Start asynchronous initialization without requiring FileMaker connection
        Task {
            await FileMakerAppConfig.shared.initializeApp()
        }
    }
}

// MARK: - Loading View for FileMaker Initialization
struct FileMakerLoadingView: View {
    @EnvironmentObject var fileMakerConfig: FileMakerAppConfig
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(2)
                .padding()
            
            Text("Setting up your app...")
                .font(.headline)
            
            if !fileMakerConfig.isFileMakerAvailable {
                // This is now a fallback message, but with the modified code,
                // isFileMakerAvailable should always be true
                Text("Continuing in offline mode...")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Button("Continue") {
                    Task {
                        await fileMakerConfig.initializeApp()
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
