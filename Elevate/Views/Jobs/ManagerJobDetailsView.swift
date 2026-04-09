import SwiftUI
import MapKit

struct ManagerJobDetailsView: View {
    let jobId: String

    @Environment(\.managerTabRouter) private var router
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = JobDetailsViewModel()
    @ObservedObject private var network = NetworkService.shared
    @State private var reportCount = 0

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

                            ZStack(alignment: .bottomLeading) {
                                if let latitude = job.siteLatitude, let longitude = job.siteLongitude {
                                    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                                    let position = MapCameraPosition.region(
                                        MKCoordinateRegion(
                                            center: coordinate,
                                            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                                        )
                                    )
                                    Map(position: .constant(position)) {
                                        Marker("Site", coordinate: coordinate)
                                    }
                                    .frame(height: 150)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.elevateDarkGreen.opacity(0.8))
                                        .frame(height: 150)
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
                                        .position(x: 160, y: 60)

                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Image(systemName: "person.circle.fill")
                                                .foregroundColor(.elevateDarkGreen)
                                                .font(.system(size: 22))
                                        )
                                        .position(x: 240, y: 95)

                                    HStack(spacing: 12) {
                                        legendPill(title: "Site", icon: "mappin")
                                        legendPill(title: "Technician", icon: "person")
                                    }
                                    .padding(12)
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
        guard let value = value else { return "LKR -" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "LKR"
        return formatter.string(from: NSNumber(value: value)) ?? "LKR \(value)"
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
