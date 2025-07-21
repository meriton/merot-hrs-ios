import SwiftUI

struct AdminDashboardView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Admin Dashboard Tab
            AdminHomeView()
                .environmentObject(authService)
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Dashboard")
                }
                .tag(0)
            
            // Hiring Tab - This is the new tab for job postings
            HiringView()
                .tabItem {
                    Image(systemName: "briefcase")
                    Text("Hiring")
                }
                .tag(1)
            
            // Employers Tab
            AdminEmployersView()
                .tabItem {
                    Image(systemName: "building.2")
                    Text("Employers")
                }
                .tag(2)
            
            // Employees Tab
            AdminEmployeesView()
                .tabItem {
                    Image(systemName: "person.3")
                    Text("Employees")
                }
                .tag(3)
            
            // Settings Tab
            AdminSettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(4)
        }
    }
}

// Placeholder views for admin functionality
struct AdminHomeView: View {
    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var apiService = APIService()
    @State private var dashboardData: AdminDashboardData?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView("Loading dashboard...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let errorMessage = errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            
                            Text("Error Loading Dashboard")
                                .font(.headline)
                            
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            Button("Retry") {
                                Task {
                                    await loadAdminDashboard()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    } else if let dashboardData = dashboardData {
                        AdminDashboardStatsView(stats: dashboardData.stats)
                        
                        RecentEmployersView(employers: dashboardData.recentEmployers)
                        
                        SystemAlertsView(alerts: dashboardData.systemAlerts)
                    }
                }
                .padding()
            }
            .navigationTitle("Admin Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await loadAdminDashboard()
            }
            .toolbar {
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
        }
        .onAppear {
            Task {
                await loadAdminDashboard()
            }
        }
    }
    
    private func loadAdminDashboard() async {
        isLoading = true
        errorMessage = nil
        
        do {
            dashboardData = try await apiService.getAdminDashboard()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

struct AdminDashboardStatsView: View {
    let stats: AdminStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                AdminStatCard(
                    title: "Total Employers",
                    value: "\(stats.totalEmployers)",
                    icon: "building.2",
                    color: .blue
                )
                
                AdminStatCard(
                    title: "Active Employees",
                    value: "\(stats.activeEmployees)",
                    icon: "person.3",
                    color: .green
                )
                
                AdminStatCard(
                    title: "Active Invoices",
                    value: "\(stats.activeInvoices ?? 0)",
                    icon: "doc.text",
                    color: .purple
                )
                
                AdminStatCard(
                    title: "Monthly Revenue",
                    value: "$\(String(format: "%.0f", stats.monthlyRevenue ?? 0))",
                    icon: "dollarsign.circle",
                    color: .green
                )
            }
        }
    }
}

struct AdminStatCard: View {
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

struct RecentEmployersView: View {
    let employers: [RecentEmployer]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Employers")
                .font(.headline)
            
            if employers.isEmpty {
                Text("No recent employer registrations")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(employers) { employer in
                    RecentEmployerRow(employer: employer)
                }
            }
        }
    }
}

struct RecentEmployerRow: View {
    let employer: RecentEmployer
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(employer.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(employer.employeeCount) employees")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Registered \(employer.createdAt, style: .date)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            StatusBadge(status: employer.status)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct SystemAlertsView: View {
    let alerts: [SystemAlert]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("System Alerts")
                .font(.headline)
            
            if alerts.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                    Text("All systems operational")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            } else {
                ForEach(alerts) { alert in
                    SystemAlertRow(alert: alert)
                }
            }
        }
    }
}

struct SystemAlertRow: View {
    let alert: SystemAlert
    
    var alertColor: Color {
        switch alert.type {
        case "warning":
            return .orange
        case "error":
            return .red
        case "info":
            return .blue
        default:
            return .gray
        }
    }
    
    var alertIcon: String {
        switch alert.type {
        case "warning":
            return "exclamationmark.triangle"
        case "error":
            return "xmark.circle"
        case "info":
            return "info.circle"
        default:
            return "bell"
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: alertIcon)
                .foregroundColor(alertColor)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(alert.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(alertColor.opacity(0.1))
        .cornerRadius(8)
    }
}

struct AdminEmployersView: View {
    @StateObject private var apiService = APIService()
    @State private var employers: [Employer] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var currentPage = 1
    @State private var hasMorePages = true
    @State private var selectedEmployer: Employer?
    
    var filteredEmployers: [Employer] {
        if searchText.isEmpty {
            return employers
        } else {
            return employers.filter { employer in
                employer.name?.localizedCaseInsensitiveContains(searchText) == true ||
                employer.primaryEmail?.localizedCaseInsensitiveContains(searchText) == true ||
                employer.contactEmail?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search employers", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top)
                
                if isLoading && employers.isEmpty {
                    Spacer()
                    ProgressView("Loading employers...")
                    Spacer()
                } else if let errorMessage = errorMessage {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        
                        Text("Error")
                            .font(.headline)
                        
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Retry") {
                            Task {
                                await loadEmployers(reset: true)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    Spacer()
                } else if filteredEmployers.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "building.2")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No employers found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        if !searchText.isEmpty {
                            Text("Try adjusting your search")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredEmployers) { employer in
                            EmployerRow(employer: employer) {
                                selectedEmployer = employer
                            }
                        }
                        
                        if hasMorePages && searchText.isEmpty {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .onAppear {
                                Task {
                                    await loadEmployers(reset: false)
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Employers")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await loadEmployers(reset: true)
            }
        }
        .onAppear {
            if employers.isEmpty {
                Task {
                    await loadEmployers(reset: true)
                }
            }
        }
        .sheet(item: $selectedEmployer) { employer in
            EmployerDetailView(employer: employer)
        }
    }
    
    private func loadEmployers(reset: Bool) async {
        if reset {
            currentPage = 1
            hasMorePages = true
            employers.removeAll()
        }
        
        if !hasMorePages { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.getAllEmployers(
                page: currentPage,
                search: searchText.isEmpty ? nil : searchText
            )
            
            if reset {
                employers = response.employers
            } else {
                employers.append(contentsOf: response.employers)
            }
            
            hasMorePages = response.pagination.currentPage < response.pagination.totalPages
            currentPage += 1
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

struct EmployerRow: View {
    let employer: Employer
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(employer.name ?? "Unnamed Employer")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        if let email = employer.primaryEmail {
                            Text(email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("ID: \(employer.id ?? 0)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let createdAt = employer.createdAt {
                            Text("Created \(createdAt, style: .date)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if let legalName = employer.legalName, legalName != employer.name {
                    HStack {
                        Image(systemName: "building")
                            .foregroundColor(.secondary)
                        Text("Legal: \(legalName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

struct EmployerDetailView: View {
    let employer: Employer
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(employer.name ?? "Unnamed Employer")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        if let email = employer.primaryEmail {
                            Label(email, systemImage: "envelope")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .font(.headline)
                        
                        DetailRow(label: "Employer ID", value: "\(employer.id ?? 0)")
                        
                        if let createdAt = employer.createdAt {
                            DetailRow(label: "Created", value: createdAt.formatted(date: .abbreviated, time: .shortened))
                        }
                        
                        if let updatedAt = employer.updatedAt {
                            DetailRow(label: "Last Updated", value: updatedAt.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Employer Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AdminEmployeesView: View {
    @StateObject private var apiService = APIService()
    @State private var employees: [Employee] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var currentPage = 1
    @State private var hasMorePages = true
    @State private var selectedEmployee: Employee?
    
    var filteredEmployees: [Employee] {
        if searchText.isEmpty {
            return employees
        } else {
            return employees.filter { employee in
                employee.firstName?.localizedCaseInsensitiveContains(searchText) == true ||
                employee.lastName?.localizedCaseInsensitiveContains(searchText) == true ||
                employee.email.localizedCaseInsensitiveContains(searchText) ||
                employee.fullName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search employees", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top)
                
                if isLoading && employees.isEmpty {
                    Spacer()
                    ProgressView("Loading employees...")
                    Spacer()
                } else if let errorMessage = errorMessage {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        
                        Text("Error")
                            .font(.headline)
                        
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Retry") {
                            Task {
                                await loadEmployees(reset: true)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    Spacer()
                } else if filteredEmployees.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "person.3")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No employees found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        if !searchText.isEmpty {
                            Text("Try adjusting your search")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredEmployees) { employee in
                            AdminEmployeeRow(employee: employee) {
                                selectedEmployee = employee
                            }
                        }
                        
                        if hasMorePages && searchText.isEmpty {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .onAppear {
                                Task {
                                    await loadEmployees(reset: false)
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Employees")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await loadEmployees(reset: true)
            }
        }
        .onAppear {
            if employees.isEmpty {
                Task {
                    await loadEmployees(reset: true)
                }
            }
        }
        .sheet(item: $selectedEmployee) { employee in
            AdminEmployeeDetailView(employee: employee)
        }
    }
    
    private func loadEmployees(reset: Bool) async {
        if reset {
            currentPage = 1
            hasMorePages = true
            employees.removeAll()
        }
        
        if !hasMorePages { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.getAllEmployees(
                page: currentPage,
                search: searchText.isEmpty ? nil : searchText
            )
            
            if reset {
                employees = response.employees
            } else {
                employees.append(contentsOf: response.employees)
            }
            
            hasMorePages = response.pagination.currentPage < response.pagination.totalPages
            currentPage += 1
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

struct AdminEmployeeRow: View {
    let employee: Employee
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(employee.fullName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(employee.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let department = employee.department {
                            Text(department)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("ID: \(employee.employeeId ?? "N/A")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(employee.status.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(employee.status == "active" ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                            .foregroundColor(employee.status == "active" ? .green : .orange)
                            .cornerRadius(8)
                    }
                }
                
                HStack {
                    if let employment = employee.employment, let startDate = employment.startDate {
                        Label("Started \(startDate, style: .date)", systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Label("Joined \(employee.createdAt, style: .date)", systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if let salaryDetail = employee.salaryDetail {
                        Text("$\(Int(salaryDetail.grossSalary ?? 0))/mo")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

struct AdminEmployeeDetailView: View {
    let employee: Employee
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(employee.fullName)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Label(employee.email, systemImage: "envelope")
                            .foregroundColor(.secondary)
                        
                        if let phone = employee.phone {
                            Label(phone, systemImage: "phone")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // Employment Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Employment")
                            .font(.headline)
                        
                        DetailRow(label: "Status", value: employee.status.capitalized)
                        
                        if let employment = employee.employment {
                            if let position = employment.employmentPosition {
                                DetailRow(label: "Position", value: position)
                            }
                            
                            if let startDate = employment.startDate {
                                DetailRow(label: "Start Date", value: startDate.formatted(date: .abbreviated, time: .omitted))
                            }
                            
                            if let endDate = employment.endDate {
                                DetailRow(label: "End Date", value: endDate.formatted(date: .abbreviated, time: .omitted))
                            }
                        }
                        
                        if let department = employee.department {
                            DetailRow(label: "Department", value: department)
                        }
                        
                        if let title = employee.title {
                            DetailRow(label: "Title", value: title)
                        }
                    }
                    
                    Divider()
                    
                    // Salary Details
                    if let salaryDetail = employee.salaryDetail {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Salary Information")
                                .font(.headline)
                            
                            DetailRow(label: "Gross Salary", value: "$\(Int(salaryDetail.grossSalary ?? 0))")
                            DetailRow(label: "Net Salary", value: "$\(Int(salaryDetail.netSalary ?? 0))")
                            
                        }
                        
                        Divider()
                    }
                    
                    // Personal Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Personal Information")
                            .font(.headline)
                        
                        DetailRow(label: "Employee ID", value: employee.employeeId ?? "N/A")
                        
                        if let location = employee.location {
                            DetailRow(label: "Location", value: location)
                        }
                        
                        if let country = employee.country {
                            DetailRow(label: "Country", value: country)
                        }
                        
                        DetailRow(label: "Account Created", value: employee.createdAt.formatted(date: .abbreviated, time: .shortened))
                    }
                }
                .padding()
            }
            .navigationTitle("Employee Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AdminSettingsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Admin Settings")
                    .font(.title)
                Text("Coming soon...")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    AdminDashboardView()
}