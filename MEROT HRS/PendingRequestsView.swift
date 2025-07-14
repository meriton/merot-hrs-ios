import SwiftUI

struct PendingRequestsView: View {
    @StateObject private var apiService = APIService()
    @State private var pendingRequests: [TimeOffRequest] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedRequest: TimeOffRequest?
    @State private var processingRequestId: Int?
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading pending requests...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if pendingRequests.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("No Pending Requests")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("All time off requests have been processed")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(pendingRequests, id: \.id) { request in
                            PendingRequestRow(
                                request: request,
                                isProcessing: processingRequestId == request.id,
                                onApprove: { await approveRequest(request) },
                                onDeny: { await denyRequest(request) },
                                onTap: {
                                    selectedRequest = request
                                }
                            )
                        }
                    }
                    .refreshable {
                        await loadPendingRequests()
                    }
                }
                
                if let errorMessage = errorMessage {
                    VStack {
                        Text("Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .padding()
                        
                        Button("Retry") {
                            Task {
                                await loadPendingRequests()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("Pending Requests")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task {
                    await loadPendingRequests()
                }
            }
            .sheet(item: $selectedRequest) { request in
                RequestDetailView(request: request) {
                    Task {
                        await loadPendingRequests()
                    }
                }
            }
        }
    }
    
    private func loadPendingRequests() async {
        isLoading = true
        errorMessage = nil
        
        do {
            pendingRequests = try await apiService.getTimeOffRequests(status: "pending")
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func approveRequest(_ request: TimeOffRequest) async {
        processingRequestId = request.id
        
        do {
            _ = try await apiService.approveTimeOffRequest(id: request.id)
            await loadPendingRequests()
        } catch {
            errorMessage = "Failed to approve request: \(error.localizedDescription)"
        }
        
        processingRequestId = nil
    }
    
    private func denyRequest(_ request: TimeOffRequest) async {
        processingRequestId = request.id
        
        do {
            _ = try await apiService.denyTimeOffRequest(id: request.id)
            await loadPendingRequests()
        } catch {
            errorMessage = "Failed to deny request: \(error.localizedDescription)"
        }
        
        processingRequestId = nil
    }
}

struct PendingRequestRow: View {
    let request: TimeOffRequest
    let isProcessing: Bool
    let onApprove: () async -> Void
    let onDeny: () async -> Void
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.employee.fullName)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text(request.employee.department)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Employee ID: \(request.employee.employeeId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    StatusBadge(status: request.approvalStatus)
                    
                    Text("\(request.days) day\(request.days == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Leave Period")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(formattedDate(request.startDate)) - \(formattedDate(request.endDate))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                if let leaveType = request.timeOffRecord?.leaveType {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Type")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(leaveType.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    Task {
                        await onApprove()
                    }
                }) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark")
                        }
                        Text("Approve")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(isProcessing)
                
                Button(action: {
                    Task {
                        await onDeny()
                    }
                }) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "xmark")
                        }
                        Text("Deny")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(isProcessing)
                
                Button(action: onTap) {
                    HStack {
                        Image(systemName: "info.circle")
                        Text("Details")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isProcessing)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }
    
    private func formattedDate(_ dateString: String) -> String {
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

struct RequestDetailView: View {
    let request: TimeOffRequest
    let onDismiss: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Employee Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Employee Information")
                            .font(.headline)
                        
                        RequestInfoRow(label: "Name", value: request.employee.fullName)
                        RequestInfoRow(label: "Employee ID", value: request.employee.employeeId)
                        RequestInfoRow(label: "Department", value: request.employee.department)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Request Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Request Details")
                            .font(.headline)
                        
                        RequestInfoRow(label: "Leave Type", value: request.timeOffRecord?.leaveType?.replacingOccurrences(of: "_", with: " ").capitalized ?? "Unknown")
                        RequestInfoRow(label: "Start Date", value: formattedDate(request.startDate))
                        RequestInfoRow(label: "End Date", value: formattedDate(request.endDate))
                        RequestInfoRow(label: "Duration", value: "\(request.days) day\(request.days == 1 ? "" : "s")")
                        RequestInfoRow(label: "Status", value: request.approvalStatus.capitalized)
                        RequestInfoRow(label: "Requested", value: formattedDate(request.createdAt))
                        
                        if let balance = request.timeOffRecord?.balance {
                            RequestInfoRow(label: "Available Balance", value: "\(balance) days")
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Request Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                        onDismiss()
                    }
                }
            }
        }
    }
    
    private func formattedDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .full
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

struct RequestInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    PendingRequestsView()
}