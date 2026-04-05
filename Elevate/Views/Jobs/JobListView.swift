import SwiftUI

struct JobListView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTab: TechnicianDashboardView.TabItem = .jobs
    @State private var selectedFilter = 0
    
    var body: some View {
        ZStack {
            Color.elevateLightGray.opacity(0.3).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Nav
                BrandHeaderNav(showOnlineStatus: false)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Filters Segment
                        HStack(spacing: 0) {
                            FilterButton(title: "Today", isSelected: selectedFilter == 0) { selectedFilter = 0 }
                            FilterButton(title: "Upcoming", isSelected: selectedFilter == 1) { selectedFilter = 1 }
                            FilterButton(title: "Completed", isSelected: selectedFilter == 2) { selectedFilter = 2 }
                        }
                        .padding(4)
                        .background(Color.elevateLightGray)
                        .cornerRadius(8)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CURRENT SCHEDULE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.elevateTextGray)
                                .textCase(.uppercase)
                            
                            Text("Wednesday, May 24")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.elevateDarkGreen)
                        }
                        .padding(.horizontal, 24)
                        
                        // Job Cards
                        VStack(spacing: 16) {
                            // In Progress Card
                            VStack(spacing: 16) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("IN PROGRESS")
                                            .font(.system(size: 10, weight: .bold))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.green.opacity(0.2))
                                            .foregroundColor(Color.elevateDarkGreen)
                                            .cornerRadius(12)
                                        
                                        Text("HVAC Calibration")
                                            .font(.system(size: 18, weight: .bold))
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("10:30 AM")
                                            .font(.system(size: 14, weight: .bold))
                                        Text("Est. 2h 30m")
                                            .font(.system(size: 10))
                                            .foregroundColor(.elevateTextGray)
                                    }
                                }
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "mappin.and.ellipse")
                                        .frame(width: 32, height: 32)
                                        .background(Color.elevateLightGray)
                                        .cornerRadius(8)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Grand Central Mall")
                                            .font(.system(size: 14, weight: .bold))
                                        Text("4th Floor, Service Area B")
                                            .font(.system(size: 12))
                                            .foregroundColor(.elevateTextGray)
                                    }
                                    Spacer()
                                }
                                
                                HStack(spacing: 12) {
                                    NavigationLink(destination: JobDetailsView()) {
                                        Text("Open Details")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .background(Color.elevateDarkGreen)
                                            .cornerRadius(8)
                                    }
                                    
                                    Button(action: {}) {
                                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.black)
                                            .frame(width: 48, height: 48)
                                            .background(Color.elevateLightGray)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            .padding(20)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.elevateDarkGreen, lineWidth: 4)
                                    .alignmentGuide(.leading) { $0[.leading] }
                            )
                            .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
                            .padding(.horizontal, 24)
                            
                            // Scheduled Card 1
                            JobScheduledCard(title: "Elevator Maintenance", time: "01:15 PM", location: "Skyline Office Plaza", desc: "Tower 2, Lifts 5-8", icon: "building.2.fill")
                            
                            // Scheduled Card 2
                            JobScheduledCard(title: "Fire Safety Inspection", time: "03:45 PM", location: "Metropolis Industrial", desc: "Warehouse 4, Zone A", icon: "building.fill")
                        }
                        
                        // Bottom Stats
                        HStack(spacing: 16) {
                            StatPill(icon: "checkmark.circle", value: "12", title: "JOBS COMPLETED", isPrimary: true)
                            StatPill(icon: "clock", value: "3", title: "PENDING JOBS", isPrimary: false)
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer().frame(height: 120)
                    }
                }
            }
            // Bottom Navbar Floating
            ReusableBottomNav(selectedTab: .constant(.jobs))
        }
        .navigationBarHidden(true)
    }
}

struct FilterButton: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(isSelected ? .elevateDarkGreen : .elevateTextGray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color.white : Color.clear)
                .cornerRadius(6)
                .shadow(color: isSelected ? Color.black.opacity(0.05) : Color.clear, radius: 2, x: 0, y: 1)
        }
    }
}

struct JobScheduledCard: View {
    var title: String
    var time: String
    var location: String
    var desc: String
    var icon: String
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("SCHEDULED")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.elevateLightGray)
                        .foregroundColor(.elevateTextGray)
                        .cornerRadius(12)
                    
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                }
                Spacer()
                Text(time)
                    .font(.system(size: 14, weight: .bold))
            }
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .frame(width: 32, height: 32)
                    .background(Color.elevateLightGray)
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(location)
                        .font(.system(size: 14, weight: .bold))
                    Text(desc)
                        .font(.system(size: 12))
                        .foregroundColor(.elevateTextGray)
                }
                Spacer()
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 24)
    }
}

struct StatPill: View {
    var icon: String
    var value: String
    var title: String
    var isPrimary: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(isPrimary ? .white : .black)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(isPrimary ? .white : .black)
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isPrimary ? .white.opacity(0.8) : .elevateTextGray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(isPrimary ? Color.elevateDarkGreen : Color.elevateLightGray)
        .cornerRadius(12)
    }
}

#Preview {
    JobListView()
}
