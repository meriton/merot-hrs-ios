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
        let response: APIResponse<UserProfileWrapperForAPI> = try await networkManager.get(
            endpoint: "/employers/profile",
            responseType: APIResponse<UserProfileWrapperForAPI>.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.serverError(response.message)
        }
        
        guard let employer = response.data.user.employer else {
            throw NetworkManager.NetworkError.serverError("No employer profile found for this user")
        }
        return employer
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
        let response: APIResponse<AdminEmployeeResponse> = try await networkManager.get(
            endpoint: "/employees/\(id)",
            responseType: APIResponse<AdminEmployeeResponse>.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.serverError(response.message)
        }
        
        return response.data.employee
    }
    
    func updateEmployee(id: Int, employee: Employee) async throws -> Employee {
        let updateRequest = ["employee": employee]
        
        let response: APIResponse<AdminEmployeeResponse> = try await networkManager.put(
            endpoint: "/employees/\(id)",
            body: updateRequest,
            responseType: APIResponse<AdminEmployeeResponse>.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.serverError(response.message)
        }
        
        return response.data.employee
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
    
    func getDetailedEmployer(id: Int) async throws -> DetailedEmployerResponse {
        let response: APIResponse<DetailedEmployerResponse> = try await networkManager.get(
            endpoint: "/admin/employers/\(id)",
            responseType: APIResponse<DetailedEmployerResponse>.self
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
        // Check if current user is an admin and use appropriate endpoint
        let isAdmin = await isCurrentUserAdmin()
        let baseEndpoint = isAdmin ? "/admin/invoices" : "/invoices"
        var endpoint = "\(baseEndpoint)?page=\(page)&per_page=\(perPage)"
        
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
    
    private func isCurrentUserAdmin() async -> Bool {
        // Check if we have a cached user profile to determine admin status
        if UserDefaults.standard.string(forKey: "jwt_token") != nil {
            // Try to get current user profile to check admin status
            do {
                let response: APIResponse<UserProfileWrapperForAPI> = try await networkManager.get(
                    endpoint: "/auth/profile",
                    responseType: APIResponse<UserProfileWrapperForAPI>.self
                )
                
                // Check if user type indicates admin or if they have super admin status
                let userType = response.data.user.user_type.lowercased()
                let isSuperAdmin = response.data.user.super_admin ?? false
                let hasAdminRole = response.data.user.roles?.contains { $0.lowercased().contains("admin") } ?? false
                
                return userType == "admin" || 
                       userType == "user" || 
                       isSuperAdmin || 
                       hasAdminRole
            } catch {
                // If we can't determine user type, default to non-admin endpoint
                print("Failed to determine user admin status: \(error)")
                return false
            }
        }
        return false
    }
    
    func getInvoiceDetails(id: Int) async throws -> DetailedInvoice {
        // Check if current user is an admin and use appropriate endpoint
        let isAdmin = await isCurrentUserAdmin()
        let endpoint = isAdmin ? "/admin/invoices/\(id)" : "/invoices/\(id)"
        
        let response: APIResponse<InvoiceDetailResponse> = try await networkManager.get(
            endpoint: endpoint,
            responseType: APIResponse<InvoiceDetailResponse>.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.serverError(response.message)
        }
        
        return response.data.invoice
    }
    
    func downloadInvoicePDF(id: Int) async throws -> Data {
        // Check if current user is an admin and use appropriate endpoint
        let isAdmin = await isCurrentUserAdmin()
        let endpoint = isAdmin ? "/admin/invoices/\(id)/download_pdf" : "/invoices/\(id)/download_pdf"
        
        guard let url = URL(string: "\(NetworkManager.shared.baseURL)\(endpoint)") else {
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
    
    // MARK: - Job Postings Methods
    func getJobPostings(
        page: Int = 1,
        perPage: Int = 20,
        search: String? = nil,
        location: String? = nil,
        employmentType: String? = nil,
        experienceLevel: String? = nil,
        department: String? = nil
    ) async throws -> JobPostingsResponse {
        var endpoint = "/job_postings?page=\(page)&per_page=\(perPage)"
        
        if let search = search, !search.isEmpty {
            endpoint += "&search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        
        if let location = location, !location.isEmpty {
            endpoint += "&location=\(location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        
        if let employmentType = employmentType, !employmentType.isEmpty {
            endpoint += "&employment_type=\(employmentType)"
        }
        
        if let experienceLevel = experienceLevel, !experienceLevel.isEmpty {
            endpoint += "&experience_level=\(experienceLevel)"
        }
        
        if let department = department, !department.isEmpty {
            endpoint += "&department=\(department.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        
        let response: APIResponse<JobPostingsResponse> = try await networkManager.get(
            endpoint: "/admin\(endpoint)",
            responseType: APIResponse<JobPostingsResponse>.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.serverError(response.message)
        }
        
        return response.data
    }
    
    func getJobPosting(id: Int) async throws -> JobPosting {
        let response: APIResponse<JobPostingDetailResponse> = try await networkManager.get(
            endpoint: "/admin/job_postings/\(id)",
            responseType: APIResponse<JobPostingDetailResponse>.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.serverError(response.message)
        }
        
        return response.data.jobPosting
    }
    
    // MARK: - Admin API Methods
    
    func getAdminDashboard() async throws -> AdminDashboardData {
        let response: APIResponse<AdminDashboardResponse> = try await networkManager.get(
            endpoint: "/admin/dashboard",
            responseType: APIResponse<AdminDashboardResponse>.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.serverError(response.message)
        }
        
        return AdminDashboardData(
            stats: response.data.stats,
            recentEmployers: response.data.recentEmployers ?? [],
            systemAlerts: response.data.systemAlerts ?? []
        )
    }

    func getAdminStats() async throws -> AdminStats {
        let dashboardData = try await getAdminDashboard()
        return dashboardData.stats
    }
    
    func getAllEmployers(page: Int = 1, perPage: Int = 20, search: String? = nil) async throws -> AdminEmployersResponse {
        var endpoint = "/admin/employers?page=\(page)&per_page=\(perPage)"
        
        if let search = search, !search.isEmpty {
            endpoint += "&search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        
        let response: APIResponse<AdminEmployersResponse> = try await networkManager.get(
            endpoint: endpoint,
            responseType: APIResponse<AdminEmployersResponse>.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.serverError(response.message)
        }
        
        return response.data
    }
    
    func updateAdminEmployee(id: Int, employee: AdminEmployeeUpdateRequest) async throws -> Employee {
        // Create employee parameters without salary_detail
        let employeeData = AdminEmployeeUpdateRequestForAPI(
            firstName: employee.firstName,
            lastName: employee.lastName,
            email: employee.email,
            phoneNumber: employee.phoneNumber,
            personalEmail: employee.personalEmail,
            department: employee.department,
            status: employee.status,
            employeeType: employee.employeeType,
            title: employee.title,
            location: employee.location,
            address: employee.address,
            city: employee.city,
            country: employee.country,
            postcode: employee.postcode,
            personalIdNumber: employee.personalIdNumber,
            fullNameCyr: employee.fullNameCyr,
            cityCyr: employee.cityCyr,
            addressCyr: employee.addressCyr,
            countryCyr: employee.countryCyr
        )
        
        // Create the body with both employee and salary_detail
        let requestBody = AdminEmployeeUpdateBody(
            employee: employeeData,
            salaryDetail: employee.salaryDetail
        )
        
        let response: APIResponse<AdminEmployeeResponse> = try await networkManager.put(
            endpoint: "/admin/employees/\(id)",
            body: requestBody,
            responseType: APIResponse<AdminEmployeeResponse>.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.serverError(response.message)
        }
        
        return response.data.employee
    }
    
    func createAdminEmployee(employee: AdminEmployeeCreateRequest) async throws -> Employee {
        let response: APIResponse<AdminEmployeeResponse> = try await networkManager.post(
            endpoint: "/admin/employees",
            body: ["employee": employee],
            responseType: APIResponse<AdminEmployeeResponse>.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.serverError(response.message)
        }
        
        return response.data.employee
    }
    
    func lookupBankName(accountNumber: String, country: String) async throws -> BankNameLookupResponse {
        let request = BankNameLookupRequest(accountNumber: accountNumber, country: country)
        
        let response: APIResponse<BankNameLookupResponse> = try await networkManager.post(
            endpoint: "/admin/bank_name_lookup",
            body: request,
            responseType: APIResponse<BankNameLookupResponse>.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.serverError(response.message)
        }
        
        return response.data
    }
    
    func getAdminEmployee(id: Int) async throws -> Employee {
        let response: APIResponse<AdminEmployeeResponse> = try await networkManager.get(
            endpoint: "/admin/employees/\(id)",
            responseType: APIResponse<AdminEmployeeResponse>.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.serverError(response.message)
        }
        
        return response.data.employee
    }
    
    func getAllEmployees(page: Int = 1, perPage: Int = 20, search: String? = nil, status: String? = nil) async throws -> AdminEmployeesResponse {
        var endpoint = "/admin/employees?page=\(page)&per_page=\(perPage)"
        
        if let search = search, !search.isEmpty {
            endpoint += "&search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        
        if let status = status, !status.isEmpty {
            endpoint += "&status=\(status)"
        }
        
        let response: APIResponse<AdminEmployeesResponse> = try await networkManager.get(
            endpoint: endpoint,
            responseType: APIResponse<AdminEmployeesResponse>.self
        )
        
        guard response.success else {
            throw NetworkManager.NetworkError.serverError(response.message)
        }
        
        return response.data
    }
}

// MARK: - Response Types
struct InvoiceDetailResponse: Codable {
    let invoice: DetailedInvoice
}

struct JobPostingDetailResponse: Codable {
    let jobPosting: JobPosting
    
    enum CodingKeys: String, CodingKey {
        case jobPosting = "job_posting"
    }
}

struct AdminDashboardResponse: Codable {
    let stats: AdminStats
    let recentEmployers: [RecentEmployer]?
    let systemAlerts: [SystemAlert]?
    
    enum CodingKeys: String, CodingKey {
        case stats
        case recentEmployers = "recent_employers"
        case systemAlerts = "system_alerts"
    }
}



struct AdminEmployersResponse: Codable {
    let employers: [Employer]
    let pagination: PaginationInfo
}

struct AdminEmployeesResponse: Codable {
    let employees: [Employee]
    let pagination: PaginationInfo
}

struct AdminEmployeeResponse: Codable {
    let employee: Employee
}

struct AdminEmployeeUpdateRequest: Codable {
    let firstName: String?
    let lastName: String?
    let email: String?
    let phoneNumber: String?
    let personalEmail: String?
    let department: String?
    let status: String?
    let employeeType: String?
    let title: String?
    let location: String?
    let address: String?
    let city: String?
    let country: String?
    let postcode: String?
    let personalIdNumber: String?
    let fullNameCyr: String?
    let cityCyr: String?
    let addressCyr: String?
    let countryCyr: String?
    let salaryDetail: AdminSalaryDetailUpdateRequest?
    
    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case phoneNumber = "phone_number"
        case personalEmail = "personal_email"
        case department
        case status
        case employeeType = "employee_type"
        case title
        case location
        case address
        case city
        case country
        case postcode
        case personalIdNumber = "personal_id_number"
        case fullNameCyr = "full_name_cyr"
        case cityCyr = "city_cyr"
        case addressCyr = "address_cyr"
        case countryCyr = "country_cyr"
        case salaryDetail = "salary_detail"
    }
}

struct AdminSalaryDetailUpdateRequest: Codable {
    let baseSalary: Double?
    let hourlySalary: Double?
    let variableSalary: Double?
    let deductions: Double?
    let netSalary: Double?
    let grossSalary: Double?
    let seniority: Double?
    let bankName: String?
    let bankAccountNumber: String?
    let onMaternity: Bool?
    
    enum CodingKeys: String, CodingKey {
        case baseSalary = "base_salary"
        case hourlySalary = "hourly_salary"
        case variableSalary = "variable_salary"
        case deductions = "deductions"
        case netSalary = "net_salary"
        case grossSalary = "gross_salary"
        case seniority = "seniority"
        case bankName = "bank_name"
        case bankAccountNumber = "bank_account_number"
        case onMaternity = "on_maternity"
    }
}

struct AdminEmployeeUpdateRequestForAPI: Codable {
    let firstName: String?
    let lastName: String?
    let email: String?
    let phoneNumber: String?
    let personalEmail: String?
    let department: String?
    let status: String?
    let employeeType: String?
    let title: String?
    let location: String?
    let address: String?
    let city: String?
    let country: String?
    let postcode: String?
    let personalIdNumber: String?
    let fullNameCyr: String?
    let cityCyr: String?
    let addressCyr: String?
    let countryCyr: String?
    
    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case phoneNumber = "phone_number"
        case personalEmail = "personal_email"
        case department
        case status
        case employeeType = "employee_type"
        case title
        case location
        case address
        case city
        case country
        case postcode
        case personalIdNumber = "personal_id_number"
        case fullNameCyr = "full_name_cyr"
        case cityCyr = "city_cyr"
        case addressCyr = "address_cyr"
        case countryCyr = "country_cyr"
    }
}

struct AdminEmployeeUpdateBody: Codable {
    let employee: AdminEmployeeUpdateRequestForAPI
    let salaryDetail: AdminSalaryDetailUpdateRequest?
    
    enum CodingKeys: String, CodingKey {
        case employee
        case salaryDetail = "salary_detail"
    }
}

struct BankNameLookupRequest: Codable {
    let accountNumber: String
    let country: String
    
    enum CodingKeys: String, CodingKey {
        case accountNumber = "account_number"
        case country
    }
}

struct BankNameLookupResponse: Codable {
    let bankName: String
    let accountNumber: String
    let country: String
    
    enum CodingKeys: String, CodingKey {
        case bankName = "bank_name"
        case accountNumber = "account_number"
        case country
    }
}

struct AdminEmployeeCreateRequest: Codable {
    let firstName: String
    let lastName: String
    let email: String
    let password: String?
    let phoneNumber: String?
    let personalEmail: String?
    let department: String?
    let status: String?
    let employeeType: String?
    let title: String?
    let location: String?
    let address: String?
    let city: String?
    let country: String?
    let postcode: String?
    
    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case password
        case phoneNumber = "phone_number"
        case personalEmail = "personal_email"
        case department
        case status
        case employeeType = "employee_type"
        case title
        case location
        case address
        case city
        case country
        case postcode
    }
}

