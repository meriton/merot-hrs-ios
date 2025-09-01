//
//  MainAppView.swift
//  MEROT HRS
//
//  Created by Claude on 8/5/25.
//

import SwiftUI

struct MainAppView: View {
    @State private var logoOpacity: Double = 0.0
    @State private var logoScale: Double = 1.5
    @State private var backgroundOpacity: Double = 1.0
    @State private var showMainContent = false
    @State private var phraseOpacities: [Double] = [0.0, 0.0]
    @Environment(\.colorScheme) var colorScheme
    
    private let taglinePhrases = ["Your Team,", "Beyond Borders."]
    
    var body: some View {
        ZStack {
            // Main content (always present but initially invisible)
            MainContentView()
                .opacity(showMainContent ? 1.0 : 0.0)
            
            // Splash overlay
            if backgroundOpacity > 0 {
                ZStack {
                    // Background
                    (colorScheme == .dark ? Color.black : Color.white)
                        .ignoresSafeArea()
                        .opacity(backgroundOpacity)
                    
                    // Logo and tagline centered in screen
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image("MerotLogo")
                            .renderingMode(colorScheme == .dark ? .template : .original)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 80)
                            .foregroundColor(colorScheme == .dark ? .white : nil)
                            .scaleEffect(logoScale)
                            .opacity(logoOpacity)
                        
                        // Animated tagline
                        HStack(spacing: 8) {
                            ForEach(0..<taglinePhrases.count, id: \.self) { index in
                                Text(taglinePhrases[index])
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .opacity(phraseOpacities[index])
                            }
                        }
                        
                        Spacer()
                    }
                }
                .allowsHitTesting(false)
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Phase 1: Fade in logo (centered and scaled up)
        withAnimation(.easeOut(duration: 0.5)) {
            logoOpacity = 1.0
        }
        
        // Phase 2: Animate tagline phrases one by one
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            for index in 0..<taglinePhrases.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.8) {
                    withAnimation(.easeIn(duration: 1.0)) {
                        phraseOpacities[index] = 1.0
                    }
                }
            }
        }
        
        // Phase 3: Hold for a moment after tagline completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            // Phase 4: Fade in main content while keeping logo visible
            withAnimation(.easeInOut(duration: 0.8)) {
                showMainContent = true
            }
            
            // Phase 5: Fade out splash overlay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 0.5)) {
                    backgroundOpacity = 0.0
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
                    } else if currentUser.userType == "employee" {
                        EmployeeDashboardView()
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

// MARK: - Employee Dashboard Views

struct EmployeeDashboardView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            EmployeeHomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            EmployeeTimeOffView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Time Off")
                }
                .tag(1)
            
            EmployeePaystubsView()
                .tabItem {
                    Image(systemName: "doc.text.fill")
                    Text("Paystubs")
                }
                .tag(2)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Sign Out") {
                    Task {
                        await authService.logout()
                    }
                }
                .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Employee Home Tab

struct EmployeeHomeView: View {
    @State private var dashboardData: EmployeeDashboardData?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading dashboard...")
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 50)
                    } else if let errorMessage = errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text("Unable to load dashboard")
                                .font(.headline)
                            Text(errorMessage)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                            Button("Try Again") {
                                Task {
                                    await loadDashboardData()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    } else if let data = dashboardData {
                        // Welcome Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Welcome back!")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(data.employee.fullName)
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            if let employment = data.employment {
                                Text(employment.position)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                if let employer = employment.employer {
                                    Text(employer.name ?? "")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .cornerRadius(16)
                        
                        // Quick Stats
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            StatCard(
                                title: "Time Off Available",
                                value: "\(data.timeOff.availableDays)",
                                subtitle: "days",
                                icon: "calendar.badge.plus",
                                color: .green
                            )
                            
                            StatCard(
                                title: "Pending Requests",
                                value: "\(data.timeOff.pendingRequestsCount)",
                                subtitle: "requests",
                                icon: "clock.fill",
                                color: .orange
                            )
                        }
                        
                        // Time Tracking (if available)
                        if data.timeTracking.currentlyClockedIn || 
                           data.timeTracking.totalHoursThisWeek != nil ||
                           data.timeTracking.totalHoursThisMonth != nil {
                            
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Time Tracking")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    if data.timeTracking.currentlyClockedIn {
                                        Label("Currently Clocked In", systemImage: "clock.fill")
                                            .foregroundColor(.green)
                                            .font(.subheadline)
                                    } else {
                                        Label("Clocked Out", systemImage: "clock")
                                            .foregroundColor(.secondary)
                                            .font(.subheadline)
                                    }
                                    Spacer()
                                }
                                
                                if let weekHours = data.timeTracking.totalHoursThisWeek {
                                    HStack {
                                        Text("This Week:")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("\(String(format: "%.1f", weekHours)) hours")
                                            .fontWeight(.semibold)
                                    }
                                }
                                
                                if let monthHours = data.timeTracking.totalHoursThisMonth {
                                    HStack {
                                        Text("This Month:")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("\(String(format: "%.1f", monthHours)) hours")
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(16)
                            .shadow(radius: 2)
                        }
                        
                        // Recent Time Off Requests
                        if !data.timeOff.pendingRequests.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recent Time Off Requests")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                ForEach(data.timeOff.pendingRequests.prefix(3)) { request in
                                    TimeOffRequestRow(request: request)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(16)
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
            if let networkError = error as? NetworkManager.NetworkError {
                errorMessage = networkError.localizedDescription
            } else {
                errorMessage = "Network error: \(error.localizedDescription)"
            }
        }
        
        isLoading = false
    }
}

// MARK: - Employee Time Off Tab

struct EmployeeTimeOffView: View {
    @State private var timeOffRecords: [EmployeeTimeOffRecordBalance] = []
    @State private var timeOffRequests: [EmployeeTimeOffRequest] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingNewRequestForm = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Loading time off data...")
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 50)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("Unable to load time off data")
                            .font(.headline)
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        Button("Try Again") {
                            Task {
                                await loadTimeOffData()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            // Time Off Balances
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Available Time Off")
                                    .font(.headline)
                                
                                if timeOffRecords.isEmpty {
                                    Text("No time off records available")
                                        .foregroundColor(.secondary)
                                        .italic()
                                } else {
                                    ForEach(timeOffRecords) { record in
                                        TimeOffBalanceRow(record: record)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(16)
                            .shadow(radius: 2)
                            
                            // Recent Requests
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Your Requests")
                                        .font(.headline)
                                    Spacer()
                                    Button("New Request") {
                                        showingNewRequestForm = true
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                }
                                
                                if timeOffRequests.isEmpty {
                                    Text("No time off requests yet")
                                        .foregroundColor(.secondary)
                                        .italic()
                                } else {
                                    ForEach(timeOffRequests.prefix(10)) { request in
                                        TimeOffRequestRow(request: request)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(16)
                            .shadow(radius: 2)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Time Off")
            .refreshable {
                await loadTimeOffData()
            }
            .sheet(isPresented: $showingNewRequestForm) {
                NewTimeOffRequestView(timeOffRecords: timeOffRecords) {
                    Task {
                        await loadTimeOffData()
                    }
                }
            }
        }
        .onAppear {
            Task {
                await loadTimeOffData()
            }
        }
    }
    
    private func loadTimeOffData() async {
        isLoading = true
        errorMessage = nil
        
        // Load time off balances and requests in parallel
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await loadTimeOffRecords()
            }
            group.addTask {
                await loadTimeOffRequests()
            }
        }
        
        isLoading = false
    }
    
    private func loadTimeOffRecords() async {
        do {
            let response: APIResponse<EmployeeTimeOffRecordList> = try await NetworkManager.shared.get(
                endpoint: "/employees/time_off_records",
                responseType: APIResponse<EmployeeTimeOffRecordList>.self
            )
            
            if response.success {
                timeOffRecords = response.data.timeOffRecords
            }
        } catch {
            print("Failed to load time off records: \(error)")
            errorMessage = "Failed to load time off balances"
        }
    }
    
    private func loadTimeOffRequests() async {
        do {
            let response: APIResponse<EmployeeTimeOffRequestList> = try await NetworkManager.shared.get(
                endpoint: "/employees/time_off_requests",
                responseType: APIResponse<EmployeeTimeOffRequestList>.self
            )
            
            if response.success {
                timeOffRequests = response.data.timeOffRequests
            }
        } catch {
            print("Failed to load time off requests: \(error)")
            errorMessage = "Failed to load time off requests"
        }
    }
}

// MARK: - Employee Paystubs Tab

struct EmployeePaystubsView: View {
    @State private var payrollRecords: [EmployeePayrollRecord] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Loading paystubs...")
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 50)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("Unable to load paystubs")
                            .font(.headline)
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        Button("Try Again") {
                            Task {
                                await loadPaystubs()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    if payrollRecords.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "doc.text")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text("No paystubs available")
                                .font(.headline)
                            Text("Your paystubs will appear here once they are generated")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    } else {
                        List {
                            ForEach(payrollRecords) { record in
                                PaystubRow(record: record)
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationTitle("Paystubs")
            .refreshable {
                await loadPaystubs()
            }
        }
        .onAppear {
            Task {
                await loadPaystubs()
            }
        }
    }
    
    private func loadPaystubs() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: APIResponse<EmployeePayrollRecordList> = try await NetworkManager.shared.get(
                endpoint: "/employees/payroll_records",
                responseType: APIResponse<EmployeePayrollRecordList>.self
            )
            
            if response.success {
                payrollRecords = response.data.payrollRecords
            } else {
                errorMessage = response.message ?? "Failed to load paystubs"
            }
        } catch {
            if let networkError = error as? NetworkManager.NetworkError {
                errorMessage = networkError.localizedDescription
            } else {
                errorMessage = "Network error: \(error.localizedDescription)"
            }
        }
        
        isLoading = false
    }
}

// MARK: - Helper Components

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TimeOffRequestRow: View {
    let request: EmployeeTimeOffRequest
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(request.timeOffRecord?.name ?? "Time Off")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let startDate = request.startDate, let endDate = request.endDate {
                    Text("\(formatDate(startDate)) - \(formatDate(endDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let days = request.days {
                    Text("\(String(format: "%.1f", days)) days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(request.approvalStatus.capitalized)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor(for: request.approvalStatus))
                .foregroundColor(.white)
                .cornerRadius(12)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
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
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

struct TimeOffBalanceRow: View {
    let record: EmployeeTimeOffRecordBalance
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(record.leaveType.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(record.balance)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                Text("of \(record.totalDays) days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

struct PaystubRow: View {
    let record: EmployeePayrollRecord
    @State private var showingPDFViewer = false
    @State private var isDownloading = false
    @State private var pdfData: Data?
    @State private var errorMessage: String?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let batch = record.payrollBatch {
                    Text("\(monthName(batch.month)) \(batch.year)")
                        .font(.headline)
                } else {
                    Text("Payroll Record")
                        .font(.headline)
                }
                
                if let grossPay = record.grossPay {
                    Text("Gross: €\(String(format: "%.2f", grossPay))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                if let netPay = record.netPay {
                    Text("€\(String(format: "%.2f", netPay))")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Net Pay")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button(isDownloading ? "Loading..." : "View PDF") {
                    Task {
                        await downloadPDF()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(isDownloading)
            }
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showingPDFViewer) {
            if let pdfData = pdfData {
                PDFViewerView(pdfData: pdfData, title: pdfTitle())
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func monthName(_ month: Int) -> String {
        let dateFormatter = DateFormatter()
        return dateFormatter.monthSymbols[month - 1]
    }
    
    private func pdfTitle() -> String {
        if let batch = record.payrollBatch {
            return "Paystub - \(monthName(batch.month)) \(batch.year)"
        }
        return "Paystub"
    }
    
    private func downloadPDF() async {
        isDownloading = true
        errorMessage = nil
        
        do {
            let data = try await NetworkManager.shared.downloadData(
                endpoint: "/employees/payroll_records/\(record.id)/paystub"
            )
            
            pdfData = data
            showingPDFViewer = true
        } catch {
            errorMessage = "Failed to download paystub: \(error.localizedDescription)"
        }
        
        isDownloading = false
    }
}

struct NewTimeOffRequestView: View {
    let timeOffRecords: [EmployeeTimeOffRecordBalance]
    let onRequestCreated: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedRecordId: Int?
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("New Time Off Request")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                if timeOffRecords.isEmpty {
                    Text("No time off types available")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Time Off Type")
                            .font(.headline)
                        
                        ForEach(timeOffRecords) { record in
                            HStack {
                                Button(action: {
                                    selectedRecordId = record.id
                                }) {
                                    HStack {
                                        Image(systemName: selectedRecordId == record.id ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedRecordId == record.id ? .blue : .gray)
                                        Text(record.name)
                                        Spacer()
                                        Text("\(record.balance) days available")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding()
                            .background(selectedRecordId == record.id ? Color.blue.opacity(0.1) : Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Dates")
                            .font(.headline)
                        
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                    }
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                HStack {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Submit Request") {
                        Task {
                            await submitRequest()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedRecordId == nil || isSubmitting)
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
    
    private func submitRequest() async {
        guard let recordId = selectedRecordId else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        let requestData: [String: Any] = [
            "time_off_request": [
                "time_off_record_id": recordId,
                "start_date": ISO8601DateFormatter().string(from: startDate),
                "end_date": ISO8601DateFormatter().string(from: endDate),
                "days": Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1
            ]
        ]
        
        do {
            let _: APIResponse<[String: Any]> = try await NetworkManager.shared.post(
                endpoint: "/employees/time_off_requests",
                body: requestData,
                responseType: APIResponse<[String: Any]>.self
            )
            
            onRequestCreated()
            presentationMode.wrappedValue.dismiss()
        } catch {
            errorMessage = "Failed to submit request: \(error.localizedDescription)"
        }
        
        isSubmitting = false
    }
}

#Preview {
    MainAppView()
}