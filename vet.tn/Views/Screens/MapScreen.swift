import SwiftUI


import MapKit

struct MapScreen: View {
        @State private var region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 36.8065, longitude: 10.1815),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )

        var body: some View {
            Map(coordinateRegion: $region, annotationItems: reportsMock) { report in
                MapMarker(coordinate: report.location, tint: .vetBackground)
            }
            .ignoresSafeArea()
        }
    }


#Preview("MapScreen") {
    MapScreen()
        .environmentObject(ThemeStore())
}
