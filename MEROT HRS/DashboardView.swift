import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var apiService = APIService()
    @State private var dashboardData: DashboardData?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingProfile = false
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView("Loading dashboard...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let dashboardData = dashboardData {
                        DashboardStatsView(stats: dashboardData.stats)
                        
                        RecentActivitiesView(activities: dashboardData.recentActivities)
                    } else if let errorMessage = errorMessage {
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text("Error loading dashboard")
                                .font(.headline)
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button("Retry") {
                                Task {
                                    await loadDashboard()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingProfile = true
                    }) {
                        Image(systemName: "person.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await authService.logout()
                        }
                    }) {
                        Image(systemName: "power")
                    }
                }
            }
            .refreshable {
                await loadDashboard()
            }
            .sheet(isPresented: $showingProfile) {
                EmployerProfileView()
                    .environmentObject(authService)
            }
            }
            .tabItem {
                Image(systemName: "chart.bar")
                Text("Dashboard")
            }
            .tag(0)
            
            EmployeesView()
                .tabItem {
                    Image(systemName: "person.3")
                    Text("Employees")
                }
                .tag(1)
            
            PendingRequestsView()
                .tabItem {
                    Image(systemName: "clock.badge.exclamationmark")
                    Text("Pending")
                }
                .tag(2)
            
            InvoicesView()
                .tabItem {
                    Image(systemName: "doc.text")
                    Text("Invoices")
                }
                .tag(3)
        }
        .onAppear {
            Task {
                await loadDashboard()
            }
        }
    }
    
    private func loadDashboard() async {
        isLoading = true
        errorMessage = nil
        
        do {
            dashboardData = try await apiService.getDashboard()
        } catch {
            if let networkError = error as? NetworkManager.NetworkError {
                if case .authenticationError = networkError {
                    let refreshed = await authService.refreshToken()
                    if refreshed {
                        await loadDashboard()
                        return
                    }
                }
                errorMessage = networkError.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
    }
}

struct DashboardStatsView: View {
    let stats: DashboardStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "Total Employees",
                    value: "\(stats.totalEmployees)",
                    icon: "person.3",
                    color: .blue
                )
                
                StatCard(
                    title: "Active Employees",
                    value: "\(stats.activeEmployees)",
                    icon: "person.badge.plus",
                    color: .green
                )
                
                StatCard(
                    title: "Pending Requests",
                    value: "\(stats.pendingTimeOffRequests)",
                    icon: "clock.badge.exclamationmark",
                    color: .orange
                )
                
                StatCard(
                    title: "On Leave Today",
                    value: "\(stats.employeesOnLeaveToday)",
                    icon: "calendar.badge.minus",
                    color: .purple
                )
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
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
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct RecentActivitiesView: View {
    let activities: [DashboardActivity]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activities")
                .font(.headline)
            
            if activities.isEmpty {
                Text("No recent activities")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(activities) { activity in
                    ActivityRow(activity: activity)
                }
            }
        }
    }
}

struct ActivityRow: View {
    let activity: DashboardActivity
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.employeeName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(activity.type.replacingOccurrences(of: "_", with: " ").capitalized)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let startDate = activity.startDate, let endDate = activity.endDate {
                    Text("\(startDate) - \(endDate)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                StatusBadge(status: activity.status)
                
                if let days = activity.days {
                    Text("\(days) day\(days == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct StatusBadge: View {
    let status: String
    
    var body: some View {
        Text(status.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(6)
    }
    
    private var backgroundColor: Color {
        switch status.lowercased() {
        case "pending":
            return .orange.opacity(0.2)
        case "approved":
            return .green.opacity(0.2)
        case "denied":
            return .red.opacity(0.2)
        default:
            return .gray.opacity(0.2)
        }
    }
    
    private var foregroundColor: Color {
        switch status.lowercased() {
        case "pending":
            return .orange
        case "approved":
            return .green
        case "denied":
            return .red
        default:
            return .gray
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let user = authService.currentUser {
                    VStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text(user.email)
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        if let employer = user.employer {
                            Text(employer.name ?? "Unknown Company")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Button("Sign Out") {
                    Task {
                        await authService.logout()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}