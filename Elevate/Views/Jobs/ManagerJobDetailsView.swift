import SwiftUI
import MapKit

struct ManagerJobDetailsView: View {
    let jobId: String

    @Environment(\.managerTabRouter) private var router
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = JobDetailsViewModel()
    @ObservedObject private var network = NetworkService.shared
    @State private var reportCount = 0
    @State private var cameraPosition: MapCameraPosition = .automatic

    private let localStorage = LocalStorageService.shared

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                BackHeaderNav(isManager: true, onBack: {
                    router.currentScreen = .jobs
                    router.selectedTab = .jobs
                })

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        if let job = viewModel.job {
                            HStack {
                                Text("Job Details")
                                    .scaledFont(size: 28, weight: .bold, design: .rounded)

                                Spacer()

                                Button(action: {
                                    router.currentScreen = .jobIssueReport
                                    router.selectedTab = .jobs
                                }) {
                                    HStack(spacing: 6) {
                                        ZStack(alignment: .topTrailing) {
                                            Image(systemName: "doc.text.magnifyingglass")
                                            if reportCount > 0 {
                                                Circle()
                                                    .fill(Color.red)
                                                    .frame(width: 8, height: 8)
                                                    .offset(x: 6, y: -4)
                                            }
                                        }
                                        Text("VIEW REPORTS")
                                    }
                                    .scaledFont(size: 10, weight: .bold)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.red.opacity(0.1))
                                    .foregroundColor(.red)
                                    .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                            }

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
                                Text("ID\n\(String(job.id.prefix(8)).uppercased())")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .multilineTextAlignment(.leading)
                                    .padding(12)
                                    .background(Color.elevateLightGray)
                                    .cornerRadius(8)
                            }

                            Text(job.notes ?? "No description provided.")
                                .scaledFont(size: 14)
                                .foregroundColor(.black.opacity(0.8))

                            Text("Assigned: \(viewModel.assignedTechnician?.displayName ?? job.assignedUserId)")
                                .scaledFont(size: 12, weight: .bold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.elevateLightGray)
                                .cornerRadius(16)

                            ZStack(alignment: .bottomTrailing) {
                                if let siteLat = viewModel.job?.siteLatitude, let siteLon = viewModel.job?.siteLongitude {
                                    let siteCoord = CLLocationCoordinate2D(latitude: siteLat, longitude: siteLon)
                                    
                                    Map(position: $cameraPosition) {
                                        Marker("Site", systemImage: "mappin.circle.fill", coordinate: siteCoord)
                                            .tint(.elevateDarkGreen)
                                        
                                        if let techCoord = viewModel.technicianLocation {
                                            Marker("Technician", systemImage: "person.circle.fill", coordinate: techCoord)
                                                .tint(.blue)
                                        }
                                    }
                                    .frame(height: 220)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(alignment: .topTrailing) {
                                        VStack(spacing: 8) {
                                            Button(action: {
                                                cameraPosition = .region(MKCoordinateRegion(center: siteCoord, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
                                            }) {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "mappin.circle.fill")
                                                    Text("SITE")
                                                }
                                                .scaledFont(size: 8, weight: .bold)
                                                .padding(6)
                                                .background(.ultraThinMaterial)
                                                .cornerRadius(8)
                                            }
                                            
                                            if let techCoord = viewModel.technicianLocation {
                                                Button(action: {
                                                    cameraPosition = .region(MKCoordinateRegion(center: techCoord, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
                                                }) {
                                                    HStack(spacing: 4) {
                                                        Image(systemName: "person.circle.fill")
                                                        Text("TECH")
                                                    }
                                                    .scaledFont(size: 8, weight: .bold)
                                                    .padding(6)
                                                    .background(.ultraThinMaterial)
                                                    .cornerRadius(8)
                                                }
                                            }
                                        }
                                        .padding(8)
                                    }
                                } else {
                                    // Improved Placeholder
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(LinearGradient(colors: [.elevateDarkGreen.opacity(0.85), .elevateDarkGreen.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(height: 160)
                                        
                                        VStack(spacing: 8) {
                                            Image(systemName: "map.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(.white.opacity(0.4))
                                            Text("Location preview unavailable")
                                                .scaledFont(size: 12, weight: .semibold)
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                    }
                                }
                            }

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

                                Button(action: {
                                    router.currentScreen = .quotationApproval
                                    router.selectedTab = .jobs
                                }) {
                                    VStack(spacing: 6) {
                                        Image(systemName: "doc.text.fill")
                                        Text("APPROVE QUOTATIONS")
                                            .multilineTextAlignment(.center)
                                            .scaledFont(size: 10, weight: .bold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                    .background(Color.elevateDarkGreen)
                                    .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                Text("PHOTO UPLOADS")
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
                                } else {
                                    Text("No photos submitted yet.")
                                        .scaledFont(size: 12)
                                        .foregroundColor(.elevateTextGray)
                                }
                            }

                            VStack(spacing: 12) {
                                HStack(spacing: 12) {
                                    Button(action: { updateStatus(jobId: job.id, status: "HOLD") }) {
                                        Text("Hold Job")
                                            .scaledFont(size: 14, weight: .bold)
                                            .foregroundColor(.elevateDarkGreen)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .background(Color.elevateLightGray)
                                            .cornerRadius(12)
                                    }

                                    Button(action: { updateStatus(jobId: job.id, status: "CANCELLED") }) {
                                        Text("Cancel Job")
                                            .scaledFont(size: 14, weight: .bold)
                                            .foregroundColor(.red)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .background(Color.red.opacity(0.1))
                                            .cornerRadius(12)
                                    }
                                }

                                Button(action: { updateStatus(jobId: job.id, status: "IN_PROGRESS") }) {
                                    Text("Update Job")
                                        .scaledFont(size: 16, weight: .bold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color.elevateDarkGreen)
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
                    .padding(.bottom, 24)
                    
                    Spacer().frame(height: 100)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.load(jobId: jobId)
            reportCount = localStorage.fetchIssueReports(jobId: jobId).count
        }
    }

    private func updateStatus(jobId: String, status: String) {
        guard let user = appSession.currentUser else { return }
        viewModel.updateStatus(jobId: jobId, status: status, user: user, isOnline: network.isOnline)
    }

    private func currencyString(_ value: Double?) -> String {
        let actualValue = value ?? 0.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "LKR"
        return formatter.string(from: NSNumber(value: actualValue)) ?? "LKR \(actualValue)"
    }

    private func legendPill(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(title)
                .scaledFont(size: 10, weight: .bold)
        }
        .foregroundColor(.elevateDarkGreen)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white)
        .cornerRadius(10)
    }
}

#Preview {
    ManagerJobDetailsView(jobId: "sample")
        .environmentObject(AppSession())
}
