import SwiftUI
import MapKit
import CoreLocation

struct ManagerCreateJobView: View {
    @Environment(\.managerTabRouter) private var router
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = ManagerCreateJobViewModel()
    @ObservedObject private var network = NetworkService.shared
    @ObservedObject var settings = AccessibilitySettings.shared
    @ObservedObject var locationService = LocationService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTechnicianId: String?
    @State private var jobTitle = ""
    @State private var location = ""
    @State private var scheduledAt = Date()
    @State private var descriptionText = ""
    @State private var isUrgent = false
    @State private var siteCoordinate: CLLocationCoordinate2D?
    @State private var mapPosition = MapCameraPosition.userLocation(fallback: .automatic)

    var body: some View {
        ZStack {
            settings.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                BackHeaderNav(isManager: true, onBack: {
                    dismiss()
                })
                .background(settings.surfaceColor)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Create Job")
                                .scaledFont(size: 34, weight: .black, design: .rounded)
                                .foregroundColor(settings.primaryText)
                            Text("Dispatch a new field assignment to your technical team.")
                                .scaledFont(size: 15)
                                .foregroundColor(settings.secondaryText)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                        VStack(spacing: 24) {
                            // GENERAL DETAILS SECTION
                            sectionCard(title: "GENERAL DETAILS", icon: "briefcase.fill") {
                                VStack(spacing: 20) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("ASSIGN TECHNICIAN")
                                            .scaledFont(size: 10, weight: .bold)
                                            .foregroundColor(settings.secondaryText)
                                            .tracking(1)
                                        
                                        Menu {
                                            Picker("Technician", selection: $selectedTechnicianId) {
                                                ForEach(viewModel.technicians, id: \.id) { tech in
                                                    Text(displayName(for: tech)).tag(Optional(tech.id))
                                                }
                                            }
                                        } label: {
                                            HStack {
                                                Image(systemName: "person.badge.shield.checkmark")
                                                    .foregroundColor(settings.accentColor)
                                                    .font(.system(size: 14))
                                                Text(selectedTechnicianLabel())
                                                    .scaledFont(size: 15, weight: .medium)
                                                    .foregroundColor(selectedTechnicianId == nil ? settings.secondaryText : settings.primaryText)
                                                Spacer()
                                                Image(systemName: "chevron.up.chevron.down")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(settings.secondaryText)
                                            }
                                            .padding(14)
                                            .background(settings.isHighContrast ? Color.black : settings.appBackground.opacity(0.4))
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                                            )
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("JOB TITLE")
                                            .scaledFont(size: 10, weight: .bold)
                                            .foregroundColor(settings.secondaryText)
                                            .tracking(1)
                                        
                                        TextField("e.g. Annual HVAC Maintenance", text: $jobTitle)
                                            .scaledFont(size: 15)
                                            .foregroundColor(settings.primaryText)
                                            .padding(14)
                                            .background(settings.isHighContrast ? Color.black : settings.appBackground.opacity(0.4))
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                                            )
                                    }

                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("DESCRIPTION")
                                            .scaledFont(size: 10, weight: .bold)
                                            .foregroundColor(settings.secondaryText)
                                            .tracking(1)
                                        
                                        ZStack(alignment: .topLeading) {
                                            if descriptionText.isEmpty {
                                                Text("Additional notes or job scope...")
                                                    .scaledFont(size: 14)
                                                    .foregroundColor(settings.secondaryText.opacity(0.6))
                                                    .padding(.horizontal, 4)
                                                    .padding(.vertical, 8)
                                            }
                                            
                                            TextEditor(text: $descriptionText)
                                                .scaledFont(size: 14)
                                                .scrollContentBackground(.hidden)
                                                .foregroundColor(settings.primaryText)
                                        }
                                        .frame(height: 100)
                                        .padding(10)
                                        .background(settings.isHighContrast ? Color.black : settings.appBackground.opacity(0.4))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                                        )
                                    }
                                }
                            }

                            // SITE & LOCATION SECTION
                            sectionCard(title: "SITE & LOCATION", icon: "mappin.and.ellipse") {
                                VStack(spacing: 20) {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: "location.fill")
                                                .foregroundColor(settings.accentColor)
                                                .font(.system(size: 14))
                                            TextField("Search or pin location", text: $location)
                                                .scaledFont(size: 15)
                                                .foregroundColor(settings.primaryText)
                                                .onSubmit {
                                                    performSearch()
                                                }
                                            
                                            Button(action: performSearch) {
                                                Image(systemName: "magnifyingglass")
                                                    .foregroundColor(settings.accentColor)
                                            }
                                        }
                                        .padding(14)
                                        .background(settings.isHighContrast ? Color.black : settings.appBackground.opacity(0.4))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                                        )

                                        MapReader { proxy in
                                            Map(position: $mapPosition) {
                                                if let siteCoordinate {
                                                    Marker("Job Site", coordinate: siteCoordinate)
                                                        .tint(settings.accentColor)
                                                }
                                            }
                                            .frame(height: 180)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(settings.cardStroke, lineWidth: 1)
                                            )
                                            .gesture(
                                                SpatialTapGesture()
                                                    .onEnded { value in
                                                        if let coordinate = proxy.convert(value.location, from: .local) {
                                                            HapticManager.shared.playImpact(style: .medium)
                                                            siteCoordinate = coordinate
                                                            mapPosition = MapCameraPosition.region(
                                                                MKCoordinateRegion(
                                                                    center: coordinate,
                                                                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                                                                )
                                                            )
                                                            updateLocation(from: coordinate)
                                                        }
                                                    }
                                            )
                                        }
                                    }
                                }
                            }

                            // SCHEDULE & URGENCY SECTION
                            sectionCard(title: "SCHEDULE & PRIORITY", icon: "calendar.badge.clock") {
                                VStack(spacing: 20) {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("DATE")
                                                .scaledFont(size: 10, weight: .bold)
                                                .foregroundColor(settings.secondaryText)
                                                .tracking(1)
                                            DatePicker("", selection: $scheduledAt, displayedComponents: .date)
                                                .labelsHidden()
                                                .datePickerStyle(.compact)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(8)
                                                .background(settings.isHighContrast ? Color.black : settings.appBackground.opacity(0.4))
                                                .cornerRadius(10)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                                                )
                                        }

                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("TIME")
                                                .scaledFont(size: 10, weight: .bold)
                                                .foregroundColor(settings.secondaryText)
                                                .tracking(1)
                                            DatePicker("", selection: $scheduledAt, displayedComponents: .hourAndMinute)
                                                .labelsHidden()
                                                .datePickerStyle(.compact)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(8)
                                                .background(settings.isHighContrast ? Color.black : settings.appBackground.opacity(0.4))
                                                .cornerRadius(10)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                                                )
                                        }
                                    }

                                    Toggle(isOn: $isUrgent) {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                Circle()
                                                    .fill(isUrgent ? Color.red.opacity(0.1) : (settings.isHighContrast ? Color.black : settings.appBackground.opacity(0.4)))
                                                    .frame(width: 32, height: 32)
                                                    .overlay(
                                                        Circle().stroke(isUrgent ? Color.red : settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                                                    )
                                                Image(systemName: "exclamationmark.triangle.fill")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(isUrgent ? .red : settings.secondaryText)
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("HIGH PRIORITY")
                                                    .scaledFont(size: 13, weight: .bold)
                                                    .foregroundColor(isUrgent ? .red : settings.primaryText)
                                                Text("Mark as urgent")
                                                    .scaledFont(size: 11)
                                                    .foregroundColor(settings.secondaryText)
                                            }
                                        }
                                    }
                                    .toggleStyle(SwitchToggleStyle(tint: .red))
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        PrimaryButton(title: viewModel.isSaving ? "Dispatching..." : "Create Dispatch", iconName: viewModel.isSaving ? nil : "paperplane.fill") {
                            createJob()
                        }
                        .disabled(viewModel.isSaving)
                        .opacity(viewModel.isSaving ? 0.6 : 1.0)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 100)
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            guard let user = appSession.currentUser else { return }
            viewModel.loadTechnicians(organizationId: user.organizationId, isOnline: network.isOnline)
            
            // Center map on current location if available
            if let current = locationService.currentLocation {
                mapPosition = .region(MKCoordinateRegion(center: current, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)))
            }
        }
        .alert("Create Job", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func sectionCard<Content: View>(title: String, icon: String, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(settings.accentColor)
                Text(title)
                    .scaledFont(size: 11, weight: .bold)
                    .foregroundColor(settings.secondaryText)
                    .tracking(1)
            }
            .padding(.horizontal, 4)
            .speakOnAppear(title)

            VStack(spacing: 20) {
                content()
            }
            .padding(20)
            .background(settings.surfaceColor)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 5)
        }
    }

    private func displayName(for user: User) -> String {
        user.displayName.isEmpty ? user.username : user.displayName
    }

    private func selectedTechnicianLabel() -> String {
        guard let selectedId = selectedTechnicianId,
              let tech = viewModel.technicians.first(where: { $0.id == selectedId })
        else { return "Select Technician" }
        return displayName(for: tech)
    }

    private func createJob() {
        guard let user = appSession.currentUser else { return }
        let assignedId = selectedTechnicianId ?? ""
        viewModel.createJob(
            organizationId: user.organizationId,
            userId: user.id,
            assignedUserId: assignedId,
            title: jobTitle,
            location: location,
            scheduledAt: scheduledAt,
            notes: descriptionText,
            isUrgent: isUrgent,
            siteLatitude: siteCoordinate?.latitude,
            siteLongitude: siteCoordinate?.longitude,
            isOnline: network.isOnline
        ) { job in
            if job != nil {
                dismiss()
            }
        }
    }

    private func performSearch() {
        let trimmed = location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        viewModel.searchLocation(query: trimmed) { coordinate, name in
            if let coordinate = coordinate {
                self.siteCoordinate = coordinate
                self.mapPosition = MapCameraPosition.region(
                    MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    )
                )
                if let name = name {
                    self.location = name
                }
                HapticManager.shared.playImpact(style: .medium)
            }
        }
    }

    private func updateLocation(from coordinate: CLLocationCoordinate2D) {
        if #available(iOS 26.0, *) {
            Task {
                do {
                    let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    if let request = MKReverseGeocodingRequest(location: location) {
                        let mapItems = try await request.mapItems
                        if let mapItem = mapItems.first {
                            let name = mapItem.name ?? "Pinned location"
                            await MainActor.run {
                                self.location = name
                            }
                        }
                    } else {
                        await MainActor.run {
                            if self.location.isEmpty { self.location = "Pinned location" }
                        }
                    }
                } catch {
                    await MainActor.run {
                        if self.location.isEmpty { self.location = "Pinned location" }
                    }
                }
            }
        } else {
            let geocoder = CLGeocoder()
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            geocoder.reverseGeocodeLocation(location) { placemarks, _ in
                guard let placemark = placemarks?.first else {
                    if self.location.isEmpty { self.location = "Pinned location" }
                    return
                }
                let parts = [placemark.name, placemark.locality, placemark.administrativeArea]
                let text = parts.compactMap { $0 }.joined(separator: ", ")
                self.location = text.isEmpty ? "Pinned location" : text
            }
        }
    }
}

#Preview {
    ManagerCreateJobView()
        .environmentObject(AppSession())
}
