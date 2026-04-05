import SwiftUI
import MapKit

struct TechnicianMapView: View {
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel = MapViewModel()
    @ObservedObject private var locationService = LocationService.shared
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background Map
            Map(position: .constant(.region(viewModel.region))) {
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
                            
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 28))
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
                
                // Floating Trip Info Card
                HStack(spacing: 16) {
                    // Time Block
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
                    
                    // Navigate Action
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
                .padding(.bottom, 120) // Give space for custom tab bar below it
            }
            
            // Bottom Navbar Floating
            ReusableBottomNav(selectedTab: .constant(.map))
        }
        .navigationBarHidden(true)
        .onAppear {
            locationService.requestAuthorization()
            viewModel.updateRegionIfNeeded()
            viewModel.setDestination(destinationCoordinate())
            viewModel.requestRoute()
        }
        .onReceive(locationService.$currentLocation) { _ in
            viewModel.updateRegionIfNeeded()
            viewModel.requestRoute()
        }
    }

    private func destinationCoordinate() -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
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
        "Job Site"
    }

    private func jobLocation() -> String {
        "Destination"
    }

    private func openInMaps() {
        guard let destination = viewModel.destination else { return }
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        mapItem.name = jobTitle()
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

#Preview {
    TechnicianMapView()
        .environmentObject(AppSession())
}
