import SwiftUI
import MapKit

struct ManagerMapView: View {
    @EnvironmentObject private var appSession: AppSession
    @ObservedObject var viewModel: MapViewModel
    @ObservedObject private var locationService = LocationService.shared
    @State private var mapPosition: MapCameraPosition
    @State private var hasCenteredOnUser = false
    @State private var technicians: [User] = []
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

                ForEach(technicians) { tech in
                    if let lat = tech.latitude, let lon = tech.longitude {
                        Annotation(tech.displayName, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon)) {
                            VStack(spacing: 4) {
                                Text(tech.displayName)
                                    .scaledFont(size: 9, weight: .bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .shadow(radius: 2)
                                
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.elevateDarkGreen)
                                    .background(Circle().fill(Color.white))
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
                .background(Color.white)
            
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
            loadTechnicians()
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
}

#Preview {
    ManagerMapView()
        .environmentObject(AppSession())
}
