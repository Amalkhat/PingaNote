//
//  PingaNoteApp.swift
//  PingaNote
//
//  Created by Malek Alkhatib on 2024-10-22.
//

import SwiftUI

@main
struct PingaNoteApp: App {
    // Initialize HomeViewModel with injected dependencies if necessary
    @StateObject private var homeViewModel = HomeViewModel()
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(homeViewModel) // Inject HomeViewModel into the environment
        }
    }
}
