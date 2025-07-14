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
                DashboardView()
                    .environmentObject(authService)
            } else {
                LoginView()
                    .environmentObject(authService)
            }
        }
        .onAppear {
            Task {
                if authService.isAuthenticated {
                    await authService.getProfile()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
