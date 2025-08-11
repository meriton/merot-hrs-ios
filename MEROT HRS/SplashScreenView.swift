//
//  SplashScreenView.swift
//  MEROT HRS
//
//  Created by Claude on 8/5/25.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var logoOpacity: Double = 0.0
    @State private var showMainContent = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        if showMainContent {
            MainContentView()
        } else {
            ZStack {
                // Background - dark in dark mode, gradient in light mode
                if colorScheme == .dark {
                    Color.black
                        .ignoresSafeArea()
                } else {
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.white]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                }
                
                // Logo - same as login screen but 35% smaller
                Image("MerotLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 78) // 120 * 0.65 = 78
                    .padding(10) // 16 * 0.65 ≈ 10
                    .background(Color.white)
                    .cornerRadius(13) // 20 * 0.65 = 13
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    .opacity(logoOpacity)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    logoOpacity = 1.0
                }
                
                // Automatically transition to main content after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showMainContent = true
                    }
                }
            }
        }
    }
}

struct MainContentView: View {
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
    SplashScreenView()
}