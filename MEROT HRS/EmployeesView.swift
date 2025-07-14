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
                                        selectedEmployee = employee
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
                        currentPage = 1
                        await loadEmployees()
                    }
                }
            }
            .navigationTitle("Employees")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedEmployee) { employee in
                EmployeeDetailView(employee: employee)
            }
        }
        .onAppear {
            Task {
                await loadEmployees()
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
        HStack {
            // Avatar
            Circle()
                .fill(Color.merotBlue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(employee.fullName.prefix(2).uppercased())
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.merotBlue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(employee.fullName)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    StatusBadge(status: employee.status)
                }
                
                Text(employee.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    if let employeeId = employee.employeeId {
                        Text("ID: \(employeeId)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let department = employee.department {
                        Text("• \(department)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if let employment = employee.employment {
                        VStack(alignment: .trailing, spacing: 2) {
                            if let position = employment.employmentPosition {
                                Text(position)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            if let salary = employment.grossSalaryDouble {
                                Text("$\(Int(salary))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct ErrorView: View {
    let message: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Error")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry", action: retry)
                .buttonStyle(MerotButtonStyle())
        }
        .padding()
    }
}