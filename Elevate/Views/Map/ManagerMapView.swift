import SwiftUI
import MapKit
import Combine

struct ManagerMapView: View {
    @EnvironmentObject private var appSession: AppSession
    @ObservedObject var viewModel: MapViewModel
    @ObservedObject private var locationService = LocationService.shared
    @State private var mapPosition: MapCameraPosition
    @State private var hasCenteredOnUser = false
    @State private var technicians: [User] = []
    @State private var mockTechnicians: [User] = []
    @State private var useMockData: Bool = true
    @State private var timer: Timer? = nil
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
                if let current = locationService.currentLocation {
                    Annotation("You", coordinate: current) {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    }
                }

                if let destination = viewModel.destination {
                    Marker("Destination", coordinate: destination)
                        .tint(settings.accentColor)
                }

                let techsToDisplay = useMockData ? mockTechnicians : technicians
                ForEach(techsToDisplay) { tech in
                    if let lat = tech.latitude, let lon = tech.longitude {
                        Annotation(tech.displayName, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                            VStack(spacing: 4) {
                                Text(tech.displayName)
                                    .scaledFont(size: 9, weight: .bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(settings.surfaceColor)
                                    .foregroundColor(settings.primaryText)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(settings.cardStroke, lineWidth: settings.cardStrokeWidth)
                                    )
                                    .shadow(radius: 2)
                                
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(settings.accentColor)
                                    .background(Circle().fill(settings.surfaceColor))
                            }
                        }
                    }
                }
            }
            .mapControls {
                MapUserLocationButton()
            }
            .ignoresSafeArea()
            
            // Header
            BrandHeaderNav(showOnlineStatus: false, isManager: true)
                .background(settings.surfaceColor)
            
            VStack {
                Spacer()

                HStack {
                    Spacer()

                    VStack(spacing: 12) {
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
                    }
                    .padding(.bottom, 120)
                    .padding(.trailing, 20)
                }
            }
            
        }
        .navigationBarHidden(true)
        .onAppear {
            locationService.requestAuthorization()
            viewModel.updateRegionIfNeeded()
            loadTechnicians()
            mapPosition = MapCameraPosition.region(viewModel.savedRegion ?? viewModel.region)
        }
        .onReceive(locationService.$currentLocation) { _ in
            viewModel.updateRegionIfNeeded()
            if !hasCenteredOnUser, locationService.currentLocation != nil {
                mapPosition = MapCameraPosition.region(viewModel.savedRegion ?? viewModel.region)
                hasCenteredOnUser = true
                generateMockTechnicians()
            }
            if viewModel.shouldRequestRoute(current: locationService.currentLocation) {
                viewModel.requestRoute()
            }
        }
        .onReceive(Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()) { _ in
            if useMockData {
                updateMockLocations()
            }
        }
        .onChange(of: mapPosition) { _, newValue in
            viewModel.savedRegion = viewModel.region
        }
    }

    private func loadTechnicians() {
        guard let user = appSession.currentUser else { return }
        technicians = localStorage.fetchUsers(organizationId: user.organizationId)
            .filter { $0.role.uppercased() == "TECHNICIAN" }
    }

    private func centerOnUser() {
        if let current = locationService.currentLocation {
            var region = viewModel.region
            region.center = current
            viewModel.region = region
            mapPosition = .region(region)
        }
    }
    
    private func generateMockTechnicians() {
        let center = locationService.currentLocation ?? CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612)
        let names = ["Alex T.", "Sam K.", "Jordan R.", "Taylor W.", "Casey M."]
        
        mockTechnicians = names.enumerated().map { index, name in
            let offsetLat = Double.random(in: -0.01...0.01)
            let offsetLon = Double.random(in: -0.01...0.01)
            return User(
                id: "mock_\(index)",
                organizationId: "mock_org",
                username: "mock_user_\(index)",
                displayName: name,
                role: "TECHNICIAN",
                email: "mock@example.com",
                phone: "555-010\(index)",
                latitude: center.latitude + offsetLat,
                longitude: center.longitude + offsetLon,
                notificationsEnabled: true
            )
        }
    }
    
    private func updateMockLocations() {
        mockTechnicians = mockTechnicians.map { tech in
            let latJitter = Double.random(in: -0.0005...0.0005)
            let lonJitter = Double.random(in: -0.0005...0.0005)
            return User(
                id: tech.id,
                organizationId: tech.organizationId,
                username: tech.username,
                displayName: tech.displayName,
                role: tech.role,
                email: tech.email,
                phone: tech.phone,
                latitude: (tech.latitude ?? 0) + latJitter,
                longitude: (tech.longitude ?? 0) + lonJitter,
                notificationsEnabled: tech.notificationsEnabled
            )
        }
    }
}

#Preview {
    ManagerMapView()
        .environmentObject(AppSession())
}
