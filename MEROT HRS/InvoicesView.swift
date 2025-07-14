import SwiftUI

struct InvoicesView: View {
    @StateObject private var apiService = APIService()
    @State private var invoices: [Invoice] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedInvoice: Invoice?
    @State private var selectedStatus: String = "all"
    @Environment(\.colorScheme) var colorScheme
    
    let statusOptions = [
        ("all", "All"),
        ("draft", "Draft"),
        ("sent", "Sent"),
        ("processing", "Processing"),
        ("paid", "Paid"),
        ("overdue", "Overdue")
    ]
    
    var filteredInvoices: [Invoice] {
        if selectedStatus == "all" {
            return invoices
        } else if selectedStatus == "overdue" {
            return invoices.filter { $0.overdue }
        } else {
            return invoices.filter { $0.status == selectedStatus }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Status Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(statusOptions, id: \.0) { status, title in
                            InvoiceFilterChip(
                                title: title,
                                isSelected: selectedStatus == status,
                                count: countForStatus(status)
                            ) {
                                selectedStatus = status
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                Divider()
                
                // Invoices List
                if isLoading {
                    Spacer()
                    ProgressView("Loading invoices...")
                    Spacer()
                } else if let errorMessage = errorMessage {
                    Spacer()
                    ErrorView(message: errorMessage) {
                        Task {
                            await loadInvoices()
                        }
                    }
                    Spacer()
                } else if filteredInvoices.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No invoices found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        if selectedStatus != "all" {
                            Text("Try selecting a different status filter")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                } else {
                    List(filteredInvoices, id: \.id) { invoice in
                        InvoiceRow(invoice: invoice) {
                            selectedInvoice = invoice
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Invoices")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await loadInvoices()
            }
        }
        .onAppear {
            Task {
                await loadInvoices()
            }
        }
        .sheet(item: $selectedInvoice) { invoice in
            InvoiceDetailView(invoice: invoice)
        }
    }
    
    private func countForStatus(_ status: String) -> Int {
        if status == "all" {
            return invoices.count
        } else if status == "overdue" {
            return invoices.filter { $0.overdue }.count
        } else {
            return invoices.filter { $0.status == status }.count
        }
    }
    
    private func loadInvoices() async {
        isLoading = true
        errorMessage = nil
        
        do {
            invoices = try await apiService.getInvoices()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

struct InvoiceFilterChip: View {
    let title: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Text("(\(count))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.merotBlue : (colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray5)))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InvoiceRow: View {
    let invoice: Invoice
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header row
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(invoice.invoice_number)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if let billingPeriod = invoice.billing_period_display {
                            Text(billingPeriod)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(String(format: "$%.2f", invoice.total_amount))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        InvoiceStatusBadge(status: invoice.status, isOverdue: invoice.overdue)
                    }
                }
                
                // Details row
                HStack {
                    Label {
                        Text("Due: \(formatDate(invoice.due_date))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if invoice.overdue {
                        Label {
                            Text("\(invoice.days_overdue) days overdue")
                                .font(.caption)
                                .foregroundColor(.red)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

struct InvoiceStatusBadge: View {
    let status: String
    let isOverdue: Bool
    
    var statusColor: Color {
        if isOverdue {
            return .red
        }
        
        switch status.lowercased() {
        case "paid":
            return .green
        case "sent", "processing":
            return .blue
        case "draft":
            return .orange
        case "cancelled":
            return .gray
        default:
            return .secondary
        }
    }
    
    var statusText: String {
        if isOverdue {
            return "Overdue"
        }
        return status.capitalized
    }
    
    var body: some View {
        Text(statusText)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(8)
    }
}

// MARK: - Data Models
struct Invoice: Codable, Identifiable {
    let id: Int
    let invoice_number: String
    let status: String
    let issue_date: String
    let due_date: String
    let total_amount: Double
    let subtotal: Double
    let tax_amount: Double
    let currency: String
    let billing_period_start: String?
    let billing_period_end: String?
    let billing_period_display: String?
    let overdue: Bool
    let days_overdue: Int
    let created_at: String
    let updated_at: String
}

struct InvoiceListResponse: Codable {
    let invoices: [Invoice]
    let pagination: InvoicePaginationInfo
}

struct InvoicePaginationInfo: Codable {
    let current_page: Int
    let per_page: Int
    let total_count: Int
    let total_pages: Int
}

#Preview {
    InvoicesView()
}