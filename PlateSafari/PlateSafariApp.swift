//
//  PlateSafariApp.swift
//  PlateSafari
//
//  Created by Thomas Raia on 6/13/25.
//

import SwiftUI

@main
struct PlateSafariApp: App {
    // Core services for the entire app
    @StateObject private var plateDataService = PlateDataService()
    @StateObject private var gameManager = GameManagerService()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(plateDataService)
                .environmentObject(gameManager)
                .onAppear {
                    // Load plate data when app launches
                    plateDataService.loadPlateData()
                }
        }
    }
}
