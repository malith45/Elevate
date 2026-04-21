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
    @State private var showHoldPrompt = false
    @State private var holdReasonText = ""

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
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Job Details")
                                        .scaledFont(size: 28, weight: .bold, design: .rounded)
                                        .foregroundColor(settings.primaryText)
                                    Text(job.title)
                                        .scaledFont(size: 14, weight: .semibold)
                                        .foregroundColor(settings.secondaryText)
                                }

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
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(settings.isHighContrast ? settings.surfaceColor : Color.red.opacity(0.1))
                                    .foregroundColor(settings.isHighContrast ? settings.primaryText : .red)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                                    )
                                }
                                .buttonStyle(.plain)
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("PROJECT SITE")
                                            .scaledFont(size: 10, weight: .bold)
                                            .foregroundColor(settings.secondaryText)
                                        Text(job.location)
                                            .scaledFont(size: 22, weight: .bold)
                                            .foregroundColor(settings.accentColor)
                                    }
                                    Spacer()
                                    Text("ID\n\(String(job.id.prefix(8)).uppercased())")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(settings.primaryText)
                                        .multilineTextAlignment(.leading)
                                        .padding(10)
                                        .background(settings.isHighContrast ? settings.surfaceColor : Color.elevateLightGray)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                                        )
                                }

                                if let notes = job.notes, !notes.isEmpty {
                                    Text(notes)
                                        .scaledFont(size: 14)
                                        .foregroundColor(settings.primaryText.opacity(0.8))
                                } else {
                                    Text("No description provided.")
                                        .scaledFont(size: 14)
                                        .foregroundColor(settings.secondaryText)
                                }

                                HStack(spacing: 8) {
                                    Label("Assigned", systemImage: "person.fill")
                                        .scaledFont(size: 11, weight: .bold)
                                        .foregroundColor(settings.secondaryText)
                                    Spacer()
                                    Text(viewModel.assignedTechnician?.displayName ?? job.assignedUserId)
                                        .scaledFont(size: 12, weight: .bold)
                                        .foregroundColor(settings.primaryText)
                                }
                            }
                            .padding(16)
                            .background(settings.surfaceColor)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                            )

                            VStack(alignment: .leading, spacing: 12) {
                                Text("LOCATION")
                                    .scaledFont(size: 12, weight: .bold)
                                    .foregroundColor(settings.secondaryText)

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
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
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
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(LinearGradient(colors: [.elevateDarkGreen.opacity(0.85), .elevateDarkGreen.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                                .frame(height: 180)

                                            VStack(spacing: 8) {
                                                Image(systemName: "map.fill")
                                                    .font(.system(size: 36))
                                                    .foregroundColor(.white.opacity(0.4))
                                                Text("Location preview unavailable")
                                                    .scaledFont(size: 12, weight: .semibold)
                                                    .foregroundColor(.white.opacity(0.7))
                                            }
                                        }
                                    }
                                }
                            }

                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("APPROVED COST")
                                        .scaledFont(size: 10, weight: .bold)
                                        .foregroundColor(settings.secondaryText)

                                    Text(currencyString(job.approvedCost))
                                        .scaledFont(size: 18, weight: .bold)
                                        .foregroundColor(settings.accentColor)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(settings.surfaceColor)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                                )

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
                                    .padding(.vertical, 18)
                                    .background(settings.isHighContrast ? settings.surfaceColor : Color.elevateDarkGreen)
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                                    )
                                }
                                .buttonStyle(.plain)
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                Text("PHOTOS")
                                    .scaledFont(size: 12, weight: .bold)
                                    .foregroundColor(settings.secondaryText)

                                if !job.photoUrls.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(job.photoUrls, id: \.self) { url in
                                                PhotoPreview(urlString: url)
                                                    .frame(width: 88, height: 88)
                                                    .cornerRadius(12)
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
                                    Button(action: {
                                        holdReasonText = job.holdReason ?? ""
                                        showHoldPrompt = true
                                    }) {
                                        Text("Hold Job")
                                            .scaledFont(size: 14, weight: .bold)
                                            .foregroundColor(settings.isHighContrast ? settings.primaryText : settings.accentColor)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .background(settings.surfaceColor)
                                            .cornerRadius(14)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                                            )
                                    }

                                    Button(action: { updateStatus(jobId: job.id, status: "CANCELLED") }) {
                                        Text("Cancel Job")
                                            .scaledFont(size: 14, weight: .bold)
                                            .foregroundColor(.red)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .background(Color.red.opacity(0.1))
                                            .cornerRadius(14)
                                    }
                                }

                                Button(action: { updateStatus(jobId: job.id, status: "IN_PROGRESS") }) {
                                    Text("Update Job")
                                        .scaledFont(size: 16, weight: .bold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(settings.isHighContrast ? settings.surfaceColor : Color.elevateDarkGreen)
                                        .cornerRadius(14)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
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
        .alert("Hold Job", isPresented: $showHoldPrompt) {
            TextField("Reason (optional)", text: $holdReasonText)
            Button("Cancel", role: .cancel) {}
            Button("Place on Hold") {
                guard let job = viewModel.job else { return }
                updateStatus(jobId: job.id, status: "HOLD", holdReason: holdReasonText)
            }
        } message: {
            Text("Add a reason for placing this job on hold.")
        }
    }

    private func updateStatus(jobId: String, status: String, holdReason: String? = nil) {
        guard let user = appSession.currentUser else { return }
        viewModel.updateStatus(jobId: jobId, status: status, user: user, isOnline: network.isOnline, holdReasonOverride: holdReason)
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
        .foregroundColor(settings.isHighContrast ? settings.primaryText : settings.accentColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(settings.surfaceColor)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
    }
}

#Preview {
    ManagerJobDetailsView(jobId: "sample")
        .environmentObject(AppSession())
}
