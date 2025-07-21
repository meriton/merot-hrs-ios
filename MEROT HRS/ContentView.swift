//
//  ContentView.swift
//  MEROT HRS
//
//  Created by Meriton Chutra on 7/14/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authService = AuthenticationService()
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                if let currentUser = authService.currentUser {
                    if currentUser.userType == "admin" {
                        AdminDashboardView()
                            .environmentObject(authService)
                    } else {
                        DashboardView()
                            .environmentObject(authService)
                    }
                } else {
                    // Show loading while fetching user profile
                    VStack {
                        ProgressView("Loading...")
                        Text("Getting your profile...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                LoginView()
                    .environmentObject(authService)
            }
        }
        .onAppear {
            Task {
                if authService.isAuthenticated && authService.currentUser == nil {
                    await authService.getProfile()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
