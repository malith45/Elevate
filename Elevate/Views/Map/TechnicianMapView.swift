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
                    Annotation("", coordinate: destination) {
                        VStack(spacing: 4) {
                            Text("DESTINATION")
                                .scaledFont(size: 10, weight: .bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.elevateDarkGreen)
                                .cornerRadius(12)
                            
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.elevateDarkGreen)
                                .background(Circle().fill(Color.white).frame(width: 14, height: 14))
                        }
                    }
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
                .background(Color.white)
            
            VStack {
                Spacer()
                
                if shouldShowTripCard {
                    HStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text(routeMinutes())
                                .scaledFont(size: 20, weight: .bold)
                                .foregroundColor(.white)
                            Text("MINS")
                                .scaledFont(size: 10, weight: .bold)
                                .foregroundColor(.white)
                        }
                        .frame(width: 60, height: 60)
                        .background(Color.elevateDarkGreen)
                        .cornerRadius(10)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(routeDistance())
                                    .scaledFont(size: 10, weight: .bold)
                                    .foregroundColor(.elevateDarkGreen)
                                Circle().fill(Color.gray).frame(width: 3, height: 3)
                                Text("ARRIVAL \(arrivalTime())")
                                    .scaledFont(size: 10, weight: .bold)
                                    .foregroundColor(.gray)
                            }

                            Text(jobTitle())
                                .scaledFont(size: 16, weight: .bold)

                            Text(jobLocation())
                                .scaledFont(size: 12)
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        Button(action: openInMaps) {
                            Image(systemName: "arrow.turn.up.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.elevateDarkGreen)
                                .cornerRadius(8)
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 120)
                }
            }

            VStack {
                Spacer()

                HStack {
                    Spacer()

                    VStack(spacing: 10) {
                        Button(action: centerOnUser) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.elevateDarkGreen)
                                .frame(width: 40, height: 40)
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                        }
                    }
                    .padding(.bottom, 260)
                    .padding(.trailing, 20)
                }
            }
            
        }
        .navigationBarHidden(true)
        .onAppear {
            locationService.requestAuthorization()
            viewModel.updateRegionIfNeeded()
            
            if let focusId = router.mapFocusJobId {
                focusOnJob(id: focusId)
                // Clear focus after consumption
                router.mapFocusJobId = nil
            } else {
                selectActiveJob()
            }
            
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
    }

    private func routeMinutes() -> String {
        guard let route = viewModel.route else { return "--" }
        return String(Int(route.expectedTravelTime / 60))
    }

    private func routeDistance() -> String {
        guard let route = viewModel.route else { return "--" }
        let miles = route.distance / 1609.34
        return String(format: "%.1f MILES", miles)
    }

    private func arrivalTime() -> String {
        guard let route = viewModel.route else { return "--" }
        let arrival = Date().addingTimeInterval(route.expectedTravelTime)
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
