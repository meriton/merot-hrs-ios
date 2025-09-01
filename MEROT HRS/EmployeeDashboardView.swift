//
//  EmployeeDashboardView.swift
//  MEROT HRS
//
//  Created by Claude on 9/1/25.
//

import SwiftUI

struct EmployeeDashboardView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var selectedTab = 0
    @State private var showingProfile = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            EmployeeHomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            TimeOffView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Time Off")
                }
                .tag(1)
            
            PaystubsView()
                .tabItem {
                    Image(systemName: "doc.text.fill")
                    Text("Paystubs")
                }
                .tag(2)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { showingProfile = true }) {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Sign Out") {
                    Task {
                        await authService.logout()
                    }
                }
                .foregroundColor(.red)
            }
        }
        .sheet(isPresented: $showingProfile) {
            NavigationView {
                EmployeeProfileView()
                    .navigationTitle("Profile")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingProfile = false
                            }
                        }
                    }
            }
        }
    }
}

struct EmployeeHomeView: View {
    @State private var dashboardData: EmployeeDashboardData?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if isLoading {
                        ProgressView("Loading dashboard...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let errorMessage = errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text("Error")
                                .font(.headline)
                            Text(errorMessage)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                            Button("Retry") {
                                Task {
                                    await loadDashboardData()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    } else if let data = dashboardData {
                        // Employee Info Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Welcome, \(data.employee.fullName)")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            if let employment = data.employment {
                                Text(employment.position)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                if let employer = employment.employer {
                                    Text(employer.name)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                        
                        // Quick Stats Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            // Time Off Balance
                            StatCard(
                                title: "Available Time Off",
                                value: "\(data.timeOff.availableDays)",
                                unit: "days",
                                icon: "calendar",
                                color: .green
                            )
                            
                            // Pending Requests
                            StatCard(
                                title: "Pending Requests",
                                value: "\(data.timeOff.pendingRequestsCount)",
                                unit: "requests",
                                icon: "clock.fill",
                                color: .orange
                            )
                        }
                        
                        // Recent Time Off Requests
                        if !data.timeOff.pendingRequests.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recent Time Off Requests")
                                    .font(.headline)
                                
                                ForEach(data.timeOff.pendingRequests.prefix(3)) { request in
                                    TimeOffRequestRow(request: request)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(radius: 2)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .refreshable {
                await loadDashboardData()
            }
        }
        .onAppear {
            Task {
                await loadDashboardData()
            }
        }
    }
    
    private func loadDashboardData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: APIResponse<EmployeeDashboardData> = try await NetworkManager.shared.get(
                endpoint: "/employees/dashboard",
                responseType: APIResponse<EmployeeDashboardData>.self
            )
            
            if response.success {
                dashboardData = response.data
            } else {
                errorMessage = response.message ?? "Failed to load dashboard data"
            }
        } catch {
            errorMessage = "Network error: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// Time Off View placeholder
struct TimeOffView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Time Off Management")
                    .font(.title)
                Text("Coming soon...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Time Off")
        }
    }
}

// Paystubs View placeholder  
struct PaystubsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Paystubs")
                    .font(.title)
                Text("Coming soon...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Paystubs")
        }
    }
}

// Employee Profile View placeholder
struct EmployeeProfileView: View {
    var body: some View {
        VStack {
            Text("Employee Profile")
                .font(.title)
            Text("Coming soon...")
                .foregroundColor(.secondary)
        }
    }
}

// Time Off Request Row
struct TimeOffRequestRow: View {
    let request: EmployeeTimeOffRequest
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(request.timeOffRecord?.name ?? "Time Off")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(request.startDate ?? "") - \(request.endDate ?? "")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(request.approvalStatus.capitalized)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor(for: request.approvalStatus))
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .padding(.vertical, 8)
    }
    
    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "approved":
            return .green
        case "denied":
            return .red
        default:
            return .orange
        }
    }
}

#Preview {
    EmployeeDashboardView()
        .environmentObject(AuthenticationService())
}