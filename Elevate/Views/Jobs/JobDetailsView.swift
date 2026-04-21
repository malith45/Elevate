import SwiftUI
import UIKit
import MapKit

struct JobDetailsView: View {
    let jobId: String

    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = JobDetailsViewModel()
    @ObservedObject private var network = NetworkService.shared
    @ObservedObject var settings = AccessibilitySettings.shared
    @State private var showCamera = false
    
    var body: some View {
        ZStack {
            settings.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Nav
                BackHeaderNav()
                
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

                                NavigationLink(destination: JobIssueReportView(jobId: job.id)) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                        Text("REPORT ISSUE")
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
                                    .frame(height: 180)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                } else {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(LinearGradient(colors: [.elevateDarkGreen.opacity(0.85), .elevateDarkGreen.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(height: 180)

                                        VStack(spacing: 8) {
                                            Image(systemName: "map.fill")
                                                .font(.system(size: 36))
                                                .foregroundColor(settings.isHighContrast ? settings.primaryText : .white.opacity(0.4))
                                            Text("Location preview unavailable")
                                                .scaledFont(size: 12, weight: .semibold)
                                                .foregroundColor(settings.isHighContrast ? settings.primaryText : .white.opacity(0.7))
                                        }
                                    }
                                }

                                Button(action: { openInMaps(job) }) {
                                    Text("VIEW IN MAPS")
                                        .scaledFont(size: 10, weight: .bold)
                                        .foregroundColor(settings.isHighContrast ? .white : settings.accentColor)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(settings.isHighContrast ? Color.black : Color.white)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(settings.isHighContrast ? Color.white : Color.clear, lineWidth: 1)
                                        )
                                }
                                .padding(12)
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

                            NavigationLink(destination: QuotationStatusView(jobId: job.id)) {
                                VStack(spacing: 6) {
                                    Image(systemName: "doc.text.fill")
                                    Text("VIEW QUOTATION")
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

                            Button(action: { showCamera = true }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "camera.fill")
                                    Text("Add Photo")
                                        .scaledFont(size: 12, weight: .bold)
                                }
                                .foregroundColor(settings.accentColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(settings.surfaceColor)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                                        .foregroundColor(settings.cardStroke)
                                )
                            }
                        }
                        
                        HStack(spacing: 12) {
                            Button(action: { updateStatus(jobId: job.id, status: "IN_PROGRESS") }) {
                                Text("Update")
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
                            Button(action: { updateStatus(jobId: job.id, status: "COMPLETED") }) {
                                Text("Complete Job")
                                    .scaledFont(size: 16, weight: .bold)
                                    .foregroundColor(settings.isHighContrast ? settings.primaryText : settings.accentColor)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(settings.surfaceColor)
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                                    )
                            }
                        }
                        
                        Spacer().frame(height: 100)
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
        let actualValue = value ?? 0.0
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "LKR"
        return formatter.string(from: NSNumber(value: actualValue)) ?? "LKR \(actualValue)"
    }

    private func openInMaps(_ job: Job) {
        if let latitude = job.siteLatitude, let longitude = job.siteLongitude {
            let location = CLLocation(latitude: latitude, longitude: longitude)
            let item = MKMapItem(location: location, address: nil)
            item.name = job.title
            item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
            return
        }

        let encoded = job.location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? job.location
        if let url = URL(string: "http://maps.apple.com/?q=\(encoded)") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    JobDetailsView(jobId: "sample")
        .environmentObject(AppSession())
}
