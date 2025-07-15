import SwiftUI

struct InvoiceDetailView: View {
    let invoice: Invoice
    @StateObject private var apiService = APIService()
    @State private var detailedInvoice: DetailedInvoice?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isDownloading = false
    @State private var pdfDataToShare: Data?
    @State private var showingShareSheet = false
    @State private var showingPDFViewer = false
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let errorMessage = errorMessage {
                        ErrorView(message: errorMessage) {
                            Task {
                                await loadInvoiceDetails()
                            }
                        }
                    } else {
                        // Always show invoice data - use detailed if available, otherwise basic
                        VStack(alignment: .leading, spacing: 20) {
                            if let detailedInvoice = detailedInvoice {
                                // Header Section
                                InvoiceHeaderCard(invoice: detailedInvoice)
                                
                                // Summary Section
                                InvoiceSummaryCard(invoice: detailedInvoice)
                                
                                // Line Items Section
                                if !detailedInvoice.line_items.isEmpty {
                                    LineItemsCard(lineItems: detailedInvoice.line_items)
                                }
                                
                                // Payment Information
                                PaymentInfoCard(invoice: detailedInvoice)
                                
                                // Total Summary at the bottom
                                InvoiceTotalCard(invoice: detailedInvoice)
                            } else {
                                // Show basic invoice data immediately while loading details
                                BasicInvoiceHeaderCard(invoice: invoice)
                                
                                if isLoading {
                                    HStack {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("Loading details...")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                }
                                
                                // Basic Total Summary at the bottom
                                BasicInvoiceTotalCard(invoice: invoice)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Invoice Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await downloadPDF()
                        }
                    }) {
                        HStack {
                            if isDownloading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.down.doc")
                            }
                            Text("PDF")
                        }
                    }
                    .disabled(isDownloading)
                }
            }
        }
        .onAppear {
            Task {
                await loadInvoiceDetails()
            }
        }
        .sheet(isPresented: $showingPDFViewer) {
            if let pdfData = pdfDataToShare {
                PDFViewerSheet(
                    pdfData: pdfData, 
                    fileName: "invoice_\(invoice.invoice_number).pdf"
                ) {
                    showingShareSheet = true
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let pdfData = pdfDataToShare {
                ShareSheet(activityItems: [pdfData])
            }
        }
    }
    
    private func loadInvoiceDetails() async {
        isLoading = true
        errorMessage = nil
        
        do {
            detailedInvoice = try await apiService.getInvoiceDetails(id: invoice.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func downloadPDF() async {
        isDownloading = true
        
        do {
            let pdfData = try await apiService.downloadInvoicePDF(id: invoice.id)
            
            // Show PDF viewer and prepare for sharing
            DispatchQueue.main.async {
                self.pdfDataToShare = pdfData
                self.showingPDFViewer = true
            }
        } catch {
            errorMessage = "Failed to download PDF: \(error.localizedDescription)"
        }
        
        isDownloading = false
    }
    
}

import PDFKit

struct PDFViewerSheet: View {
    let pdfData: Data
    let fileName: String
    let onShare: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            PDFKitView(pdfData: pdfData)
                .navigationTitle("Invoice PDF")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Close") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                onShare()
                            }
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                        }
                    }
                }
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let pdfData: Data
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        
        if let pdfDocument = PDFDocument(data: pdfData) {
            pdfView.document = pdfDocument
        }
        
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        // No updates needed
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return activityVC
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

struct BasicInvoiceHeaderCard: View {
    let invoice: Invoice
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Invoice")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(invoice.invoice_number)
                        .font(.title3)
                        .foregroundColor(.merotBlue)
                }
                
                Spacer()
                
                InvoiceStatusBadge(status: invoice.status, isOverdue: invoice.overdue)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                DetailRow(label: "Issue Date", value: formatDate(invoice.issue_date))
                DetailRow(label: "Due Date", value: formatDate(invoice.due_date))
                if let billingPeriod = invoice.billing_period_display {
                    DetailRow(label: "Billing Period", value: billingPeriod)
                }
            }
            
            if invoice.overdue {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("This invoice is \(invoice.days_overdue) days overdue")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .fontWeight(.medium)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
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

struct InvoiceHeaderCard: View {
    let invoice: DetailedInvoice
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Invoice")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(invoice.invoice_number)
                        .font(.title3)
                        .foregroundColor(.merotBlue)
                }
                
                Spacer()
                
                InvoiceStatusBadge(status: invoice.status, isOverdue: invoice.overdue)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                DetailRow(label: "Issue Date", value: formatDate(invoice.issue_date))
                DetailRow(label: "Due Date", value: formatDate(invoice.due_date))
                if let billingPeriod = invoice.billing_period_display {
                    DetailRow(label: "Billing Period", value: billingPeriod)
                }
            }
            
            if invoice.overdue {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("This invoice is \(invoice.days_overdue) days overdue")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .fontWeight(.medium)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
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

struct InvoiceSummaryCard: View {
    let invoice: DetailedInvoice
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                SummaryRow(label: "Subtotal", amount: invoice.subtotal)
                
                if invoice.discount_amount > 0 {
                    SummaryRow(label: "Discount", amount: -invoice.discount_amount, isDiscount: true)
                }
                
                if invoice.tax_amount > 0 {
                    SummaryRow(label: "Tax", amount: invoice.tax_amount)
                }
                
                if invoice.late_fee > 0 {
                    SummaryRow(label: "Late Fee", amount: invoice.late_fee, isLateFee: true)
                }
                
                Divider()
                
                SummaryRow(label: "Total", amount: invoice.total_amount, isTotal: true)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

struct LineItemsCard: View {
    let lineItems: [InvoiceLineItem]
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Services")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(lineItems, id: \.id) { item in
                    LineItemRow(item: item)
                    if item.id != lineItems.last?.id {
                        Divider()
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
}

struct PaymentInfoCard: View {
    let invoice: DetailedInvoice
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                DetailRow(label: "Total Employees", value: "\(invoice.total_employees ?? 0)")
                
                if let payrollFee = invoice.payroll_processing_fee, payrollFee > 0 {
                    DetailRow(label: "Payroll Processing Fee", value: String(format: "$%.2f", payrollFee))
                }
                
                if let hrFee = invoice.hr_services_fee, hrFee > 0 {
                    DetailRow(label: "HR Services Fee", value: String(format: "$%.2f", hrFee))
                }
                
                if let benefitsFee = invoice.benefits_administration_fee, benefitsFee > 0 {
                    DetailRow(label: "Benefits Administration Fee", value: String(format: "$%.2f", benefitsFee))
                }
                
                DetailRow(label: "Currency", value: invoice.currency)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

struct DetailRow: View {
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

struct SummaryRow: View {
    let label: String
    let amount: Double
    var isDiscount: Bool = false
    var isLateFee: Bool = false
    var isTotal: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(isTotal ? .headline : .subheadline)
                .fontWeight(isTotal ? .semibold : .regular)
                .foregroundColor(isTotal ? .primary : .secondary)
            
            Spacer()
            
            Text(String(format: "$%.2f", amount))
                .font(isTotal ? .headline : .subheadline)
                .fontWeight(isTotal ? .semibold : .medium)
                .foregroundColor(
                    isDiscount ? .green :
                    isLateFee ? .red :
                    isTotal ? .primary : .secondary
                )
        }
    }
}

struct LineItemRow: View {
    let item: InvoiceLineItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(String(format: "$%.2f", item.total_price))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            HStack {
                Text("Qty: \(item.quantity) × $\(String(format: "%.2f", item.unit_price))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let employeeName = item.employee_name {
                    Text(employeeName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Data Models
struct DetailedInvoice: Codable {
    let id: Int
    let invoice_number: String
    let status: String
    let issue_date: String
    let due_date: String
    let total_amount: Double
    let subtotal: Double
    let tax_amount: Double
    let discount_amount: Double
    let late_fee: Double
    let currency: String
    let billing_period_start: String?
    let billing_period_end: String?
    let billing_period_display: String?
    let total_employees: Int?
    let payroll_processing_fee: Double?
    let hr_services_fee: Double?
    let benefits_administration_fee: Double?
    let overdue: Bool
    let days_overdue: Int
    let line_items: [InvoiceLineItem]
    let created_at: String
    let updated_at: String
}

struct InvoiceLineItem: Codable {
    let id: Int
    let description: String
    let quantity: Int
    let unit_price: Double
    let total_price: Double
    let line_item_type: String?
    let service_category: String?
    let employee_name: String?
    let employee_id: String?
    let service_date: String?
}

struct InvoiceTotalCard: View {
    let invoice: DetailedInvoice
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Invoice Total")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.merotBlue)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Subtotal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "$%.2f", invoice.subtotal))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                if invoice.tax_amount > 0 {
                    HStack {
                        Text("Tax")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "$%.2f", invoice.tax_amount))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                
                if invoice.discount_amount > 0 {
                    HStack {
                        Text("Discount")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "-$%.2f", invoice.discount_amount))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
                
                if invoice.late_fee > 0 {
                    HStack {
                        Text("Late Fee")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "$%.2f", invoice.late_fee))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    }
                }
                
                Divider()
                
                HStack {
                    Text("Total Amount")
                        .font(.title3)
                        .fontWeight(.bold)
                    Spacer()
                    Text(String(format: "$%.2f", invoice.total_amount))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.merotBlue)
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
}

struct BasicInvoiceTotalCard: View {
    let invoice: Invoice
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Invoice Total")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.merotBlue)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Subtotal")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "$%.2f", invoice.subtotal))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                if invoice.tax_amount > 0 {
                    HStack {
                        Text("Tax")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "$%.2f", invoice.tax_amount))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                
                Divider()
                
                HStack {
                    Text("Total Amount")
                        .font(.title3)
                        .fontWeight(.bold)
                    Spacer()
                    Text(String(format: "$%.2f", invoice.total_amount))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.merotBlue)
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
}

#Preview {
    InvoiceDetailView(invoice: Invoice(
        id: 1,
        invoice_number: "INV-2025-001",
        status: "sent",
        issue_date: "2025-07-01T00:00:00Z",
        due_date: "2025-07-15T00:00:00Z",
        total_amount: 1500.00,
        subtotal: 1350.00,
        tax_amount: 150.00,
        currency: "USD",
        billing_period_start: "2025-06-01",
        billing_period_end: "2025-06-30",
        billing_period_display: "June 2025",
        overdue: false,
        days_overdue: 0,
        created_at: "2025-07-01T00:00:00Z",
        updated_at: "2025-07-01T00:00:00Z"
    ))
}