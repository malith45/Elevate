import SwiftUI

struct JobDetailsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTab: TechnicianDashboardView.TabItem = .jobs
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Nav
                BackHeaderNav()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        HStack {
                            Text("Job Details")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                            
                            Spacer()
                            
                            NavigationLink(destination: JobIssueReportView()) {
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                    Text("REPORT ISSUE")
                                }
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(12)
                            }
                        }
                        
                        // Site Info
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("PROJECT SITE")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.elevateTextGray)
                                Text("Skyline Office\nPlaza")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.elevateDarkGreen)
                            }
                            Spacer()
                            Text("REF-2024-\n0892")
                                .font(.system(size: 12, weight: .bold))
                                .multilineTextAlignment(.leading)
                                .padding(12)
                                .background(Color.elevateLightGray)
                                .cornerRadius(8)
                        }
                        
                        Text("Monthly elevator maintenance and safety inspection.")
                            .font(.system(size: 14))
                            .foregroundColor(.black.opacity(0.8))
                        
                        Text("Marcus V. • TECH-4092")
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.elevateLightGray)
                            .cornerRadius(16)
                        
                        // Map view block placeholder
                        ZStack(alignment: .bottomLeading) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.elevateDarkGreen.opacity(0.8))
                                .frame(height: 140)
                                .overlay(
                                    Image(systemName: "map.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.white.opacity(0.3))
                                )
                            
                            Circle()
                                .fill(Color.white)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(.elevateDarkGreen)
                                        .font(.system(size: 24))
                                )
                                .position(x: 180, y: 70) // roughly center
                            
                            Button(action: {}) {
                                Text("VIEW IN MAPS")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.elevateDarkGreen)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.white)
                                    .cornerRadius(8)
                            }
                            .padding(12)
                        }
                        .cornerRadius(12)
                        
                        // Cost and Quotation Block
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("APPROVED COST")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.elevateTextGray)
                                
                                Text("LKR 8,700")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.elevateDarkGreen)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.elevateLightGray, lineWidth: 1))
                            
                            NavigationLink(destination: QuotationStatusView()) {
                                VStack(spacing: 6) {
                                    Image(systemName: "doc.text.fill")
                                    Text("VIEW QUOTATION")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                                .background(Color.elevateDarkGreen)
                                .cornerRadius(12)
                            }
                        }
                        
                        // Photo Upload
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PHOTO UPLOAD")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.black.opacity(0.8))
                            
                            HStack(spacing: 16) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray)
                                    .frame(width: 80, height: 80)
                                    .overlay(Image(systemName: "cpu").font(.system(size:30)).foregroundColor(.white))
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray)
                                    .frame(width: 80, height: 80)
                                    .overlay(Image(systemName: "cpu").font(.system(size:30)).foregroundColor(.white.opacity(0.5)))
                                
                                Button(action: {}) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "camera.badge.ellipsis")
                                        Text("ADD PHOTO")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                    .foregroundColor(.elevateTextGray)
                                    .frame(width: 80, height: 80)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(style: StrokeStyle(lineWidth: 1, dash: [4])).foregroundColor(.elevateTextGray))
                                }
                            }
                        }
                        
                        // Actions
                        HStack(spacing: 16) {
                            Button(action: {}) {
                                Text("Update")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.elevateDarkGreen)
                                    .cornerRadius(12)
                            }
                            Button(action: {}) {
                                Text("Complete Job")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.elevateDarkGreen.opacity(0.8))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.elevateLightGray)
                                    .cornerRadius(12)
                            }
                        }
                        
                        Spacer().frame(height: 120)
                    }
                    .padding(.horizontal, 24)
                }
            }
            // Bottom Navbar Floating
            ReusableBottomNav(selectedTab: .constant(.jobs))
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    JobDetailsView()
}
