//
//  ContentView.swift
//  PlateSpy
//
//  Created by Thomas Raia on 6/13/25.
//

import SwiftUI

/**
 * Legacy ContentView - now redirects to MainTabView
 * Kept for compatibility with existing project structure
 */
struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .environmentObject(PlateDataService())
        .environmentObject(GameManagerService())
}
