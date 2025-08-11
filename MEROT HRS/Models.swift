import Foundation

struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let message: String
    let data: T
    let errors: [String]?
}

struct APIErrorResponse: Codable {
    let success: Bool
    let message: String
    let errors: [String]?
}


struct PaginationInfo: Codable {
    let currentPage: Int
    let perPage: Int
    let totalCount: Int
    let totalPages: Int
    
    enum CodingKeys: String, CodingKey {
        case currentPage = "current_page"
        case perPage = "per_page"
        case totalCount = "total_count"
        case totalPages = "total_pages"
    }
}

struct User: Codable, Identifiable {
    let id: Int
    let email: String
    let userType: String
    let employer: Employer?
    let fullName: String?
    let roles: [String]?
    let superAdmin: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, email, employer, roles
        case userType = "user_type"
        case fullName = "full_name"
        case superAdmin = "super_admin"
    }
}

struct UserProfileWrapper: Decodable {
    let user: User
}

struct UserProfileWrapperForAPI: Decodable {
    let user: UserProfileForAPI
}

struct UserProfileForAPI: Decodable {
    let id: Int
    let email: String
    let user_type: String
    let employer: Employer
}

struct Employer: Codable, Identifiable {
    let id: Int?
    let name: String?
    let legalName: String?
    let primaryEmail: String?
    let billingEmail: String?
    let contactEmail: String?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case legalName = "legal_name"
        case primaryEmail = "primary_email"
        case billingEmail = "billing_email"
        case contactEmail = "contact_email"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct Employee: Codable, Identifiable {
    let id: Int
    let employeeId: String?
    let fullName: String
    let firstName: String?
    let lastName: String?
    let email: String
    let phoneNumber: String?
    let personalEmail: String?
    let department: String?
    let status: String
    let onLeave: String?
    let employeeType: String?
    let title: String?
    let location: String?
    let address: String?
    let city: String?
    let country: String?
    let postcode: String?
    let managerId: String?
    let personalIdNumber: String?
    let fullNameCyr: String?
    let cityCyr: String?
    let addressCyr: String?
    let countryCyr: String?
    let createdAt: Date
    let updatedAt: Date?
    let employment: Employment?
    let salaryDetail: SalaryDetail?
    let employers: [EmployerInfo]?
    
    enum CodingKeys: String, CodingKey {
        case id, email, department, status, title, location, employment, address, city, country, postcode, employers
        case employeeId = "employee_id"
        case fullName = "full_name"
        case firstName = "first_name"
        case lastName = "last_name"
        case phoneNumber = "phone_number"
        case personalEmail = "personal_email"
        case onLeave = "on_leave"
        case employeeType = "employee_type"
        case managerId = "manager_id"
        case personalIdNumber = "personal_id_number"
        case fullNameCyr = "full_name_cyr"
        case cityCyr = "city_cyr"
        case addressCyr = "address_cyr"
        case countryCyr = "country_cyr"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case salaryDetail = "salary_detail"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        employeeId = try container.decodeIfPresent(String.self, forKey: .employeeId)
        fullName = try container.decode(String.self, forKey: .fullName)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        email = try container.decode(String.self, forKey: .email)
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        personalEmail = try container.decodeIfPresent(String.self, forKey: .personalEmail)
        department = try container.decodeIfPresent(String.self, forKey: .department)
        status = try container.decode(String.self, forKey: .status)
        onLeave = try container.decodeIfPresent(String.self, forKey: .onLeave)
        employeeType = try container.decodeIfPresent(String.self, forKey: .employeeType)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        city = try container.decodeIfPresent(String.self, forKey: .city)
        country = try container.decodeIfPresent(String.self, forKey: .country)
        postcode = try container.decodeIfPresent(String.self, forKey: .postcode)
        managerId = try container.decodeIfPresent(String.self, forKey: .managerId)
        personalIdNumber = try container.decodeIfPresent(String.self, forKey: .personalIdNumber)
        fullNameCyr = try container.decodeIfPresent(String.self, forKey: .fullNameCyr)
        cityCyr = try container.decodeIfPresent(String.self, forKey: .cityCyr)
        addressCyr = try container.decodeIfPresent(String.self, forKey: .addressCyr)
        countryCyr = try container.decodeIfPresent(String.self, forKey: .countryCyr)
        employment = try container.decodeIfPresent(Employment.self, forKey: .employment)
        salaryDetail = try container.decodeIfPresent(SalaryDetail.self, forKey: .salaryDetail)
        employers = try container.decodeIfPresent([EmployerInfo].self, forKey: .employers)
        
        // Handle date decoding
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        
        // Use DateFormatter for more flexible parsing
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        if let date = formatter.date(from: createdAtString) {
            createdAt = date
        } else {
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            createdAt = formatter.date(from: createdAtString) ?? Date()
        }
        
        if let updatedAtString = updatedAtString {
            if let date = formatter.date(from: updatedAtString) {
                updatedAt = date
            } else {
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                updatedAt = formatter.date(from: updatedAtString)
            }
        } else {
            updatedAt = nil
        }
    }
}

struct EmployerInfo: Codable, Identifiable {
    let id: Int
    let name: String
}

struct Employment: Codable, Identifiable {
    let id: Int
    let employmentPosition: String?
    let startDate: Date?
    let endDate: Date?
    let employmentStatus: String?
    let grossSalary: String?
    let employmentFee: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case employmentPosition = "employment_position"
        case startDate = "start_date"
        case endDate = "end_date"
        case employmentStatus = "employment_status"
        case grossSalary = "gross_salary"
        case employmentFee = "employment_fee"
    }
    
    var grossSalaryDouble: Double? {
        guard let grossSalary = grossSalary else { return nil }
        return Double(grossSalary)
    }
    
    var employmentFeeDouble: Double? {
        guard let employmentFee = employmentFee else { return nil }
        return Double(employmentFee)
    }
}

struct SalaryDetail: Codable, Identifiable {
    let id: Int
    let baseSalary: Double?
    let hourlySalary: Double?
    let variableSalary: Double?
    let deductions: Double?
    let grossSalary: Double?
    let netSalary: Double?
    let seniority: Double?
    let onMaternity: Bool?
    let bankName: String?
    let bankAccountNumber: String?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, seniority
        case baseSalary = "base_salary"
        case hourlySalary = "hourly_salary"
        case variableSalary = "variable_salary"
        case deductions = "deductions"
        case grossSalary = "gross_salary"
        case netSalary = "net_salary"
        case onMaternity = "on_maternity"
        case bankName = "bank_name"
        case bankAccountNumber = "bank_account_number"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        
        // Handle salary fields that might be strings or doubles
        if let baseSalaryString = try? container.decodeIfPresent(String.self, forKey: .baseSalary) {
            baseSalary = Double(baseSalaryString)
        } else {
            baseSalary = try container.decodeIfPresent(Double.self, forKey: .baseSalary)
        }
        
        if let hourlySalaryString = try? container.decodeIfPresent(String.self, forKey: .hourlySalary) {
            hourlySalary = Double(hourlySalaryString)
        } else {
            hourlySalary = try container.decodeIfPresent(Double.self, forKey: .hourlySalary)
        }
        
        if let variableSalaryString = try? container.decodeIfPresent(String.self, forKey: .variableSalary) {
            variableSalary = Double(variableSalaryString)
        } else {
            variableSalary = try container.decodeIfPresent(Double.self, forKey: .variableSalary)
        }
        
        if let deductionsString = try? container.decodeIfPresent(String.self, forKey: .deductions) {
            deductions = Double(deductionsString)
        } else {
            deductions = try container.decodeIfPresent(Double.self, forKey: .deductions)
        }
        
        if let grossSalaryString = try? container.decodeIfPresent(String.self, forKey: .grossSalary) {
            grossSalary = Double(grossSalaryString)
        } else {
            grossSalary = try container.decodeIfPresent(Double.self, forKey: .grossSalary)
        }
        
        if let netSalaryString = try? container.decodeIfPresent(String.self, forKey: .netSalary) {
            netSalary = Double(netSalaryString)
        } else {
            netSalary = try container.decodeIfPresent(Double.self, forKey: .netSalary)
        }
        
        if let seniorityString = try? container.decodeIfPresent(String.self, forKey: .seniority) {
            seniority = Double(seniorityString)
        } else {
            seniority = try container.decodeIfPresent(Double.self, forKey: .seniority)
        }
        onMaternity = try container.decodeIfPresent(Bool.self, forKey: .onMaternity)
        bankName = try container.decodeIfPresent(String.self, forKey: .bankName)
        bankAccountNumber = try container.decodeIfPresent(String.self, forKey: .bankAccountNumber)
        
        // Handle date decoding
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            if let date = formatter.date(from: createdAtString) {
                createdAt = date
            } else {
                // Try without fractional seconds
                formatter.formatOptions = [.withInternetDateTime]
                createdAt = formatter.date(from: createdAtString)
            }
        } else {
            createdAt = nil
        }
        
        if let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            if let date = formatter.date(from: updatedAtString) {
                updatedAt = date
            } else {
                // Try without fractional seconds
                formatter.formatOptions = [.withInternetDateTime]
                updatedAt = formatter.date(from: updatedAtString)
            }
        } else {
            updatedAt = nil
        }
    }
}

struct TimeOffRequest: Codable, Identifiable {
    let id: Int
    let startDate: String
    let endDate: String
    let days: Int
    let approvalStatus: String
    let employee: TimeOffEmployee
    let timeOffRecord: TimeOffRecord?
    let createdAt: String
    let updatedAt: String
    let approvedByUserId: Int?
    let approverType: String?
    let approvalBy: String?
    
    enum CodingKeys: String, CodingKey {
        case id, days, employee
        case startDate = "start_date"
        case endDate = "end_date"
        case approvalStatus = "approval_status"
        case timeOffRecord = "time_off_record"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case approvedByUserId = "approved_by_user_id"
        case approverType = "approver_type"
        case approvalBy = "approval_by"
    }
}

struct TimeOffEmployee: Codable, Identifiable {
    let id: Int
    let fullName: String
    let employeeId: String
    let department: String
    
    enum CodingKeys: String, CodingKey {
        case id, department
        case fullName = "full_name"
        case employeeId = "employee_id"
    }
}

struct TimeOffRecord: Codable, Identifiable {
    let id: Int
    let name: String
    let leaveType: String?
    let balance: Int?
    let totalDays: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, name, balance
        case leaveType = "leave_type"
        case totalDays = "total_days"
    }
}

struct DashboardData: Codable {
    let stats: DashboardStats
    let recentActivities: [DashboardActivity]
    
    enum CodingKeys: String, CodingKey {
        case stats
        case recentActivities = "recent_activities"
    }
}

struct DashboardStats: Codable {
    let totalEmployees: Int
    let activeEmployees: Int
    let pendingTimeOffRequests: Int
    let employeesOnLeaveToday: Int
    
    enum CodingKeys: String, CodingKey {
        case totalEmployees = "total_employees"
        case activeEmployees = "active_employees"
        case pendingTimeOffRequests = "pending_time_off_requests"
        case employeesOnLeaveToday = "employees_on_leave_today"
    }
}

struct DashboardActivity: Codable, Identifiable {
    let id: Int
    let type: String
    let employeeName: String
    let status: String
    let startDate: String?
    let endDate: String?
    let days: Int?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, type, status, days
        case employeeName = "employee_name"
        case startDate = "start_date"
        case endDate = "end_date"
        case createdAt = "created_at"
    }
}

struct EmployeeListResponse: Codable {
    let employees: [Employee]
    let pagination: PaginationInfo
}

struct EmployeeListData: Codable {
    let employees: [Employee]
    let pagination: PaginationInfo
}

struct TimeOffRequestListData: Codable {
    let timeOffRequests: [TimeOffRequest]
    let pagination: PaginationInfo
    
    enum CodingKeys: String, CodingKey {
        case timeOffRequests = "time_off_requests"
        case pagination
    }
}

struct TimeOffRequestResponse: Codable {
    let timeOffRequest: TimeOffRequest
    
    enum CodingKeys: String, CodingKey {
        case timeOffRequest = "time_off_request"
    }
}

struct TimeOffStats: Codable {
    let stats: TimeOffStatsData
    let employeesOnLeaveToday: [Employee]
    let upcomingLeave: [TimeOffRequest]
    
    enum CodingKeys: String, CodingKey {
        case stats
        case employeesOnLeaveToday = "employees_on_leave_today"
        case upcomingLeave = "upcoming_leave"
    }
}

struct TimeOffStatsData: Codable {
    let totalRequests: Int
    let pendingRequests: Int
    let approvedRequests: Int
    let deniedRequests: Int
    let employeesOnLeaveToday: Int
    let upcomingLeave: Int
    
    enum CodingKeys: String, CodingKey {
        case totalRequests = "total_requests"
        case pendingRequests = "pending_requests"
        case approvedRequests = "approved_requests"
        case deniedRequests = "denied_requests"
        case employeesOnLeaveToday = "employees_on_leave_today"
        case upcomingLeave = "upcoming_leave"
    }
}

struct AnalyticsOverview: Codable {
    let totalEmployees: Int
    let byStatus: [String: Int]
    let byDepartment: [String: Int]
    let byCountry: [String: Int]
    let recentHires: [Employee]
    let contractExpiries: [Employee]
    
    enum CodingKeys: String, CodingKey {
        case totalEmployees = "total_employees"
        case byStatus = "by_status"
        case byDepartment = "by_department"
        case byCountry = "by_country"
        case recentHires = "recent_hires"
        case contractExpiries = "contract_expiries"
    }
}

struct Holiday: Codable, Identifiable {
    let id: Int
    let name: String
    let date: String
    let holidayType: String
    let applicableGroup: String
    let applicableCountry: String
    let formattedDate: String
    let dayOfWeek: String
    let isWeekend: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, date
        case holidayType = "holiday_type"
        case applicableGroup = "applicable_group"
        case applicableCountry = "applicable_country"
        case formattedDate = "formatted_date"
        case dayOfWeek = "day_of_week"
        case isWeekend = "is_weekend"
    }
}

struct HolidaysResponse: Codable {
    let holidays: HolidaysByCountry
    let period: HolidayPeriod
}

struct HolidaysByCountry: Codable {
    let northMacedonia: [Holiday]
    let kosovo: [Holiday]
    
    enum CodingKeys: String, CodingKey {
        case northMacedonia = "north_macedonia"
        case kosovo
    }
}

struct HolidayPeriod: Codable {
    let startDate: String
    let endDate: String
    
    enum CodingKeys: String, CodingKey {
        case startDate = "start_date"
        case endDate = "end_date"
    }
}

// MARK: - Job Posting Models

struct JobPosting: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String
    let department: String?
    let location: String?
    let employmentType: String?
    let experienceLevel: String?
    let salaryMin: Double?
    let salaryMax: Double?
    let salaryCurrency: String?
    let salaryPeriod: String?
    let publishedAt: String
    let expiresAt: String?
    let employer: JobPostingEmployer
    let positionsAvailable: Int
    let positionsFilled: Int
    let requirements: String?
    let benefits: String?
    let viewsCount: Int?
    let applicationsCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, department, location, requirements, benefits, employer
        case employmentType = "employment_type"
        case experienceLevel = "experience_level"
        case salaryMin = "salary_min"
        case salaryMax = "salary_max"
        case salaryCurrency = "salary_currency"
        case salaryPeriod = "salary_period"
        case publishedAt = "published_at"
        case expiresAt = "expires_at"
        case positionsAvailable = "positions_available"
        case positionsFilled = "positions_filled"
        case viewsCount = "views_count"
        case applicationsCount = "applications_count"
    }
    
    // Memberwise initializer for creating instances programmatically
    init(id: Int, title: String, description: String, department: String? = nil, location: String? = nil, employmentType: String? = nil, experienceLevel: String? = nil, salaryMin: Double? = nil, salaryMax: Double? = nil, salaryCurrency: String? = nil, salaryPeriod: String? = nil, publishedAt: String, expiresAt: String? = nil, employer: JobPostingEmployer, positionsAvailable: Int, positionsFilled: Int, requirements: String? = nil, benefits: String? = nil, viewsCount: Int? = nil, applicationsCount: Int? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.department = department
        self.location = location
        self.employmentType = employmentType
        self.experienceLevel = experienceLevel
        self.salaryMin = salaryMin
        self.salaryMax = salaryMax
        self.salaryCurrency = salaryCurrency
        self.salaryPeriod = salaryPeriod
        self.publishedAt = publishedAt
        self.expiresAt = expiresAt
        self.employer = employer
        self.positionsAvailable = positionsAvailable
        self.positionsFilled = positionsFilled
        self.requirements = requirements
        self.benefits = benefits
        self.viewsCount = viewsCount
        self.applicationsCount = applicationsCount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        department = try container.decodeIfPresent(String.self, forKey: .department)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        employmentType = try container.decodeIfPresent(String.self, forKey: .employmentType)
        experienceLevel = try container.decodeIfPresent(String.self, forKey: .experienceLevel)
        salaryCurrency = try container.decodeIfPresent(String.self, forKey: .salaryCurrency)
        salaryPeriod = try container.decodeIfPresent(String.self, forKey: .salaryPeriod)
        publishedAt = try container.decode(String.self, forKey: .publishedAt)
        expiresAt = try container.decodeIfPresent(String.self, forKey: .expiresAt)
        employer = try container.decode(JobPostingEmployer.self, forKey: .employer)
        positionsAvailable = try container.decode(Int.self, forKey: .positionsAvailable)
        positionsFilled = try container.decode(Int.self, forKey: .positionsFilled)
        requirements = try container.decodeIfPresent(String.self, forKey: .requirements)
        benefits = try container.decodeIfPresent(String.self, forKey: .benefits)
        viewsCount = try container.decodeIfPresent(Int.self, forKey: .viewsCount)
        applicationsCount = try container.decodeIfPresent(Int.self, forKey: .applicationsCount)
        
        // Handle salary fields that might be strings or doubles
        if let salaryMinString = try container.decodeIfPresent(String.self, forKey: .salaryMin) {
            salaryMin = Double(salaryMinString)
        } else {
            salaryMin = try container.decodeIfPresent(Double.self, forKey: .salaryMin)
        }
        
        if let salaryMaxString = try container.decodeIfPresent(String.self, forKey: .salaryMax) {
            salaryMax = Double(salaryMaxString)
        } else {
            salaryMax = try container.decodeIfPresent(Double.self, forKey: .salaryMax)
        }
    }
}

struct JobPostingEmployer: Codable {
    let id: Int
    let name: String
    let location: String?
}

struct JobPostingsResponse: Codable {
    let jobPostings: [JobPosting]
    let pagination: PaginationInfo
    let filters: JobPostingFilters?
    
    enum CodingKeys: String, CodingKey {
        case jobPostings = "job_postings"
        case pagination, filters
    }
}

struct JobPostingFilters: Codable {
    let employmentTypes: [String]
    let experienceLevels: [String]
    let locations: [String]
    let departments: [String]
    
    enum CodingKeys: String, CodingKey {
        case employmentTypes = "employment_types"
        case experienceLevels = "experience_levels"
        case locations, departments
    }
}

struct AdminDashboardData: Codable {
    let stats: AdminStats
    let recentEmployers: [RecentEmployer]
    let systemAlerts: [SystemAlert]
    
    enum CodingKeys: String, CodingKey {
        case stats
        case recentEmployers = "recent_employers"
        case systemAlerts = "system_alerts"
    }
}

struct AdminStats: Codable {
    let totalEmployers: Int
    let activeEmployees: Int
    let activeInvoices: Int?
    let monthlyRevenue: Double?
    
    enum CodingKeys: String, CodingKey {
        case totalEmployers = "total_employers"
        case totalEmployees = "total_employees"
        case activeEmployees = "active_employees"
        case activeInvoices = "active_invoices"
        case monthlyRevenue = "monthly_revenue"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        totalEmployers = try container.decode(Int.self, forKey: .totalEmployers)
        activeInvoices = try container.decodeIfPresent(Int.self, forKey: .activeInvoices)
        monthlyRevenue = try container.decodeIfPresent(Double.self, forKey: .monthlyRevenue)
        
        // Handle both field names for backward compatibility
        if let activeEmployeesCount = try container.decodeIfPresent(Int.self, forKey: .activeEmployees) {
            activeEmployees = activeEmployeesCount
        } else if let totalEmployeesCount = try container.decodeIfPresent(Int.self, forKey: .totalEmployees) {
            activeEmployees = totalEmployeesCount
        } else {
            activeEmployees = 0
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(totalEmployers, forKey: .totalEmployers)
        try container.encode(activeEmployees, forKey: .activeEmployees)
        try container.encodeIfPresent(activeInvoices, forKey: .activeInvoices)
        try container.encodeIfPresent(monthlyRevenue, forKey: .monthlyRevenue)
    }
}

struct RecentEmployer: Codable, Identifiable {
    let id: Int
    let name: String
    let employeeCount: Int
    let status: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, status
        case employeeCount = "employee_count"
        case createdAt = "created_at"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        employeeCount = try container.decode(Int.self, forKey: .employeeCount)
        status = try container.decode(String.self, forKey: .status)
        
        // Handle createdAt with custom date parsing for better error handling
        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            print("RecentEmployer: Attempting to parse date string: \(createdAtString)")
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let date = formatter.date(from: createdAtString) {
                createdAt = date
                print("RecentEmployer: Successfully parsed date with fractional seconds")
            } else {
                // Fallback to a simpler ISO8601 format
                formatter.formatOptions = [.withInternetDateTime]
                if let date = formatter.date(from: createdAtString) {
                    createdAt = date
                    print("RecentEmployer: Successfully parsed date without fractional seconds")
                } else {
                    // Try basic date formats as fallbacks
                    let basicFormatter = DateFormatter()
                    basicFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                    if let date = basicFormatter.date(from: createdAtString) {
                        createdAt = date
                        print("RecentEmployer: Successfully parsed date with basic formatter")
                    } else {
                        // Last resort: use current date to prevent crash
                        print("RecentEmployer: Failed to parse date '\(createdAtString)', using current date")
                        createdAt = Date()
                    }
                }
            }
        } else {
            // If createdAt is missing, use current date to prevent crash
            print("RecentEmployer: createdAt field missing, using current date")
            createdAt = Date()
        }
    }
}

struct SystemAlert: Codable, Identifiable {
    let id: Int
    let type: String
    let message: String
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id, type, message
        case timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        type = try container.decode(String.self, forKey: .type)
        message = try container.decode(String.self, forKey: .message)
        
        // Handle timestamp with custom date parsing for better error handling
        if let timestampString = try container.decodeIfPresent(String.self, forKey: .timestamp) {
            print("SystemAlert: Attempting to parse timestamp string: \(timestampString)")
            
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            if let date = formatter.date(from: timestampString) {
                timestamp = date
                print("SystemAlert: Successfully parsed timestamp with fractional seconds")
            } else {
                // Fallback to a simpler ISO8601 format
                formatter.formatOptions = [.withInternetDateTime]
                if let date = formatter.date(from: timestampString) {
                    timestamp = date
                    print("SystemAlert: Successfully parsed timestamp without fractional seconds")
                } else {
                    // Try basic date formats as fallbacks
                    let basicFormatter = DateFormatter()
                    basicFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                    if let date = basicFormatter.date(from: timestampString) {
                        timestamp = date
                        print("SystemAlert: Successfully parsed timestamp with basic formatter")
                    } else {
                        // Last resort: use current date to prevent crash
                        print("SystemAlert: Failed to parse timestamp '\(timestampString)', using current date")
                        timestamp = Date()
                    }
                }
            }
        } else {
            // If timestamp is missing, use current date to prevent crash
            print("SystemAlert: timestamp field missing, using current date")
            timestamp = Date()
        }
    }
}