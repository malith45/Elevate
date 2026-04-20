import SwiftUI
import MapKit

struct ManagerJobDetailsView: View {
    let jobId: String

    @Environment(\.managerTabRouter) private var router
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = JobDetailsViewModel()
    @ObservedObject private var network = NetworkService.shared
    @ObservedObject var settings = AccessibilitySettings.shared
    @State private var reportCount = 0
    @State private var cameraPosition: MapCameraPosition = .automatic

    private let localStorage = LocalStorageService.shared

    var body: some View {
        ZStack {
            settings.appBackground.ignoresSafeArea()

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
                                    .foregroundColor(settings.primaryText)

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
                                    .background(settings.isHighContrast ? Color.black : Color.red.opacity(0.1))
                                    .foregroundColor(settings.isHighContrast ? .white : .red)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }

                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("PROJECT SITE")
                                        .scaledFont(size: 10, weight: .bold)
                                        .foregroundColor(settings.secondaryText)
                                    Text(job.location)
                                        .scaledFont(size: 24, weight: .bold)
                                        .foregroundColor(settings.accentColor)
                                }
                                Spacer()
                                Text("ID\n\(String(job.id.prefix(8)).uppercased())")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(settings.primaryText)
                                    .multilineTextAlignment(.leading)
                                    .padding(12)
                                    .background(settings.isHighContrast ? Color.black : Color.elevateLightGray)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(settings.cardStroke, lineWidth: settings.isHighContrast ? 1 : 0)
                                    )
                            }

                            Text(job.notes ?? "No description provided.")
                                .scaledFont(size: 14)
                                .foregroundColor(settings.primaryText.opacity(0.8))

                            Text("Assigned: \(viewModel.assignedTechnician?.displayName ?? job.assignedUserId)")
                                .scaledFont(size: 12, weight: .bold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(settings.isHighContrast ? Color.black : Color.elevateLightGray)
                                .foregroundColor(settings.primaryText)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(settings.cardStroke, lineWidth: settings.isHighContrast ? 1 : 0)
                                )

                            ZStack(alignment: .bottomTrailing) {
                                if let siteLat = viewModel.job?.siteLatitude, let siteLon = viewModel.job?.siteLongitude {
                                    let siteCoord = CLLocationCoordinate2D(latitude: siteLat, longitude: siteLon)
                                    
                                    Map(position: $cameraPosition) {
                                        Marker("Site", systemImage: "mappin.circle.fill", coordinate: siteCoord)
                                            .tint(Color.elevateDarkGreen)
                                        
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
                                        .foregroundColor(settings.secondaryText)
                                }
                            }

                            VStack(spacing: 12) {
                                HStack(spacing: 12) {
                                    Button(action: { updateStatus(jobId: job.id, status: "HOLD") }) {
                                        Text("Hold Job")
                                            .scaledFont(size: 14, weight: .bold)
                                            .foregroundColor(settings.isHighContrast ? .white : .elevateDarkGreen)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .background(settings.isHighContrast ? Color.black : Color.elevateLightGray)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: settings.isHighContrast ? 1 : 0)
                                            )
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
                                        .background(settings.isHighContrast ? Color.black : Color.elevateDarkGreen)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 2)
                                        )
                                }
                            }
                        } else {
                            Text("Loading job details...")
                                .scaledFont(size: 14)
                                .foregroundColor(settings.secondaryText)
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
        .foregroundColor(settings.isHighContrast ? (title.contains("Site") ? settings.accentColor : .blue) : settings.accentColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(settings.isHighContrast ? Color.black : Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 1)
        )
    }
}

#Preview {
    ManagerJobDetailsView(jobId: "sample")
        .environmentObject(AppSession())
}
