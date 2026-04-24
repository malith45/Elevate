import SwiftUI
import UIKit

struct JobIssueReportView: View {
    let jobId: String

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = JobIssueReportViewModel()
    @ObservedObject private var network = NetworkService.shared
    @ObservedObject var settings = AccessibilitySettings.shared
    @State private var showCamera = false
    @State private var jobStatus: String = "PENDING"
    @State private var selectedPhotoUrl: String? = nil
    
    private var isTerminal: Bool {
        let status = jobStatus.uppercased()
        return status == "COMPLETED" || status == "CANCELLED"
    }
    
    var body: some View {
        ZStack {
            settings.appBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                BackHeaderNav(onBack: { dismiss() })
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        titleSection
                        
                        if !viewModel.reports.isEmpty {
                            reportPicker
                        }
                        
                        descriptionCard
                        priorityCard
                        photosCard
                        
                        if let response = viewModel.selectedReport?.managerResponse {
                            managerResponseCard(response)
                        }
                        
                        if viewModel.isNewReport && !isTerminal {
                            submitButton
                        }
                        
                        Spacer().frame(height: 160)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            viewModel.load(jobId: jobId)
            if let job = LocalStorageService.shared.fetchJob(id: jobId) {
                jobStatus = job.status
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showCamera) {
            CameraCaptureView(onCapture: { data in
                viewModel.addAttachment(data: data)
            }, isPresented: $showCamera)
        }
        .alert("Issue Report", isPresented: Binding(
            get: { viewModel.errorMessage != nil || viewModel.didSubmit },
            set: { _ in viewModel.errorMessage = nil; viewModel.didSubmit = false }
        )) {
            Button("OK", role: .cancel) {
                if viewModel.didSubmit { dismiss() }
            }
        } message: {
            Text(viewModel.errorMessage ?? "Report submitted successfully.")
        }
        .onChange(of: viewModel.didSubmit) { _, didSubmit in
            if didSubmit {
                HapticManager.shared.playNotification(type: .success)
            }
        }
        .fullScreenCover(item: Binding(
            get: { selectedPhotoUrl.map { PhotoIdentifiable(url: $0) } },
            set: { selectedPhotoUrl = $0?.url }
        )) { item in
            FullScreenImageView(urlString: item.url)
        }
    }
    
    struct PhotoIdentifiable: Identifiable {
        let id = UUID()
        let url: String
    }

    private var reportPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(settings.accentColor)
                Text("REPORT HISTORY")
                    .scaledFont(size: 12, weight: .bold)
                    .foregroundColor(settings.secondaryText)
                    .tracking(1)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // New Report Option
                    Button(action: {
                        HapticManager.shared.playImpact(style: .light)
                        viewModel.selectReport(nil)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("NEW")
                        }
                        .scaledFont(size: 10, weight: .bold)
                        .foregroundColor(viewModel.isNewReport ? .white : settings.primaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(viewModel.isNewReport ? settings.accentColor : settings.surfaceColor)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(viewModel.isNewReport ? .clear : settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                        )
                    }

                    ForEach(viewModel.reports) { report in
                        let isSelected = report.id == viewModel.selectedReport?.id
                        Button(action: {
                            HapticManager.shared.playImpact(style: .light)
                            viewModel.selectReport(report)
                        }) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(report.priority)
                                    .scaledFont(size: 8, weight: .black)
                                Text(shortDate(report.createdAt))
                                    .scaledFont(size: 10, weight: .bold)
                            }
                            .foregroundColor(isSelected ? .white : settings.primaryText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isSelected ? settings.accentColor : settings.surfaceColor)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSelected ? .clear : settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                            )
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(20)
        .background(settings.surfaceColor)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
    }

    private func managerResponseCard(_ response: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrowshape.turn.up.left.fill")
                    .foregroundColor(settings.accentColor)
                Text("MANAGER RESPONSE")
                    .scaledFont(size: 12, weight: .bold)
                    .foregroundColor(settings.secondaryText)
            }
            
            Text(response)
                .scaledFont(size: 14, weight: .medium)
                .foregroundColor(settings.primaryText)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(settings.accentColor.opacity(0.05))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(settings.accentColor.opacity(0.1), lineWidth: 1)
                )
            
            if let resolvedAt = viewModel.selectedReport?.resolvedAt {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                    Text("RESOLVED ON \(formattedDate(resolvedAt))")
                }
                .scaledFont(size: 10, weight: .bold)
                .foregroundColor(.elevateDarkGreen)
            }
        }
        .padding(20)
        .background(settings.surfaceColor)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.isNewReport ? "Report Issue" : "Report Details")
                .scaledFont(size: 28, weight: .bold, design: .rounded)
                .foregroundColor(settings.primaryText)
            Text(viewModel.isNewReport ? "Provide detailed information about the service failure" : "Viewing previously submitted issue report")
                .scaledFont(size: 15, weight: .medium)
                .foregroundColor(settings.secondaryText)
        }
        .padding(.top, 20)
    }

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "text.bubble.fill")
                    .foregroundColor(settings.accentColor)
                Text("ISSUE DESCRIPTION")
                    .scaledFont(size: 12, weight: .bold)
                    .foregroundColor(settings.secondaryText)
                    .tracking(1)
                
                if !viewModel.isNewReport {
                    Spacer()
                    priorityPillSmall(viewModel.priority)
                }
            }
            
            if viewModel.isNewReport {
                ZStack(alignment: .topLeading) {
                    if viewModel.issueText.isEmpty {
                        Text("Describe the technical failure in detail...")
                            .scaledFont(size: 15)
                            .foregroundColor(settings.secondaryText.opacity(0.6))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                    }
                    
                    TextEditor(text: $viewModel.issueText)
                        .scaledFont(size: 15)
                        .scrollContentBackground(.hidden)
                        .foregroundColor(settings.primaryText)
                        .disabled(isTerminal)
                }
                .frame(minHeight: 140)
            } else {
                Text(viewModel.issueText)
                    .scaledFont(size: 15)
                    .foregroundColor(settings.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            }
        }
        .padding(20)
        .background(settings.surfaceColor)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
    }

    @ViewBuilder
    private var priorityCard: some View {
        if viewModel.isNewReport {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(settings.accentColor)
                    Text("PRIORITY LEVEL")
                        .scaledFont(size: 12, weight: .bold)
                        .foregroundColor(settings.secondaryText)
                        .tracking(1)
                }
                
                HStack(spacing: 12) {
                    PriorityButton(title: "LOW", isSelected: viewModel.priority == "LOW") { viewModel.priority = "LOW" }
                    PriorityButton(title: "MEDIUM", isSelected: viewModel.priority == "MEDIUM") { viewModel.priority = "MEDIUM" }
                    PriorityButton(title: "HIGH", isSelected: viewModel.priority == "HIGH") { viewModel.priority = "HIGH" }
                }
                .disabled(isTerminal)
            }
            .padding(20)
            .background(settings.surfaceColor)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
        }
    }

    private func priorityPillSmall(_ priority: String) -> some View {
        Text(priority)
            .scaledFont(size: 10, weight: .black)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .foregroundColor(.white)
            .background(priorityColor(priority))
            .cornerRadius(8)
    }

    private func priorityColor(_ priority: String) -> Color {
        switch priority.uppercased() {
        case "HIGH": return .red
        case "MEDIUM": return .orange
        case "LOW": return .blue
        default: return settings.accentColor
        }
    }

    private var photosCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "camera.fill")
                    .foregroundColor(settings.accentColor)
                Text(viewModel.isNewReport ? "SUPPORTING PHOTOS" : "SUBMITTED PHOTOS")
                    .scaledFont(size: 12, weight: .bold)
                    .foregroundColor(settings.secondaryText)
                    .tracking(1)
                Spacer()
                Text("\(viewModel.attachmentUrls.count) TOTAL")
                    .scaledFont(size: 10, weight: .bold)
                    .foregroundColor(settings.accentColor)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.attachmentUrls, id: \.self) { url in
                        ZStack(alignment: .topTrailing) {
                            Button(action: {
                                selectedPhotoUrl = url
                            }) {
                                PhotoPreview(urlString: url)
                                    .frame(width: 90, height: 90)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                                    )
                            }
                            .buttonStyle(.plain)
                            
                            if viewModel.isNewReport && !isTerminal {
                                Button(action: {
                                    HapticManager.shared.playImpact(style: .medium)
                                    viewModel.removeAttachment(url: url)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 20))
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, .red)
                                        .background(Circle().fill(.white).padding(2))
                                        .offset(x: 5, y: -5)
                                }
                            }
                        }
                    }
                    
                    if viewModel.isNewReport && !isTerminal {
                        Button(action: { 
                            HapticManager.shared.playImpact(style: .light)
                            showCamera = true 
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: "plus.viewfinder")
                                    .font(.system(size: 22))
                                Text("ADD")
                                    .scaledFont(size: 9, weight: .bold)
                            }
                            .foregroundColor(settings.accentColor)
                            .frame(width: 90, height: 90)
                            .background(settings.surfaceColor)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(settings.accentColor.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                            )
                        }
                    }
                }
                .padding(.vertical, 4)
                .padding(.trailing, 20)
            }
        }
        .padding(20)
        .background(settings.surfaceColor)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
    }

    private var submitButton: some View {
        Button(action: {
            HapticManager.shared.playImpact(style: .medium)
            submitIssue()
        }) {
            HStack {
                Text("SUBMIT REPORT")
                Spacer()
                Image(systemName: "paperplane.fill")
            }
            .scaledFont(size: 16, weight: .bold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .padding(.horizontal, 24)
            .background(settings.isHighContrast ? settings.surfaceColor : Color.elevateDarkGreen)
            .cornerRadius(16)
            .shadow(color: Color.elevateDarkGreen.opacity(0.2), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
            )
        }
        .padding(.top, 8)
    }

    private func submitIssue() {
        guard let user = appSession.currentUser else { return }
        viewModel.submit(jobId: jobId, user: user, isOnline: network.isOnline)
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct PriorityPill: View {
    let priority: String
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        Text(priority)
            .scaledFont(size: 12, weight: .bold)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .foregroundColor(.white)
            .background(priorityColor)
            .cornerRadius(8)
    }
    
    private var priorityColor: Color {
        switch priority.uppercased() {
        case "HIGH": return .red
        case "MEDIUM": return .orange
        case "LOW": return .blue
        default: return settings.accentColor
        }
    }
}

struct PriorityButton: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void
    @ObservedObject var settings = AccessibilitySettings.shared
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .scaledFont(size: 12, weight: .bold)
                .foregroundColor(isSelected ? .white : settings.primaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isSelected ? (settings.isHighContrast ? settings.surfaceColor : Color.elevateDarkGreen) : settings.surfaceColor)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected && settings.isHighContrast ? settings.primaryText : settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                )
                .shadow(color: isSelected && !settings.isHighContrast ? Color.elevateDarkGreen.opacity(0.3) : Color.clear, radius: 5, x: 0, y: 3)
        }
    }
}

#Preview {
    JobIssueReportView(jobId: "sample")
        .environmentObject(AppSession())
}
