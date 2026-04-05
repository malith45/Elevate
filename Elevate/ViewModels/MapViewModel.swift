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

    private let locationService = LocationService.shared

    func setDestination(_ coordinate: CLLocationCoordinate2D) {
        destination = coordinate
    }

    func updateRegionIfNeeded() {
        if let current = locationService.currentLocation {
            region.center = current
        } else if let destination = destination {
            region.center = destination
        }
    }

    func requestRoute() {
        guard let start = locationService.currentLocation, let destination = destination else { return }
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, _ in
            DispatchQueue.main.async {
                self?.route = response?.routes.first
            }
        }
    }
}
