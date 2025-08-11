import SwiftUI

struct UserManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cachedAPIService = CachedAPIService()
    @State private var users: [AdminUser] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var selectedRole: UserRole = .all
    @State private var showingAddUser = false
    @State private var showingUserDetails: AdminUser?
    
    enum UserRole: String, CaseIterable {
        case all = "All"
        case admin = "Admin"
        case manager = "Manager"
        case employee = "Employee"
        case suspended = "Suspended"
    }
    
    var filteredUsers: [AdminUser] {
        users.filter { user in
            let matchesSearch = searchText.isEmpty || 
                               user.name.localizedCaseInsensitiveContains(searchText) ||
                               user.email.localizedCaseInsensitiveContains(searchText)
            
            let matchesRole = selectedRole == .all || user.role.rawValue == selectedRole.rawValue
            
            return matchesSearch && matchesRole
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Bar
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search users", text: $searchText)
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
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(UserRole.allCases, id: \.self) { role in
                                Button(action: {
                                    selectedRole = role
                                }) {
                                    Text(role.rawValue)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedRole == role ? Color.blue : Color(.systemGray5))
                                        .foregroundColor(selectedRole == role ? .white : .primary)
                                        .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                
                if isLoading {
                    Spacer()
                    ProgressView("Loading users...")
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
                                await loadUsers()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    Spacer()
                } else if filteredUsers.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "person.2")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No users found")
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
                        ForEach(filteredUsers) { user in
                            UserRow(user: user) {
                                showingUserDetails = user
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("User Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddUser = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .onAppear {
            Task {
                await loadUsers()
            }
        }
        .sheet(isPresented: $showingAddUser) {
            AddUserView()
        }
        .sheet(item: $showingUserDetails) { user in
            UserDetailView(user: user)
        }
    }
    
    private func loadUsers() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Simulate loading users - replace with actual API call
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            let sampleUsers = [
                AdminUser(id: 1, name: "John Admin", email: "john@merot.com", role: .admin, status: .active, lastLogin: Date().addingTimeInterval(-3600), createdAt: Date().addingTimeInterval(-86400 * 30)),
                AdminUser(id: 2, name: "Sarah Manager", email: "sarah@merot.com", role: .manager, status: .active, lastLogin: Date().addingTimeInterval(-7200), createdAt: Date().addingTimeInterval(-86400 * 15)),
                AdminUser(id: 3, name: "Mike Employee", email: "mike@merot.com", role: .employee, status: .active, lastLogin: Date().addingTimeInterval(-86400), createdAt: Date().addingTimeInterval(-86400 * 7)),
                AdminUser(id: 4, name: "Lisa Suspended", email: "lisa@merot.com", role: .employee, status: .suspended, lastLogin: Date().addingTimeInterval(-86400 * 7), createdAt: Date().addingTimeInterval(-86400 * 60))
            ]
            
            await MainActor.run {
                users = sampleUsers
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load users: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

struct AdminUser: Identifiable {
    let id: Int
    let name: String
    let email: String
    let role: UserRole
    let status: UserStatus
    let lastLogin: Date
    let createdAt: Date
    
    enum UserRole: String, CaseIterable {
        case admin = "Admin"
        case manager = "Manager"
        case employee = "Employee"
        
        var color: Color {
            switch self {
            case .admin: return .red
            case .manager: return .orange
            case .employee: return .blue
            }
        }
    }
    
    enum UserStatus: String, CaseIterable {
        case active = "Active"
        case suspended = "Suspended"
        case pending = "Pending"
        
        var color: Color {
            switch self {
            case .active: return .green
            case .suspended: return .red
            case .pending: return .orange
            }
        }
    }
}

struct UserRow: View {
    let user: AdminUser
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(user.role.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(user.role.color.opacity(0.2))
                            .foregroundColor(user.role.color)
                            .cornerRadius(8)
                        
                        Text(user.status.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(user.status.color.opacity(0.2))
                            .foregroundColor(user.status.color)
                            .cornerRadius(8)
                    }
                }
                
                HStack {
                    Label("Last login: \(user.lastLogin, style: .relative)", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("ID: \(user.id)")
                        .font(.caption)
                        .foregroundColor(.secondary)
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

struct AddUserView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var role: AdminUser.UserRole = .employee
    @State private var sendWelcomeEmail = true
    
    var body: some View {
        NavigationView {
            Form {
                Section("User Information") {
                    TextField("Full Name", text: $name)
                    TextField("Email Address", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                Section("Permissions") {
                    Picker("Role", selection: $role) {
                        ForEach(AdminUser.UserRole.allCases, id: \.self) { role in
                            Text(role.rawValue).tag(role)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Notifications") {
                    Toggle("Send Welcome Email", isOn: $sendWelcomeEmail)
                }
            }
            .navigationTitle("Add User")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        // TODO: Implement user creation
                        dismiss()
                    }
                    .disabled(name.isEmpty || email.isEmpty)
                }
            }
        }
    }
}

struct UserDetailView: View {
    let user: AdminUser
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            List {
                Section("User Information") {
                    InfoRow(label: "Name", value: user.name)
                    InfoRow(label: "Email", value: user.email)
                    InfoRow(label: "User ID", value: "\(user.id)")
                }
                
                Section("Access") {
                    HStack {
                        Text("Role")
                        Spacer()
                        Text(user.role.rawValue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(user.role.color.opacity(0.2))
                            .foregroundColor(user.role.color)
                            .cornerRadius(8)
                    }
                    
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(user.status.rawValue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(user.status.color.opacity(0.2))
                            .foregroundColor(user.status.color)
                            .cornerRadius(8)
                    }
                }
                
                Section("Activity") {
                    InfoRow(label: "Last Login", value: user.lastLogin.formatted(date: .abbreviated, time: .shortened))
                    InfoRow(label: "Account Created", value: user.createdAt.formatted(date: .abbreviated, time: .omitted))
                }
                
                Section("Actions") {
                    Button("Reset Password") {
                        // TODO: Implement password reset
                    }
                    
                    Button("Send Welcome Email") {
                        // TODO: Implement welcome email
                    }
                    
                    if user.status == .active {
                        Button("Suspend User") {
                            // TODO: Implement user suspension
                        }
                        .foregroundColor(.orange)
                    } else {
                        Button("Activate User") {
                            // TODO: Implement user activation
                        }
                        .foregroundColor(.green)
                    }
                    
                    Button("Delete User") {
                        showingDeleteConfirmation = true
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("User Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Delete User", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // TODO: Implement user deletion
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete \(user.name)? This action cannot be undone.")
        }
    }
}

#Preview {
    UserManagementView()
}