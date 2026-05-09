import SwiftUI
import MapKit

struct TechnicianMapView: View {
    @EnvironmentObject private var appSession: AppSession
    @Environment(\.technicianTabRouter) private var router
    @ObservedObject var viewModel: MapViewModel
    @ObservedObject private var locationService = LocationService.shared
    @State private var mapPosition: MapCameraPosition
    @State private var hasCenteredOnUser = false
    @State private var activeJob: Job?
    @ObservedObject var settings = AccessibilitySettings.shared
    private let localStorage = LocalStorageService.shared

    init(viewModel: MapViewModel = MapViewModel()) {
        self.viewModel = viewModel
        let initialPosition = MapCameraPosition.region(viewModel.savedRegion ?? viewModel.region)
        _mapPosition = State(initialValue: initialPosition)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background Map
            Map(position: $mapPosition) {
                if let route = viewModel.route {
                    MapPolyline(route.polyline)
                        .stroke(Color.elevateDarkGreen, lineWidth: 5)
                }

                if let destination = viewModel.destination {
                    Marker("Destination", coordinate: destination)
                        .tint(settings.accentColor)
                }

                if let current = locationService.currentLocation {
                    Annotation("", coordinate: current) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 16, height: 16)
                            .overlay(Circle().stroke(Color.white, lineWidth: 4))
                            .shadow(radius: 3)
                    }
                }
            }
            .mapControls {
                MapUserLocationButton()
            }
            .ignoresSafeArea()
            
            // Header
            BrandHeaderNav(showOnlineStatus: false)
                .background(settings.surfaceColor)
            
            VStack(spacing: 12) {
                Spacer()
                
                // Current Location Button
                HStack {
                    Spacer()
                    Button(action: centerOnUser) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(settings.accentColor)
                            .frame(width: 48, height: 48)
                            .background(settings.surfaceColor)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                            .overlay(
                                Circle()
                                    .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                            )
                    }
                    .padding(.trailing, 20)
                }
                .padding(.bottom, shouldShowTripCard ? 0 : 120)

                if shouldShowTripCard {
                    HStack(spacing: 12) {
                        // Time Badge
                        VStack(spacing: 0) {
                            Text(routeMinutes())
                                .scaledFont(size: 18, weight: .black)
                            Text("MIN")
                                .scaledFont(size: 8, weight: .heavy)
                        }
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(settings.accentColor)
                        .cornerRadius(12)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(routeDistance())
                                    .scaledFont(size: 10, weight: .bold)
                                    .foregroundColor(settings.accentColor)
                                
                                Text("•")
                                    .foregroundColor(.gray)
                                
                                Text(arrivalTime())
                                    .scaledFont(size: 10, weight: .medium)
                                    .foregroundColor(.gray)
                            }
                            
                            Text(jobTitle())
                                .scaledFont(size: 14, weight: .bold)
                                .foregroundColor(settings.primaryText)
                                .lineLimit(1)
                            
                            Text(jobLocation())
                                .scaledFont(size: 11)
                                .foregroundColor(settings.secondaryText)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Button(action: openInMaps) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(settings.accentColor)
                                .clipShape(Circle())
                        }
                    }
                    .padding(12)
                    .background(settings.surfaceColor)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 110)
                }
            }
            
        }
        .navigationBarHidden(true)
        .onAppear {
            locationService.requestAuthorization()
            viewModel.updateRegionIfNeeded()
            
            handleMapFocus()
            
            if viewModel.shouldRequestRoute(current: locationService.currentLocation) {
                viewModel.requestRoute()
            }
            mapPosition = MapCameraPosition.region(viewModel.savedRegion ?? viewModel.region)
        }
        .onReceive(locationService.$currentLocation) { _ in
            viewModel.updateRegionIfNeeded()
            if !hasCenteredOnUser, locationService.currentLocation != nil {
                mapPosition = MapCameraPosition.region(viewModel.savedRegion ?? viewModel.region)
                hasCenteredOnUser = true
            }
            if viewModel.shouldRequestRoute(current: locationService.currentLocation) {
                viewModel.requestRoute()
            }
        }
        .onChange(of: mapPosition) { _, newValue in
            viewModel.savedRegion = viewModel.region
        }
        .onChange(of: router.mapFocusJobId) { _, _ in
            handleMapFocus()
        }
    }

    private func handleMapFocus() {
        if let focusId = router.mapFocusJobId {
            focusOnJob(id: focusId)
            router.mapFocusJobId = nil
            viewModel.route = nil
            if viewModel.shouldRequestRoute(current: locationService.currentLocation) {
                viewModel.requestRoute()
            }
        } else {
            if let currentJob = activeJob, currentJob.status.uppercased() != "COMPLETED", currentJob.status.uppercased() != "CANCELLED" {
                // Keep the current selection
            } else {
                selectActiveJob()
            }
        }
    }

    private func routeMinutes() -> String {
        guard let time = viewModel.estimatedTravelTime else { return "--" }
        return String(Int(time / 60))
    }
    
    private func routeDistance() -> String {
        if let route = viewModel.route {
            let miles = route.distance / 1609.34
            return String(format: "%.1f MILES", miles)
        }
        guard let start = locationService.currentLocation, let destination = viewModel.destination else { return "--" }
        let startLoc = CLLocation(latitude: start.latitude, longitude: start.longitude)
        let destLoc = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        let miles = startLoc.distance(from: destLoc) / 1609.34
        return String(format: "%.1f MILES", miles)
    }

    private func arrivalTime() -> String {
        guard let time = viewModel.estimatedTravelTime else { return "--" }
        let arrival = Date().addingTimeInterval(time)
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: arrival)
    }

    private func jobTitle() -> String {
        guard let job = activeJob else { return "No destination" }
        return job.title
    }

    private func jobLocation() -> String {
        if let job = activeJob {
            return job.location
        }
        guard let destination = viewModel.destination else { return "" }
        return String(format: "%.4f, %.4f", destination.latitude, destination.longitude)
    }

    private var shouldShowTripCard: Bool {
        viewModel.destination != nil || viewModel.route != nil
    }

    private func centerOnUser() {
        if let current = locationService.currentLocation {
            var region = viewModel.region
            region.center = current
            viewModel.region = region
            mapPosition = .region(region)
        }
    }

    private func openInMaps() {
        guard let destination = viewModel.destination else { return }
        let mapItem: MKMapItem
        if #available(iOS 26.0, *) {
            let location = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
            mapItem = MKMapItem(location: location, address: nil)
        } else {
            mapItem = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        }
        mapItem.name = jobTitle()
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    private func selectActiveJob() {
        guard let user = appSession.currentUser else { return }
        let jobs = localStorage.fetchJobs(organizationId: user.organizationId)
            .filter { $0.assignedUserId == user.id && $0.status.uppercased() != "COMPLETED" && $0.status.uppercased() != "CANCELLED" }
            .sorted { $0.scheduledAt < $1.scheduledAt }

        activeJob = jobs.first
        updateSelection(activeJob)
    }

    private func focusOnJob(id: String) {
        if let job = localStorage.fetchJob(id: id) {
            activeJob = job
            updateSelection(job)
        }
    }

    private func updateSelection(_ job: Job?) {
        if let job = job,
           let latitude = job.siteLatitude,
           let longitude = job.siteLongitude {
            let coord = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            viewModel.setDestination(coord)
            
            // Adjust map view to show both user and destination if possible
            if let current = locationService.currentLocation {
                let region = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: (current.latitude + coord.latitude) / 2,
                        longitude: (current.longitude + coord.longitude) / 2
                    ),
                    span: MKCoordinateSpan(
                        latitudeDelta: abs(current.latitude - coord.latitude) * 1.5 + 0.01,
                        longitudeDelta: abs(current.longitude - coord.longitude) * 1.5 + 0.01
                    )
                )
                viewModel.region = region
                mapPosition = .region(region)
            }
        } else {
            viewModel.setDestination(nil)
        }
    }
}

#Preview {
    TechnicianMapView()
        .environmentObject(AppSession())
}
