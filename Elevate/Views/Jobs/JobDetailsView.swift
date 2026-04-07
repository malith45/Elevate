import SwiftUI
import UIKit

struct JobDetailsView: View {
    let jobId: String

    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = JobDetailsViewModel()
    @ObservedObject private var network = NetworkService.shared
    @State private var showCamera = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Nav
                BackHeaderNav()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        if let job = viewModel.job {
                            // Header
                            HStack {
                                Text("Job Details")
                                    .scaledFont(size: 28, weight: .bold, design: .rounded)
                                
                                Spacer()
                                
                                NavigationLink(destination: JobIssueReportView(jobId: job.id)) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                        Text("REPORT ISSUE")
                                    }
                                    .scaledFont(size: 10, weight: .bold)
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
                                        .scaledFont(size: 10, weight: .bold)
                                        .foregroundColor(.elevateTextGray)
                                    Text(job.location)
                                        .scaledFont(size: 24, weight: .bold)
                                        .foregroundColor(.elevateDarkGreen)
                                }
                                Spacer()
                                Text("ID\n\(job.id)")
                                    .scaledFont(size: 12, weight: .bold)
                                    .multilineTextAlignment(.leading)
                                    .padding(12)
                                    .background(Color.elevateLightGray)
                                    .cornerRadius(8)
                            }
                            
                            Text(job.notes ?? "No description provided.")
                                .scaledFont(size: 14)
                                .foregroundColor(.black.opacity(0.8))
                            
                            Text("Assigned: \(job.assignedUserId)")
                                .scaledFont(size: 12, weight: .bold)
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
                                    .scaledFont(size: 10, weight: .bold)
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
                                    .scaledFont(size: 10, weight: .bold)
                                    .foregroundColor(.elevateTextGray)
                                
                                Text(currencyString(job.approvedCost))
                                    .scaledFont(size: 16, weight: .bold)
                                    .foregroundColor(.elevateDarkGreen)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.elevateLightGray, lineWidth: 1))
                            
                            NavigationLink(destination: QuotationStatusView(jobId: job.id)) {
                                VStack(spacing: 6) {
                                    Image(systemName: "doc.text.fill")
                                    Text("VIEW QUOTATION")
                                        .scaledFont(size: 10, weight: .bold)
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
                                .scaledFont(size: 12, weight: .bold)
                                .foregroundColor(.black.opacity(0.8))

                            if !job.photoUrls.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(job.photoUrls, id: \.self) { url in
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
                        
                        // Actions
                        HStack(spacing: 16) {
                            Button(action: { updateStatus(jobId: job.id, status: "IN_PROGRESS") }) {
                                Text("Update")
                                    .scaledFont(size: 16, weight: .bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.elevateDarkGreen)
                                    .cornerRadius(12)
                            }
                            Button(action: { updateStatus(jobId: job.id, status: "COMPLETED") }) {
                                Text("Complete Job")
                                    .scaledFont(size: 16, weight: .bold)
                                    .foregroundColor(.elevateDarkGreen.opacity(0.8))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.elevateLightGray)
                                    .cornerRadius(12)
                            }
                        }
                        
                        } else {
                            Text("Loading job details...")
                                .scaledFont(size: 14)
                                .foregroundColor(.elevateTextGray)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { viewModel.load(jobId: jobId) }
        .sheet(isPresented: $showCamera) {
            CameraCaptureView(onCapture: { data in
                viewModel.addPhoto(jobId: jobId, data: data, isOnline: network.isOnline)
            }, isPresented: $showCamera)
        }
    }

    private func updateStatus(jobId: String, status: String) {
        guard let user = appSession.currentUser else { return }
        viewModel.updateStatus(jobId: jobId, status: status, user: user, isOnline: network.isOnline)
    }

    private func currencyString(_ value: Double?) -> String {
        guard let value = value else { return "LKR -" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "LKR"
        return formatter.string(from: NSNumber(value: value)) ?? "LKR \(value)"
    }
}

#Preview {
    JobDetailsView(jobId: "sample")
        .environmentObject(AppSession())
}
