import SwiftUI

struct EmployeesView: View {
    @StateObject private var apiService = APIService()
    @State private var employees: [Employee] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var selectedStatus = "all"
    @State private var currentPage = 1
    @State private var totalPages = 1
    @State private var selectedEmployee: Employee?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @Binding var filterFromDashboard: String?
    
    // Optional bindings for iPad detail pane
    @Binding var selectedEmployeeForDetail: Employee?
    @Binding var selectedInvoice: Invoice?
    @Binding var selectedJobPosting: JobPosting?
    @Binding var selectedEmployer: Employer?
    private let isIPadMode: Bool
    
    // Default initializer for iPhone (no detail pane bindings)
    init(filterFromDashboard: Binding<String?> = .constant(nil)) {
        self._filterFromDashboard = filterFromDashboard
        self._selectedEmployeeForDetail = .constant(nil)
        self._selectedInvoice = .constant(nil)
        self._selectedJobPosting = .constant(nil)
        self._selectedEmployer = .constant(nil)
        self.isIPadMode = false
    }
    
    // iPad initializer with detail pane bindings
    init(filterFromDashboard: Binding<String?> = .constant(nil), selectedEmployee: Binding<Employee?>, selectedInvoice: Binding<Invoice?> = .constant(nil), selectedJobPosting: Binding<JobPosting?> = .constant(nil), selectedEmployer: Binding<Employer?> = .constant(nil)) {
        self._filterFromDashboard = filterFromDashboard
        self._selectedEmployeeForDetail = selectedEmployee
        self._selectedInvoice = selectedInvoice
        self._selectedJobPosting = selectedJobPosting
        self._selectedEmployer = selectedEmployer
        self.isIPadMode = true
    }
    
    private let statusOptions = ["all", "active", "terminated", "pending"]
    
    var filteredEmployees: [Employee] {
        if searchText.isEmpty {
            return employees
        } else {
            return employees.filter { employee in
                employee.fullName.localizedCaseInsensitiveContains(searchText) ||
                employee.email.localizedCaseInsensitiveContains(searchText) ||
                (employee.employeeId?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Bar
                VStack(spacing: 12) {
                    SearchBar(text: $searchText)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(statusOptions, id: \.self) { status in
                                FilterChip(
                                    title: status.capitalized,
                                    isSelected: selectedStatus == status,
                                    action: {
                                        selectedStatus = status
                                        currentPage = 1
                                        Task {
                                            await loadEmployees()
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 12)
                .background(Color(.systemGray6))
                
                if isLoading {
                    Spacer()
                    ProgressView("Loading employees...")
                    Spacer()
                } else if let errorMessage = errorMessage {
                    Spacer()
                    ErrorView(message: errorMessage) {
                        Task {
                            await loadEmployees()
                        }
                    }
                    Spacer()
                } else {
                    // Employee List
                    List {
                        ForEach(filteredEmployees) { employee in
                            EmployeeRow(employee: employee)
                                .onTapGesture {
                                    if !isLoading {
                                        if isIPadMode {
                                            // iPad: show in detail pane, clear other selections first, then set new selection
                                            selectedInvoice = nil
                                            selectedJobPosting = nil
                                            selectedEmployer = nil
                                            selectedEmployeeForDetail = nil // Clear first to force update
                                            DispatchQueue.main.async {
                                                selectedEmployeeForDetail = employee // Then set new selection
                                            }
                                        } else {
                                            // iPhone: show in sheet
                                            selectedEmployee = employee
                                        }
                                    }
                                }
                        }
                        
                        // Pagination
                        if currentPage < totalPages {
                            HStack {
                                Spacer()
                                Button("Load More") {
                                    currentPage += 1
                                    Task {
                                        await loadMoreEmployees()
                                    }
                                }
                                .buttonStyle(.bordered)
                                Spacer()
                            }
                            .padding()
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await refreshEmployees()
                    }
                }
            }
            .navigationTitle("Employees")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: isIPadMode ? .constant(nil) : $selectedEmployee) { employee in
                EmployeeDetailView(employee: employee)
            }
        }
        .onAppear {
            Task {
                await loadEmployees()
            }
        }
        .onChange(of: filterFromDashboard) { newFilter in
            if let newFilter = newFilter, statusOptions.contains(newFilter) {
                selectedStatus = newFilter
                currentPage = 1
                Task {
                    await loadEmployees()
                }
                // Reset the filter after using it
                filterFromDashboard = nil
            }
        }
    }
    
    private func loadEmployees() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let status = selectedStatus == "all" ? nil : selectedStatus
            let response = try await apiService.getEmployees(
                page: currentPage,
                perPage: 20,
                status: status,
                search: searchText.isEmpty ? nil : searchText
            )
            
            if currentPage == 1 {
                employees = response.employees
            } else {
                employees.append(contentsOf: response.employees)
            }
            
            totalPages = response.pagination.totalPages
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func loadMoreEmployees() async {
        do {
            let status = selectedStatus == "all" ? nil : selectedStatus
            let response = try await apiService.getEmployees(
                page: currentPage,
                perPage: 20,
                status: status,
                search: searchText.isEmpty ? nil : searchText
            )
            
            employees.append(contentsOf: response.employees)
            totalPages = response.pagination.totalPages
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func refreshEmployees() async {
        // Don't set isLoading = true for refresh to avoid UI conflicts
        currentPage = 1
        errorMessage = nil
        
        do {
            let status = selectedStatus == "all" ? nil : selectedStatus
            let response = try await apiService.getEmployees(
                page: currentPage,
                perPage: 20,
                status: status,
                search: searchText.isEmpty ? nil : searchText
            )
            
            employees = response.employees
            totalPages = response.pagination.totalPages
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search employees...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .padding(.horizontal, 16)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.merotBlue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct EmployeeRow: View {
    let employee: Employee
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.merotBlue.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(employee.fullName.prefix(2).uppercased())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.merotBlue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                // Name and status row
                HStack {
                    Text(employee.fullName)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        StatusBadge(status: employee.status)
                        
                        if let onLeave = employee.onLeave, !onLeave.isEmpty {
                            OnLeaveBadge()
                        }
                    }
                }
                
                // Email
                Text(employee.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Employee ID
                if let employeeId = employee.employeeId {
                    Text("ID: \(employeeId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}


struct OnLeaveBadge: View {
    var body: some View {
        Text("On Leave")
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.2))
            .foregroundColor(.blue)
            .cornerRadius(6)
    }
}