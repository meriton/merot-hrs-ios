# Employee Login Implementation Todo List

## Phase 1: Project Setup and Branch Management
- [x] Create comprehensive todo list in markdown file
- [ ] Switch Rails app to main branch and pull latest changes
- [ ] Switch iOS app to main branch and pull latest changes  
- [ ] Create new `users_login` branch on Rails app
- [ ] Create new `users_login` branch on iOS app

## Phase 2: Rails Backend - Employee API Implementation

### Authentication and API Structure
- [ ] Review existing employee authentication in Rails app
- [ ] Create/update Employee API namespace (`/api/employees/`)
- [ ] Implement employee authentication endpoints
- [ ] Add employee profile endpoint
- [ ] Test employee login API endpoints

### Time Off Management API
- [ ] Create employee time off requests endpoint (`GET /api/employees/time_off_requests`)
- [ ] Create time off request creation endpoint (`POST /api/employees/time_off_requests`)  
- [ ] Create time off balance endpoint (`GET /api/employees/time_off_balance`)
- [ ] Add proper serializers for time off data
- [ ] Test time off API endpoints

### Payroll/Paystubs API  
- [ ] Create employee paystubs endpoint (`GET /api/employees/paystubs`)
- [ ] Create paystub detail endpoint (`GET /api/employees/paystubs/:id`)
- [ ] Add proper serializers for payroll data
- [ ] Test paystub API endpoints

### Security and Authorization
- [ ] Ensure proper employee-only access controls
- [ ] Add employee user scope restrictions (employees can only see their own data)
- [ ] Add API authentication middleware for employee routes
- [ ] Test security and authorization

## Phase 3: iOS App - Employee Interface Implementation

### Login and Authentication
- [ ] Update login screen with user type selector (Admin/Employer/Employee)
- [ ] Update authentication service to handle employee login
- [ ] Add employee user type to AuthenticationService
- [ ] Create employee-specific API service methods
- [ ] Test employee login flow

### Employee Dashboard
- [ ] Create employee dashboard view
- [ ] Add time off balance display
- [ ] Add quick actions (request time off, view paystubs)
- [ ] Add navigation structure for employee users
- [ ] Test employee dashboard

### Time Off Management
- [ ] Create time off balance view
- [ ] Create time off request form
- [ ] Create time off requests list view
- [ ] Add request status indicators (pending, approved, denied)
- [ ] Implement time off request submission
- [ ] Test time off functionality

### Paystubs Management  
- [ ] Create paystubs list view
- [ ] Create paystub detail view
- [ ] Add paystub PDF download functionality
- [ ] Add proper date formatting and currency display
- [ ] Test paystubs functionality

### UI/UX Polish
- [ ] Add employee-specific color scheme/branding
- [ ] Add proper loading states and error handling
- [ ] Add pull-to-refresh functionality
- [ ] Add proper navigation and user experience flow
- [ ] Test complete employee user experience

## Phase 4: Integration and Testing

### End-to-End Testing
- [ ] Test complete employee login to logout flow
- [ ] Test all employee API endpoints with iOS app
- [ ] Test error handling and edge cases
- [ ] Test on different devices and orientations
- [ ] Performance testing for employee features

### Code Review and Cleanup
- [ ] Review Rails code for consistency and best practices
- [ ] Review iOS code for consistency and best practices  
- [ ] Add appropriate comments and documentation
- [ ] Clean up any unused code or files
- [ ] Update API documentation

### Deployment Preparation
- [ ] Test employee features in development environment
- [ ] Prepare for staging environment testing
- [ ] Create deployment checklist
- [ ] Document new employee features for stakeholders

## Phase 5: Final Polish and Documentation

### Documentation
- [ ] Update README files with employee login instructions
- [ ] Document new API endpoints
- [ ] Create user guide for employee features
- [ ] Update development setup instructions

### Final Testing and Review
- [ ] Complete manual testing of all employee features
- [ ] Review security implementation
- [ ] Final code review and cleanup
- [ ] Prepare for merge to main branch

---

## Key Employee Features Summary:
1. **Login**: Employee can login with employee credentials
2. **Time Off Balance**: View remaining vacation/sick days
3. **Time Off Requests**: Create new time off requests and view status
4. **Paystubs**: View and download paystub history
5. **Profile**: View basic employee profile information

## Technical Architecture:
- **Rails**: `/api/employees/` namespace for all employee endpoints
- **iOS**: Employee user type with dedicated dashboard and features
- **Authentication**: JWT-based authentication for employee users
- **Authorization**: Employee-scoped data access only