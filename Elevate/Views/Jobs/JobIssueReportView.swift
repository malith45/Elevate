import SwiftUI
import UIKit

struct JobIssueReportView: View {
    let jobId: String

    @EnvironmentObject private var appSession: AppSession
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = JobIssueReportViewModel()
    @ObservedObject private var network = NetworkService.shared
    @State private var selectedTab: TabItem = .jobs
    @State private var showCamera = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Nav
                BackHeaderNav()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        
                        Text("Report Issue")
                            .scaledFont(size: 32, weight: .bold, design: .rounded)
                            .foregroundColor(.elevateDarkGreen)
                        
                        // Issue Description
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ISSUE DESCRIPTION")
                                .scaledFont(size: 10, weight: .bold)
                                .foregroundColor(.elevateTextGray)
                            
                            ZStack(alignment: .topLeading) {
                                if viewModel.issueText.isEmpty {
                                    Text("Describe the technical failure in detail...")
                                        .foregroundColor(Color.gray.opacity(0.8))
                                        .scaledFont(size: 16)
                                        .padding(.top, 16)
                                        .padding(.leading, 16)
                                }
                                TextEditor(text: $viewModel.issueText)
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
                                .scaledFont(size: 10, weight: .bold)
                                .foregroundColor(.elevateTextGray)
                            
                            HStack(spacing: 16) {
                                PriorityButton(title: "LOW", isSelected: viewModel.priority == "LOW") { viewModel.priority = "LOW" }
                                PriorityButton(title: "MEDIUM", isSelected: viewModel.priority == "MEDIUM") { viewModel.priority = "MEDIUM" }
                                PriorityButton(title: "HIGH", isSelected: viewModel.priority == "HIGH") { viewModel.priority = "HIGH" }
                            }
                        }
                        
                        // Photo Upload
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PHOTO UPLOAD")
                                .scaledFont(size: 10, weight: .bold)
                                .foregroundColor(.elevateTextGray)

                            if !viewModel.attachmentUrls.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(viewModel.attachmentUrls, id: \.self) { url in
                                            PhotoPreview(urlString: url)
                                                .frame(width: 80, height: 80)
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                            
                            HStack(spacing: 16) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray)
                                    .frame(width: 80, height: 80)
                                    .overlay(Image(systemName: "cpu").font(.system(size:30)).foregroundColor(.white))
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray)
                                    .frame(width: 80, height: 80)
                                    .overlay(Image(systemName: "cpu").font(.system(size:30)).foregroundColor(.white.opacity(0.5)))
                                
                                Button(action: { showCamera = true }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "camera.badge.ellipsis")
                                        Text("ADD PHOTO")
                                            .scaledFont(size: 10, weight: .bold)
                                    }
                                    .foregroundColor(.elevateTextGray)
                                    .frame(width: 80, height: 80)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(style: StrokeStyle(lineWidth: 1, dash: [4])).foregroundColor(.elevateTextGray))
                                }
                            }
                        }
                        
                        // Submit Button
                        Button(action: submitIssue) {
                            Text("SUBMIT REPORT")
                                .scaledFont(size: 16, weight: .bold)
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
        .sheet(isPresented: $showCamera) {
            CameraCaptureView(onCapture: { data in
                let fileName = "issue_\(jobId)_\(UUID().uuidString).jpg"
                viewModel.addAttachment(data: data, fileName: fileName)
            }, isPresented: $showCamera)
        }
        .alert("Issue Report", isPresented: Binding(
            get: { viewModel.errorMessage != nil || viewModel.didSubmit },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Report submitted successfully.")
        }
        .onChange(of: viewModel.didSubmit) { _, didSubmit in
            if didSubmit {
                HapticManager.shared.playNotification(type: .success)
            }
        }
    }

    private func submitIssue() {
        guard let user = appSession.currentUser else { return }
        viewModel.submit(jobId: jobId, user: user, isOnline: network.isOnline)
    }
}

struct PriorityButton: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .scaledFont(size: 12, weight: .bold)
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
    JobIssueReportView(jobId: "sample")
        .environmentObject(AppSession())
}
