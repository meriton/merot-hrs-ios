import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var apiService = APIService()
    @State private var dashboardData: DashboardData?
    @State private var employerProfile: EmployerProfileData?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingProfile = false
    @State private var selectedTab = 0
    @State private var employeeFilter: String? = nil
    @State private var selectedInvoice: Invoice? = nil
    @State private var selectedEmployee: Employee? = nil
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        if horizontalSizeClass == .regular {
            // iPad layout - sidebar navigation
            NavigationSplitView(columnVisibility: .constant(.all)) {
                // Sidebar
                List {
                    Section("Overview") {
                        Button(action: { 
                            clearDetailSelections()
                            selectedTab = 0 
                        }) {
                            Label("Dashboard", systemImage: "chart.bar")
                                .foregroundColor(selectedTab == 0 ? .accentColor : .primary)
                        }
                    }
                    
                    Section("Team") {
                        Button(action: { 
                            clearDetailSelections()
                            selectedTab = 1 
                        }) {
                            Label("Employees", systemImage: "person.3")
                                .foregroundColor(selectedTab == 1 ? .accentColor : .primary)
                        }
                        Button(action: { 
                            clearDetailSelections()
                            selectedTab = 2 
                        }) {
                            Label("Pending Requests", systemImage: "clock.badge.exclamationmark")
                                .foregroundColor(selectedTab == 2 ? .accentColor : .primary)
                        }
                    }
                    
                    Section("Finance") {
                        Button(action: { 
                            clearDetailSelections()
                            selectedTab = 3 
                        }) {
                            Label("Invoices", systemImage: "doc.text")
                                .foregroundColor(selectedTab == 3 ? .accentColor : .primary)
                        }
                    }
                    
                    Section("Calendar") {
                        Button(action: { 
                            clearDetailSelections()
                            selectedTab = 4 
                        }) {
                            Label("Holidays", systemImage: "calendar.badge.clock")
                                .foregroundColor(selectedTab == 4 ? .accentColor : .primary)
                        }
                    }
                    
                    Section("Account") {
                        Button(action: {
                            showingProfile = true
                        }) {
                            Label("Profile", systemImage: "person.circle")
                                .foregroundColor(.primary)
                        }
                        
                        Button(action: {
                            Task {
                                await authService.logout()
                            }
                        }) {
                            Label("Sign Out", systemImage: "power")
                                .foregroundColor(.red)
                        }
                    }
                }
                .navigationTitle(employerProfile?.employer.name ?? "MEROT HRS")
                .navigationBarTitleDisplayMode(.large)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
            } content: {
                // Content view (middle column - wider for lists)
                Group {
                    switch selectedTab {
                    case 0:
                        DashboardContentView(
                            dashboardData: dashboardData,
                            isLoading: isLoading,
                            errorMessage: errorMessage,
                            selectedTab: $selectedTab,
                            employeeFilter: $employeeFilter,
                            loadDashboard: loadDashboard
                        )
                    case 1:
                        EmployeesView(filterFromDashboard: $employeeFilter, selectedEmployee: $selectedEmployee)
                    case 2:
                        PendingRequestsView()
                    case 3:
                        InvoicesView(selectedInvoice: $selectedInvoice, selectedEmployee: $selectedEmployee)
                    case 4:
                        HolidaysView()
                    default:
                        DashboardContentView(
                            dashboardData: dashboardData,
                            isLoading: isLoading,
                            errorMessage: errorMessage,
                            selectedTab: $selectedTab,
                            employeeFilter: $employeeFilter,
                            loadDashboard: loadDashboard
                        )
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationSplitViewColumnWidth(min: 280, ideal: 380, max: 480)
            } detail: {
                // Detail view (right panel for invoice/employee details)
                Group {
                    if let invoice = selectedInvoice {
                        InvoiceDetailView(invoice: invoice, showInDetailPane: true)
                    } else if let employee = selectedEmployee {
                        EmployeeDetailView(employee: employee, showInDetailPane: true)
                    } else {
                        VStack(spacing: 20) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("Select an item to view details")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(.systemGray6))
                    }
                }
                .navigationSplitViewColumnWidth(min: 350, ideal: 450, max: 600)
            }
            .sheet(isPresented: $showingProfile) {
                EmployerProfileView()
                    .environmentObject(authService)
            }
            .onAppear {
                Task {
                    await loadDashboard()
                    loadEmployerProfile()
                }
            }
        } else {
            // iPhone layout - tab view
            TabView(selection: $selectedTab) {
                NavigationView {
                    DashboardContentView(
                        dashboardData: dashboardData,
                        isLoading: isLoading,
                        errorMessage: errorMessage,
                        selectedTab: $selectedTab,
                        employeeFilter: $employeeFilter,
                        loadDashboard: loadDashboard
                    )
                    .navigationTitle(employerProfile?.employer.name ?? "Dashboard")
                    .navigationBarTitleDisplayMode(.large)
                }
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Dashboard")
                }
                .tag(0)
                
                EmployeesView(filterFromDashboard: $employeeFilter)
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
                
                HolidaysView()
                    .tabItem {
                        Image(systemName: "calendar.badge.clock")
                        Text("Holidays")
                    }
                    .tag(4)
            }
            .sheet(isPresented: $showingProfile) {
                EmployerProfileView()
                    .environmentObject(authService)
            }
            .onAppear {
                Task {
                    await loadDashboard()
                    loadEmployerProfile()
                }
            }
            .onChange(of: selectedTab) { newTab in
                // Clear detail selections when switching tabs
                selectedInvoice = nil
                selectedEmployee = nil
                
                // Refresh dashboard data when returning to dashboard tab
                if newTab == 0 {
                    Task {
                        await loadDashboard()
                    }
                }
            }
        }
    }
    
    private func clearDetailSelections() {
        selectedInvoice = nil
        selectedEmployee = nil
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
    
    private func loadEmployerProfile() {
        APIService.shared.fetchEmployerProfile { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let profile):
                    self.employerProfile = profile
                case .failure(let error):
                    print("Failed to load employer profile: \(error)")
                }
            }
        }
    }
}

struct DashboardStatsView: View {
    let stats: DashboardStats
    @Binding var selectedTab: Int
    @Binding var employeeFilter: String?
    
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
                ) {
                    employeeFilter = "all"
                    selectedTab = 1 // Navigate to Employees tab
                }
                
                StatCard(
                    title: "Active Employees",
                    value: "\(stats.activeEmployees ?? 0)",
                    icon: "person.badge.plus",
                    color: .green
                ) {
                    employeeFilter = "active"
                    selectedTab = 1 // Navigate to Employees tab with active filter
                }
                
                StatCard(
                    title: "Pending Requests",
                    value: "\(stats.pendingTimeOffRequests ?? 0)",
                    icon: "clock.badge.exclamationmark",
                    color: .orange
                ) {
                    selectedTab = 2 // Navigate to Pending tab
                }
                
                StatCard(
                    title: "On Leave Today",
                    value: "\(stats.employeesOnLeaveToday ?? 0)",
                    icon: "calendar.badge.minus",
                    color: .purple
                ) {
                    employeeFilter = "all"
                    selectedTab = 1 // Navigate to Employees tab
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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
        .buttonStyle(PlainButtonStyle())
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
                Text(activity.employeeName ?? "Unknown Employee")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(activity.type.replacingOccurrences(of: "_", with: " ").capitalized)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let startDate = activity.startDate, let endDate = activity.endDate {
                    Text("\(formatDateObject(startDate)) - \(formatDateObject(endDate))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                StatusBadge(status: activity.status ?? "pending")
                
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
    
    private func formatDate(_ dateString: String) -> String {
        let formatters = [
            "yyyy-MM-dd'T'HH:mm:ssZ",      // ISO 8601 with timezone
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",  // ISO 8601 with milliseconds
            "yyyy-MM-dd'T'HH:mm:ss",       // ISO 8601 without timezone
            "yyyy-MM-dd"                   // Date only
        ]
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            
            if let date = formatter.date(from: dateString) {
                let displayFormatter = DateFormatter()
                displayFormatter.dateFormat = "MMM d, yyyy"
                return displayFormatter.string(from: date)
            }
        }
        
        return dateString
    }
    
    private func formatDateObject(_ date: Date) -> String {
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM d, yyyy"
        return displayFormatter.string(from: date)
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
        case "active":
            return .green.opacity(0.2)
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
        case "active":
            return .green
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