import Foundation

class APIService: ObservableObject {
    static let shared = APIService()
    private let networkManager = NetworkManager.shared
    
    func getDashboard() async throws -> DashboardData {
        let response: APIResponse<DashboardData> = try await networkManager.get(
            endpoint: "/employers/dashboard",
            responseType: APIResponse<DashboardData>.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.serverError(response.message)
        }
        
        return response.data
    }
    
    func getEmployerProfile() async throws -> Employer {
        let response: APIResponse<UserProfileWrapper> = try await networkManager.get(
            endpoint: "/employers/profile",
            responseType: APIResponse<UserProfileWrapper>.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.serverError(response.message)
        }
        
        return response.data.user.employer
    }
    
    func updateEmployerProfile(_ employer: Employer) async throws -> Employer {
        let updateRequest = ["employer": employer]
        
        let response: APIResponse<Employer> = try await networkManager.put(
            endpoint: "/employers/profile",
            body: updateRequest,
            responseType: APIResponse<Employer>.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.serverError(response.message)
        }
        
        return response.data
    }
    
    func getEmployees(
        page: Int = 1,
        perPage: Int = 20,
        status: String? = nil,
        search: String? = nil
    ) async throws -> EmployeeListResponse {
        var endpoint = "/employees?page=\(page)&per_page=\(perPage)"
        
        if let status = status {
            endpoint += "&status=\(status)"
        }
        
        if let search = search, !search.isEmpty {
            endpoint += "&search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        
        let response: APIResponse<EmployeeListData> = try await networkManager.get(
            endpoint: endpoint,
            responseType: APIResponse<EmployeeListData>.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.serverError(response.message)
        }
        
        return EmployeeListResponse(
            employees: response.data.employees,
            pagination: response.data.pagination
        )
    }
    
    func getEmployee(id: Int) async throws -> Employee {
        let response: APIResponse<Employee> = try await networkManager.get(
            endpoint: "/employees/\(id)",
            responseType: APIResponse<Employee>.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.serverError(response.message)
        }
        
        return response.data
    }
    
    func updateEmployee(id: Int, employee: Employee) async throws -> Employee {
        let updateRequest = ["employee": employee]
        
        let response: APIResponse<Employee> = try await networkManager.put(
            endpoint: "/employees/\(id)",
            body: updateRequest,
            responseType: APIResponse<Employee>.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.serverError(response.message)
        }
        
        return response.data
    }
    
    func getTimeOffRequests(
        page: Int = 1,
        perPage: Int = 20,
        status: String? = nil,
        employeeId: Int? = nil,
        startDate: String? = nil,
        endDate: String? = nil
    ) async throws -> [TimeOffRequest] {
        var endpoint = "/time_off_requests?page=\(page)&per_page=\(perPage)"
        
        if let status = status {
            endpoint += "&status=\(status)"
        }
        
        if let employeeId = employeeId {
            endpoint += "&employee_id=\(employeeId)"
        }
        
        if let startDate = startDate {
            endpoint += "&start_date=\(startDate)"
        }
        
        if let endDate = endDate {
            endpoint += "&end_date=\(endDate)"
        }
        
        let response: APIResponse<TimeOffRequestListData> = try await networkManager.get(
            endpoint: endpoint,
            responseType: APIResponse<TimeOffRequestListData>.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.serverError(response.message)
        }
        
        return response.data.timeOffRequests
    }
    
    func getTimeOffRequest(id: Int) async throws -> TimeOffRequest {
        let response: APIResponse<TimeOffRequest> = try await networkManager.get(
            endpoint: "/time_off_requests/\(id)",
            responseType: APIResponse<TimeOffRequest>.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.serverError(response.message)
        }
        
        return response.data
    }
    
    func approveTimeOffRequest(id: Int) async throws -> TimeOffRequest {
        let emptyBody: [String: String] = [:]
        let response: APIResponse<TimeOffRequestResponse> = try await networkManager.put(
            endpoint: "/time_off_requests/\(id)/approve",
            body: emptyBody,
            responseType: APIResponse<TimeOffRequestResponse>.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.serverError(response.message)
        }
        
        return response.data.timeOffRequest
    }
    
    func denyTimeOffRequest(id: Int) async throws -> TimeOffRequest {
        let emptyBody: [String: String] = [:]
        let response: APIResponse<TimeOffRequestResponse> = try await networkManager.put(
            endpoint: "/time_off_requests/\(id)/deny",
            body: emptyBody,
            responseType: APIResponse<TimeOffRequestResponse>.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.serverError(response.message)
        }
        
        return response.data.timeOffRequest
    }
    
    func getTimeOffStats() async throws -> TimeOffStats {
        let response: APIResponse<TimeOffStats> = try await networkManager.get(
            endpoint: "/time_off_requests/stats",
            responseType: APIResponse<TimeOffStats>.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.serverError(response.message)
        }
        
        return response.data
    }
    
    func getAnalyticsOverview(
        startDate: String? = nil,
        endDate: String? = nil
    ) async throws -> AnalyticsOverview {
        var endpoint = "/analytics/overview"
        
        var params: [String] = []
        if let startDate = startDate {
            params.append("start_date=\(startDate)")
        }
        if let endDate = endDate {
            params.append("end_date=\(endDate)")
        }
        
        if !params.isEmpty {
            endpoint += "?" + params.joined(separator: "&")
        }
        
        let response: APIResponse<AnalyticsOverview> = try await networkManager.get(
            endpoint: endpoint,
            responseType: APIResponse<AnalyticsOverview>.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.serverError(response.message)
        }
        
        return response.data
    }
    
    func getEmployeeAnalytics() async throws -> AnalyticsOverview {
        let response: APIResponse<AnalyticsOverview> = try await networkManager.get(
            endpoint: "/analytics/employees",
            responseType: APIResponse<AnalyticsOverview>.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.serverError(response.message)
        }
        
        return response.data
    }
    
    // MARK: - Invoice methods
    func getInvoices(
        page: Int = 1,
        perPage: Int = 20,
        status: String? = nil
    ) async throws -> [Invoice] {
        var endpoint = "/invoices?page=\(page)&per_page=\(perPage)"
        
        if let status = status {
            endpoint += "&status=\(status)"
        }
        
        let response: APIResponse<InvoiceListResponse> = try await networkManager.get(
            endpoint: endpoint,
            responseType: APIResponse<InvoiceListResponse>.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.serverError(response.message)
        }
        
        return response.data.invoices
    }
    
    func getInvoiceDetails(id: Int) async throws -> DetailedInvoice {
        let response: APIResponse<InvoiceDetailResponse> = try await networkManager.get(
            endpoint: "/invoices/\(id)",
            responseType: APIResponse<InvoiceDetailResponse>.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.serverError(response.message)
        }
        
        return response.data.invoice
    }
    
    func downloadInvoicePDF(id: Int) async throws -> Data {
        guard let url = URL(string: "\(NetworkManager.shared.baseURL)/invoices/\(id)/download_pdf") else {
            throw NetworkManager.NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/pdf", forHTTPHeaderField: "Accept")
        
        // Add authorization token
        if let token = UserDefaults.standard.string(forKey: "jwt_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkManager.NetworkError.networkError(URLError(.badServerResponse))
        }
        
        if httpResponse.statusCode == 401 {
            throw NetworkManager.NetworkError.authenticationError
        }
        
        if httpResponse.statusCode >= 400 {
            throw NetworkManager.NetworkError.serverError("HTTP \(httpResponse.statusCode)")
        }
        
        return data
    }
    
    // MARK: - Holiday Methods
    func getHolidays() async throws -> HolidaysResponse {
        let response: APIResponse<HolidaysResponse> = try await networkManager.get(
            endpoint: "/holidays",
            responseType: APIResponse<HolidaysResponse>.self
        )
        
        if response.success {
            return response.data
        } else {
            throw NetworkManager.NetworkError.serverError(response.message)
        }
    }
    
    // MARK: - Callback-based methods for compatibility
    func fetchEmployerProfile(completion: @escaping (Result<EmployerProfileData, Error>) -> Void) {
        Task {
            do {
                let response: APIResponse<EmployerProfileData> = try await networkManager.get(
                    endpoint: "/employers/profile",
                    responseType: APIResponse<EmployerProfileData>.self
                )
                
                if response.success {
                    completion(.success(response.data))
                } else {
                    completion(.failure(NetworkManager.NetworkError.serverError(response.message)))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
}

// MARK: - Invoice Response Types
struct InvoiceDetailResponse: Codable {
    let invoice: DetailedInvoice
}