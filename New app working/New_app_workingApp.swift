//
//  New_app_workingApp.swift
//  New app working
//
//  Created by AB on 1/9/25.
//

import SwiftUI
import SwiftData
import CloudKit

@main
struct New_app_workingApp: App {
    @StateObject private var cloudKitConfig = CloudKitAppConfig.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            // Attempt to create the container
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("Error creating ModelContainer: \(error)")
            // Fallback to in-memory container if setup fails
            return try! ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        }
    }()

    var body: some Scene {
        WindowGroup {
            // If CloudKit is ready, show the main content view
            Group {
                if cloudKitConfig.isCloudKitAvailable {
                    ContentView()
                } else {
                    // Show a view explaining iCloud setup is needed
                    VStack {
                        Text("iCloud Setup Required")
                            .font(.title)
                        Text("Please sign in to iCloud in your device settings to use all app features.")
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Retry") {
                            Task {
                                await cloudKitConfig.initializeApp()
                            }
                        }
                    }
                }
            }
            .environmentObject(cloudKitConfig)
            .task {
                // Configure CloudKit on app startup
                await cloudKitConfig.initializeApp()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
