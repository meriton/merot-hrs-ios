import SwiftUI

struct DashboardContentView: View {
    let dashboardData: DashboardData?
    let isLoading: Bool
    let errorMessage: String?
    @Binding var selectedTab: Int
    @Binding var employeeFilter: String?
    let loadDashboard: () async -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("Loading dashboard...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let dashboardData = dashboardData {
                    DashboardStatsView(stats: dashboardData.stats, selectedTab: $selectedTab, employeeFilter: $employeeFilter)
                    
                    if let recentActivities = dashboardData.recentActivities {
                        RecentActivitiesView(activities: recentActivities)
                    }
                } else if let errorMessage = errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("Error loading dashboard")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Retry") {
                            Task {
                                await loadDashboard()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
            .padding()
        }
        .refreshable {
            await loadDashboard()
        }
    }
}