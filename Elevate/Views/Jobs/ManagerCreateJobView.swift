import SwiftUI
import MapKit
import CoreLocation

struct ManagerCreateJobView: View {
    @Environment(\.managerTabRouter) private var router
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = ManagerCreateJobViewModel()
    @ObservedObject private var network = NetworkService.shared
    @State private var selectedTechnicianId: String?
    @State private var jobTitle = ""
    @State private var location = ""
    @State private var scheduledAt = Date()
    @State private var descriptionText = ""
    @State private var isUrgent = false
    @State private var siteCoordinate: CLLocationCoordinate2D?
    @State private var mapPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )

    var body: some View {
        ZStack {
            Color.elevateLightGray.opacity(0.3).ignoresSafeArea()

            VStack(spacing: 0) {
                BackHeaderNav(isManager: true, onBack: {
                    router.currentScreen = .jobs
                    router.selectedTab = .jobs
                })
                .background(Color.white)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Create Job")
                                .scaledFont(size: 34, weight: .black, design: .rounded)
                                .foregroundColor(.black)
                            Text("Dispatch a new field assignment to your technical team.")
                                .scaledFont(size: 15)
                                .foregroundColor(.elevateTextGray)
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
                                            .foregroundColor(.elevateTextGray)
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
                                                    .foregroundColor(.elevateDarkGreen)
                                                    .font(.system(size: 14))
                                                Text(selectedTechnicianLabel())
                                                    .scaledFont(size: 15, weight: .medium)
                                                    .foregroundColor(selectedTechnicianId == nil ? .elevateTextGray : .black)
                                                Spacer()
                                                Image(systemName: "chevron.up.chevron.down")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.elevateTextGray)
                                            }
                                            .padding(14)
                                            .background(Color.elevateLightGray.opacity(0.4))
                                            .cornerRadius(12)
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("JOB TITLE")
                                            .scaledFont(size: 10, weight: .bold)
                                            .foregroundColor(.elevateTextGray)
                                            .tracking(1)
                                        
                                        TextField("e.g. Annual HVAC Maintenance", text: $jobTitle)
                                            .scaledFont(size: 15)
                                            .padding(14)
                                            .background(Color.elevateLightGray.opacity(0.4))
                                            .cornerRadius(12)
                                    }

                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("DESCRIPTION")
                                            .scaledFont(size: 10, weight: .bold)
                                            .foregroundColor(.elevateTextGray)
                                            .tracking(1)
                                        
                                        TextEditor(text: $descriptionText)
                                            .frame(height: 100)
                                            .scaledFont(size: 14)
                                            .padding(10)
                                            .background(Color.elevateLightGray.opacity(0.4))
                                            .cornerRadius(12)
                                            .overlay(
                                                Group {
                                                    if descriptionText.isEmpty {
                                                        Text("Additional notes or job scope...")
                                                            .scaledFont(size: 14)
                                                            .foregroundColor(.elevateTextGray.opacity(0.6))
                                                            .padding(.leading, 14)
                                                            .padding(.top, 14)
                                                    }
                                                },
                                                alignment: .topLeading
                                            )
                                    }
                                }
                            }

                            // VENUE & LOCATION SECTION
                            sectionCard(title: "SITE & LOCATION", icon: "mappin.and.ellipse") {
                                VStack(spacing: 20) {
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            Image(systemName: "location.fill")
                                                .foregroundColor(.elevateDarkGreen)
                                                .font(.system(size: 14))
                                            TextField("Search or pin location", text: $location)
                                                .scaledFont(size: 15)
                                        }
                                        .padding(14)
                                        .background(Color.elevateLightGray.opacity(0.4))
                                        .cornerRadius(12)

                                        MapReader { proxy in
                                            Map(position: $mapPosition) {
                                                if let siteCoordinate {
                                                    Marker("Job Site", coordinate: siteCoordinate)
                                                        .tint(Color.elevateDarkGreen)
                                                }
                                            }
                                            .frame(height: 180)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.elevateLightGray, lineWidth: 1)
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
                                                .foregroundColor(.elevateTextGray)
                                                .tracking(1)
                                            DatePicker("", selection: $scheduledAt, displayedComponents: .date)
                                                .labelsHidden()
                                                .datePickerStyle(.compact)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(8)
                                                .background(Color.elevateLightGray.opacity(0.4))
                                                .cornerRadius(10)
                                        }

                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("TIME")
                                                .scaledFont(size: 10, weight: .bold)
                                                .foregroundColor(.elevateTextGray)
                                                .tracking(1)
                                            DatePicker("", selection: $scheduledAt, displayedComponents: .hourAndMinute)
                                                .labelsHidden()
                                                .datePickerStyle(.compact)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(8)
                                                .background(Color.elevateLightGray.opacity(0.4))
                                                .cornerRadius(10)
                                        }
                                    }

                                    Toggle(isOn: $isUrgent) {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                Circle()
                                                    .fill(isUrgent ? Color.red.opacity(0.1) : Color.elevateLightGray.opacity(0.4))
                                                    .frame(width: 32, height: 32)
                                                Image(systemName: "exclamationmark.triangle.fill")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(isUrgent ? .red : .elevateTextGray)
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("HIGH PRIORITY")
                                                    .scaledFont(size: 13, weight: .bold)
                                                    .foregroundColor(isUrgent ? .red : .black)
                                                Text("Mark as urgent")
                                                    .scaledFont(size: 11)
                                                    .foregroundColor(.elevateTextGray)
                                            }
                                        }
                                    }
                                    .toggleStyle(SwitchToggleStyle(tint: .red))
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        PrimaryButton(title: "Create Dispatch", iconName: "paperplane.fill") {
                            createJob()
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            guard let user = appSession.currentUser else { return }
            viewModel.loadTechnicians(organizationId: user.organizationId, isOnline: network.isOnline)
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
                    .foregroundColor(.elevateDarkGreen)
                Text(title)
                    .scaledFont(size: 11, weight: .bold)
                    .foregroundColor(.elevateTextGray)
                    .tracking(1)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 20) {
                content()
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(20)
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
                router.currentScreen = .jobs
                router.selectedTab = .jobs
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
                            let placemark = mapItem.placemark
                            let parts = [placemark.name, placemark.locality, placemark.administrativeArea]
                            let address = parts.compactMap { $0 }.joined(separator: ", ")
                            await MainActor.run {
                                self.location = address.isEmpty ? "Pinned location" : address
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
