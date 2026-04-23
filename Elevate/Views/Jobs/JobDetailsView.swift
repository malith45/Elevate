import SwiftUI
import UIKit
import MapKit

struct JobDetailsView: View {
    let jobId: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.technicianTabRouter) private var router
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = JobDetailsViewModel()
    @ObservedObject private var network = NetworkService.shared
    @ObservedObject var settings = AccessibilitySettings.shared
    @State private var showCamera = false
    @State private var showHoldPrompt = false
    @State private var holdReasonText = ""
    
    private var isTerminal: Bool {
        let status = viewModel.job?.status.uppercased() ?? ""
        return status == "COMPLETED" || status == "CANCELLED"
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            settings.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Nav
                BackHeaderNav(onBack: {
                    dismiss()
                })
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        if let job = viewModel.job {
                            // Header Section
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("JOB DETAILS")
                                        .scaledFont(size: 10, weight: .bold)
                                        .foregroundColor(settings.secondaryText)
                                        .tracking(1.0)
                                    Text(job.title)
                                        .scaledFont(size: 28, weight: .bold, design: .rounded)
                                        .foregroundColor(settings.primaryText)
                                }

                                Spacer()

                                Button(action: {
                                    router.selectedJobId = job.id
                                    router.path.append(TechnicianScreen.jobIssueReport)
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                        Text("REPORTS")
                                    }
                                    .scaledFont(size: 10, weight: .bold)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(settings.isHighContrast ? settings.surfaceColor : Color.red.opacity(0.1))
                                    .foregroundColor(settings.isHighContrast ? settings.primaryText : .red)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(settings.isHighContrast ? .red : settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.top, 12)

                            // INFO CARD
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("PROJECT SITE")
                                            .scaledFont(size: 10, weight: .bold)
                                            .foregroundColor(settings.secondaryText)
                                            .tracking(0.5)
                                        Text(job.location)
                                            .scaledFont(size: 16, weight: .bold)
                                            .foregroundColor(settings.accentColor)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("REFERENCE")
                                            .scaledFont(size: 8, weight: .bold)
                                            .foregroundColor(settings.secondaryText)
                                        Text(String(job.id.prefix(8)).uppercased())
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                            .foregroundColor(settings.primaryText)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(settings.isHighContrast ? .white.opacity(0.1) : Color.elevateLightGray.opacity(0.5))
                                            .cornerRadius(6)
                                    }
                                }

                                Divider().background(settings.cardStroke)

                                if let notes = job.notes, !notes.isEmpty {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("INSTRUCTIONS")
                                            .scaledFont(size: 10, weight: .bold)
                                            .foregroundColor(settings.secondaryText)
                                        Text(notes)
                                            .scaledFont(size: 14)
                                            .foregroundColor(settings.primaryText.opacity(0.9))
                                            .lineSpacing(4)
                                    }
                                }

                                HStack(spacing: 8) {
                                    Image(systemName: "calendar")
                                        .foregroundColor(settings.accentColor)
                                    Text(formattedDate(job.scheduledAt))
                                        .scaledFont(size: 12, weight: .semibold)
                                        .foregroundColor(settings.secondaryText)
                                    Spacer()
                                    Label("Priority: \(job.priority.uppercased())", systemImage: "flag.fill")
                                        .scaledFont(size: 10, weight: .bold)
                                        .foregroundColor(job.priority.uppercased() == "HIGH" ? .red : settings.secondaryText)
                                }
                            }
                            .padding(20)
                            .background(settings.surfaceColor)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                            )
                            .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
                            
                            // LOCATION & NAVIGATION
                            VStack(alignment: .leading, spacing: 12) {
                                Text("REAL-TIME NAVIGATION")
                                    .scaledFont(size: 11, weight: .bold)
                                    .foregroundColor(settings.secondaryText)
                                    .tracking(0.5)

                                ZStack(alignment: .bottom) {
                                    if let siteLat = job.siteLatitude, let siteLon = job.siteLongitude {
                                        let siteCoord = CLLocationCoordinate2D(latitude: siteLat, longitude: siteLon)
                                        
                                        Map {
                                            Marker("Site", systemImage: "mappin.circle.fill", coordinate: siteCoord)
                                                .tint(settings.accentColor)
                                            
                                            if let techCoord = viewModel.technicianLocation {
                                                Annotation("You", coordinate: techCoord) {
                                                    ZStack {
                                                        Circle().fill(Color.blue).frame(width: 16, height: 16)
                                                        Circle().stroke(Color.white, lineWidth: 2).frame(width: 16, height: 16)
                                                    }
                                                    .shadow(radius: 4)
                                                }
                                            }
                                        }
                                        .frame(height: 240)
                                        .clipShape(RoundedRectangle(cornerRadius: 24))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 24)
                                                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                                        )
                                        
                                        // View in Maps Overlay
                                        Button(action: {
                                            HapticManager.shared.playImpact(style: .medium)
                                            router.mapFocusJobId = job.id
                                            router.selectedTab = .map
                                        }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: "location.north.fill")
                                                Text("START NAVIGATION")
                                                    .scaledFont(size: 13, weight: .bold)
                                            }
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 24)
                                            .padding(.vertical, 14)
                                            .background(settings.isHighContrast ? Color.black : settings.accentColor)
                                            .cornerRadius(16)
                                            .shadow(color: settings.accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(settings.isHighContrast ? .white : .clear, lineWidth: 1)
                                            )
                                        }
                                        .padding(.bottom, 20)
                                    } else {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 24)
                                                .fill(Color.elevateLightGray.opacity(0.5))
                                                .frame(height: 180)
                                            Text("Map unavailable")
                                                .scaledFont(size: 14, weight: .semibold)
                                                .foregroundColor(settings.secondaryText)
                                        }
                                    }
                                }
                            }

                            // COST & QUOTATION PAIR
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
                                .padding(20)
                                .background(settings.surfaceColor)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                                )

                                Button(action: {
                                    router.selectedJobId = job.id
                                    router.path.append(TechnicianScreen.quotationStatus)
                                }) {
                                    VStack(spacing: 6) {
                                        Image(systemName: "doc.plaintext.fill")
                                            .font(.system(size: 20))
                                        Text("QUOTATION")
                                            .scaledFont(size: 10, weight: .bold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(settings.isHighContrast ? settings.surfaceColor : Color.elevateDarkGreen)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(settings.isHighContrast ? .white : settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            
                            // MEDIA GRID
                            VStack(alignment: .leading, spacing: 12) {
                                Text("SERVICE PHOTOS")
                                    .scaledFont(size: 11, weight: .bold)
                                    .foregroundColor(settings.secondaryText)
                                    .tracking(0.5)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(job.photoUrls, id: \.self) { url in
                                            ZStack(alignment: .topTrailing) {
                                                PhotoPreview(urlString: url)
                                                    .frame(width: 100, height: 100)
                                                    .cornerRadius(16)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 16)
                                                            .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                                                    )
                                                
                                                if !isTerminal {
                                                    Button(action: {
                                                        HapticManager.shared.playImpact(style: .medium)
                                                        viewModel.removePhoto(jobId: job.id, url: url, isOnline: network.isOnline)
                                                    }) {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .font(.system(size: 22))
                                                            .symbolRenderingMode(.palette)
                                                            .foregroundStyle(.white, .red)
                                                            .background(Circle().fill(.white).padding(2))
                                                            .offset(x: 6, y: -6)
                                                            .shadow(color: .black.opacity(0.1), radius: 2)
                                                    }
                                                }
                                            }
                                        }
                                        
                                        if !isTerminal {
                                            // Square Add Photo Placeholder
                                            Button(action: { 
                                                HapticManager.shared.playImpact(style: .light)
                                                showCamera = true 
                                            }) {
                                                VStack(spacing: 8) {
                                                    Image(systemName: "plus.viewfinder")
                                                        .font(.system(size: 24))
                                                    Text("ADD")
                                                        .scaledFont(size: 10, weight: .bold)
                                                }
                                                .foregroundColor(settings.accentColor)
                                                .frame(width: 100, height: 100)
                                                .background(settings.surfaceColor)
                                                .cornerRadius(16)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(settings.accentColor.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                                                )
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            
                            // TERMINAL STATE BANNERS (shown inline)
                            let status = job.status.uppercased()
                            if status == "COMPLETED" {
                                HStack(spacing: 14) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.white)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("JOB COMPLETED")
                                            .scaledFont(size: 13, weight: .bold)
                                            .foregroundColor(.white)
                                        Text(formattedDate(job.updatedAt))
                                            .scaledFont(size: 11)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(settings.isHighContrast ? Color.black : Color.elevateDarkGreen)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(settings.isHighContrast ? .white : Color.elevateDarkGreen.opacity(0.3), lineWidth: settings.cardStrokeWidth)
                                )
                                .shadow(color: Color.elevateDarkGreen.opacity(0.2), radius: 8, x: 0, y: 4)
                            } else if status == "CANCELLED" {
                                HStack(spacing: 14) {
                                    Image(systemName: "xmark.octagon.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.white)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("JOB CANCELLED BY MANAGER")
                                            .scaledFont(size: 13, weight: .bold)
                                            .foregroundColor(.white)
                                        if let cancelledAt = job.cancelledAt {
                                            Text(formattedDate(cancelledAt))
                                                .scaledFont(size: 11)
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(settings.isHighContrast ? Color.black : Color.red)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(settings.isHighContrast ? .white : Color.red.opacity(0.3), lineWidth: settings.cardStrokeWidth)
                                )
                                .shadow(color: Color.red.opacity(0.2), radius: 8, x: 0, y: 4)
                            }

                            // ACTION BUTTONS AT THE BOTTOM OF CONTENT
                            if status != "COMPLETED" && status != "CANCELLED" {
                                VStack(spacing: 12) {
                                    if status == "HOLD" {
                                        actionButton(title: "CONTINUE WORK", icon: "play.fill", color: .blue) {
                                            updateStatus(jobId: job.id, status: "IN_PROGRESS")
                                        }
                                    } else if status == "IN_PROGRESS" {
                                        HStack(spacing: 12) {
                                            Button(action: {
                                                holdReasonText = job.holdReason ?? ""
                                                showHoldPrompt = true
                                            }) {
                                                HStack {
                                                    Image(systemName: "pause.fill")
                                                    Text("HOLD")
                                                }
                                                .scaledFont(size: 15, weight: .bold)
                                                .foregroundColor(settings.isHighContrast ? settings.primaryText : settings.accentColor)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 16)
                                                .background(settings.surfaceColor)
                                                .cornerRadius(16)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                                                )
                                            }
                                            actionButton(title: "COMPLETE", icon: "checkmark.seal.fill", color: Color.elevateDarkGreen) {
                                                updateStatus(jobId: job.id, status: "COMPLETED") {
                                                    dismiss()
                                                }
                                            }
                                        }
                                    } else {
                                        // PENDING or Fallback
                                        actionButton(title: "START WORK", icon: "play.circle.fill", color: settings.accentColor) {
                                            updateStatus(jobId: job.id, status: "IN_PROGRESS")
                                        }
                                    }
                                }
                                .padding(.top, 12)
                            }

                            // Spacer for bottom tab bar clearance
                            Spacer().frame(height: 100)
                        } else {
                            SkeletonDetailHeader()
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            HapticManager.shared.playImpact(style: .light)
            viewModel.load(jobId: jobId) 
        }
        .sheet(isPresented: $showCamera) {
            CameraCaptureView(onCapture: { data in
                viewModel.addPhoto(jobId: jobId, data: data, isOnline: network.isOnline)
            }, isPresented: $showCamera)
        }
        .alert("Place on Hold", isPresented: $showHoldPrompt) {
            TextField("Reason for delay", text: $holdReasonText)
            Button("Cancel", role: .cancel) {}
            Button("Confirm Hold") {
                updateStatus(jobId: jobId, status: "HOLD", holdReason: holdReasonText)
            }
        } message: {
            Text("Provide a brief reason for pausing this service.")
        }
    }

    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticManager.shared.playImpact(style: .rigid)
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .scaledFont(size: 15, weight: .bold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(settings.isHighContrast ? Color.black : color)
            .cornerRadius(16)
            .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(settings.isHighContrast ? .white : .clear, lineWidth: 1)
            )
        }
    }

    private func updateStatus(jobId: String, status: String, holdReason: String? = nil, completion: (() -> Void)? = nil) {
        guard let user = appSession.currentUser else { return }
        viewModel.updateStatus(jobId: jobId, status: status, user: user, isOnline: network.isOnline, holdReasonOverride: holdReason, completion: completion)
    }

    private func currencyString(_ value: Double?) -> String {
        let actualValue = value ?? 0.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "LKR"
        formatter.locale = Locale(identifier: "en_LK")
        return formatter.string(from: NSNumber(value: actualValue)) ?? "LKR \(actualValue)"
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    JobDetailsView(jobId: "sample")
        .environmentObject(AppSession())
}
