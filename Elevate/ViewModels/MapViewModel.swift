import Foundation
import Combine
import CoreLocation
import MapKit

final class MapViewModel: ObservableObject {
    @Published var destination: CLLocationCoordinate2D?
    @Published var route: MKRoute?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @Published var savedRegion: MKCoordinateRegion?

    private var lastRouteRequestAt: Date?
    private var lastRouteLocation: CLLocationCoordinate2D?

    private let locationService = LocationService.shared

    func setDestination(_ coordinate: CLLocationCoordinate2D?) {
        destination = coordinate
    }

    func updateRegionIfNeeded() {
        if let current = locationService.currentLocation {
            region.center = current
        } else if let destination = destination {
            region.center = destination
        }
        savedRegion = region
    }

    func requestRoute() {
        guard let start = locationService.currentLocation, let destination = destination else { return }
        let request = MKDirections.Request()
        if #available(iOS 26.0, *) {
            let startLocation = CLLocation(latitude: start.latitude, longitude: start.longitude)
            let destinationLocation = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
            request.source = MKMapItem(location: startLocation, address: nil)
            request.destination = MKMapItem(location: destinationLocation, address: nil)
        } else {
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        }
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, _ in
            DispatchQueue.main.async {
                self?.route = response?.routes.first
            }
        }
    }

    func shouldRequestRoute(current: CLLocationCoordinate2D?) -> Bool {
        guard destination != nil, let current = current else { return false }

        if let lastRequestAt = lastRouteRequestAt,
           Date().timeIntervalSince(lastRequestAt) < 10 {
            return false
        }

        if let lastLocation = lastRouteLocation {
            let currentLocation = CLLocation(latitude: current.latitude, longitude: current.longitude)
            let lastLocationCoord = CLLocation(latitude: lastLocation.latitude, longitude: lastLocation.longitude)
            if currentLocation.distance(from: lastLocationCoord) < 30 {
                return false
            }
        }

        lastRouteRequestAt = Date()
        lastRouteLocation = current
        return true
    }
}
