import SwiftUI
import MapKit

struct ReportDetailView: View {
    let report: Report

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(report.imageName)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(12)
                    .shadow(radius: 5)

                Text(report.title)
                    .font(.vetTitleFont())
                    .foregroundColor(.vetBackground)

                Text(report.description)
                    .font(.vetTitleFont())
                    .foregroundColor(.secondary)

                Map(coordinateRegion: .constant(MKCoordinateRegion(
                    center: report.location,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )))
                .frame(height: 200)
                .cornerRadius(12)
                .shadow(radius: 4)

                Button("Contacter le refuge") {
                    // Chat action
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding()
        }
        .background(Color.vetBackground.ignoresSafeArea())
        .navigationTitle(report.title)
    }
}
