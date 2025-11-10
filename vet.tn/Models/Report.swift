import Foundation
import CoreLocation
import SwiftUI

struct Report: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String
    let location: CLLocationCoordinate2D
    let status: String
}
