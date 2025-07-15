import SwiftUI

struct HolidaysView: View {
    @StateObject private var apiService = APIService()
    @State private var holidaysData: HolidaysResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedCountry = "north_macedonia"
    
    private let countryOptions = [
        "north_macedonia": "North Macedonia",
        "kosovo": "Kosovo"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Country Filter
                VStack(spacing: 12) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(countryOptions.keys), id: \.self) { country in
                                CountryFilterChip(
                                    title: countryOptions[country] ?? country,
                                    isSelected: selectedCountry == country,
                                    action: {
                                        selectedCountry = country
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
                    ProgressView("Loading holidays...")
                    Spacer()
                } else if let errorMessage = errorMessage {
                    Spacer()
                    ErrorView(message: errorMessage) {
                        Task {
                            await loadHolidays()
                        }
                    }
                    Spacer()
                } else if let holidaysData = holidaysData {
                    // Holiday List
                    List {
                        let holidays = selectedCountry == "north_macedonia" ? 
                                      holidaysData.holidays.northMacedonia : 
                                      holidaysData.holidays.kosovo
                        
                        if holidays.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                
                                Text("No holidays found")
                                    .font(.headline)
                                
                                Text("No holidays scheduled for the selected period")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        } else {
                            ForEach(holidays) { holiday in
                                HolidayRow(holiday: holiday)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await refreshHolidays()
                    }
                }
            }
            .navigationTitle("Upcoming Holidays")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            Task {
                await loadHolidays()
            }
        }
    }
    
    private func loadHolidays() async {
        isLoading = true
        errorMessage = nil
        
        do {
            holidaysData = try await apiService.getHolidays()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func refreshHolidays() async {
        // Don't set isLoading = true for refresh to avoid UI conflicts
        errorMessage = nil
        
        do {
            holidaysData = try await apiService.getHolidays()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct CountryFilterChip: View {
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

struct HolidayRow: View {
    let holiday: Holiday
    
    var body: some View {
        HStack(spacing: 16) {
            // Date Circle
            VStack(spacing: 2) {
                Text(dayNumber)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(holiday.isWeekend ? .red : .primary)
                
                Text(monthAbbreviation)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            .frame(width: 50)
            
            // Holiday Details
            VStack(alignment: .leading, spacing: 4) {
                // Holiday Name and Weekend Icon
                HStack {
                    Text(holiday.name)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if holiday.isWeekend {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                    
                    Spacer()
                }
                
                // Day of week and Holiday Type Badge
                HStack(spacing: 8) {
                    Text(holiday.dayOfWeek)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HolidayTypeBadge(type: holiday.holidayType)
                }
                
                // Applicable Group (always reserve space)
                HStack {
                    if holiday.applicableGroup != "all" {
                        Text("Applicable to: \(holiday.applicableGroup.capitalized)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text(" ")
                            .font(.caption)
                            .foregroundColor(.clear)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: holiday.date) {
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "d"
            return dayFormatter.string(from: date)
        }
        
        return "?"
    }
    
    private var monthAbbreviation: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: holiday.date) {
            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "MMM"
            return monthFormatter.string(from: date).uppercased()
        }
        
        return "?"
    }
}

struct HolidayTypeBadge: View {
    let type: String
    
    var body: some View {
        Text(type.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(6)
    }
    
    private var backgroundColor: Color {
        switch type.lowercased() {
        case "national":
            return .blue.opacity(0.2)
        case "religious":
            return .purple.opacity(0.2)
        case "foreign":
            return .orange.opacity(0.2)
        default:
            return .gray.opacity(0.2)
        }
    }
    
    private var foregroundColor: Color {
        switch type.lowercased() {
        case "national":
            return .blue
        case "religious":
            return .purple
        case "foreign":
            return .orange
        default:
            return .gray
        }
    }
}