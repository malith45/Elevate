import SwiftUI

struct JobIssueReportView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var issueText: String = ""
    @State private var priority: Int = 1 // 0: LOW, 1: MEDIUM, 2: HIGH
    @State private var selectedTab: TechnicianDashboardView.TabItem = .jobs
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Nav
                BackHeaderNav()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        
                        Text("Report Issue")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.elevateDarkGreen)
                        
                        // Issue Description
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ISSUE DESCRIPTION")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.elevateTextGray)
                            
                            ZStack(alignment: .topLeading) {
                                if issueText.isEmpty {
                                    Text("Describe the technical failure in detail...")
                                        .foregroundColor(Color.gray.opacity(0.8))
                                        .font(.system(size: 16))
                                        .padding(.top, 16)
                                        .padding(.leading, 16)
                                }
                                TextEditor(text: $issueText)
                                    .padding(8)
                                    .frame(height: 180)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.elevateLightGray, lineWidth: 1)
                                    )
                            }
                        }
                        
                        // Priority Level
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PRIORITY LEVEL")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.elevateTextGray)
                            
                            HStack(spacing: 16) {
                                PriorityButton(title: "LOW", isSelected: priority == 0) { priority = 0 }
                                PriorityButton(title: "MEDIUM", isSelected: priority == 1) { priority = 1 }
                                PriorityButton(title: "HIGH", isSelected: priority == 2) { priority = 2 }
                            }
                        }
                        
                        // Photo Upload
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PHOTO UPLOAD")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.elevateTextGray)
                            
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
                        
                        // Submit Button
                        Button(action: {}) {
                            Text("SUBMIT REPORT")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.elevateDarkGreen)
                                .cornerRadius(12)
                        }
                        .padding(.top, 16)
                        
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

struct PriorityButton: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(isSelected ? .white : .black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isSelected ? Color.elevateDarkGreen : Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.clear : Color.elevateLightGray, lineWidth: 1)
                )
                .shadow(color: isSelected ? Color.elevateDarkGreen.opacity(0.3) : Color.clear, radius: 5, x: 0, y: 3)
        }
    }
}

#Preview {
    JobIssueReportView()
}
