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
    
    enum CodingKeys: String, CodingKey {
        case id, email, employer
        case userType = "user_type"
    }
}

struct UserProfileWrapper: Decodable {
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
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case legalName = "legal_name"
        case primaryEmail = "primary_email"
        case billingEmail = "billing_email"
        case contactEmail = "contact_email"
    }
}

struct Employee: Codable, Identifiable {
    let id: Int
    let employeeId: String?
    let fullName: String
    let firstName: String?
    let lastName: String?
    let email: String
    let department: String?
    let status: String
    let employeeType: String?
    let country: String?
    let title: String?
    let location: String?
    let phone: String?
    let createdAt: Date
    let employment: Employment?
    let salaryDetail: SalaryDetail?
    
    enum CodingKeys: String, CodingKey {
        case id, email, department, status, title, location, phone, employment
        case employeeId = "employee_id"
        case fullName = "full_name"
        case firstName = "first_name"
        case lastName = "last_name"
        case employeeType = "employee_type"
        case createdAt = "created_at"
        case salaryDetail = "salary_detail"
        case country
    }
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
    let grossSalary: Double?
    let netSalary: Double?
    let seniority: Double?
    let onMaternity: Bool?
    let bankName: String?
    let bankAccountNumber: String?
    
    enum CodingKeys: String, CodingKey {
        case id, seniority
        case baseSalary = "base_salary"
        case grossSalary = "gross_salary"
        case netSalary = "net_salary"
        case onMaternity = "on_maternity"
        case bankName = "bank_name"
        case bankAccountNumber = "bank_account_number"
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
        case id, days, employee, createdAt, updatedAt
        case startDate = "start_date"
        case endDate = "end_date"
        case approvalStatus = "approval_status"
        case timeOffRecord = "time_off_record"
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