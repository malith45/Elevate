import SwiftUI
import MapKit

struct TechnicianMapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background Map
            Map(coordinateRegion: $region, annotationItems: [MapPinItem(coordinate: region.center)]) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    VStack(spacing: 4) {
                        Text("DESTINATION")
                            .font(.system(size: 10, weight: .bold))
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
            .ignoresSafeArea()
            
            // Current Location Mock (Blue dot)
            Circle()
                .fill(Color.blue)
                .frame(width: 16, height: 16)
                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                .shadow(radius: 3)
                .position(x: 100, y: 550) // Mock offset position to mimic image
            
            // Header
            BrandHeaderNav(showOnlineStatus: false)
                .background(Color.white)
            
            VStack {
                Spacer()
                
                // Floating Trip Info Card
                HStack(spacing: 16) {
                    // Time Block
                    VStack(spacing: 2) {
                        Text("12")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        Text("MINS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 60, height: 60)
                    .background(Color.elevateDarkGreen)
                    .cornerRadius(10)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("0.8 MILES")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.elevateDarkGreen)
                            Circle().fill(Color.gray).frame(width: 3, height: 3)
                            Text("ARRIVAL 2:45 PM")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.gray)
                        }
                        
                        Text("HVAC Calibration")
                            .font(.system(size: 16, weight: .bold))
                        
                        Text("Grand Central Mall • Gate 4")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Navigate Action
                    Button(action: {}) {
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
    }
}

struct MapPinItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

#Preview {
    TechnicianMapView()
}
