import SwiftUI

struct ReportCard: View {
    let report: Report
    
    var body: some View {
        HStack(spacing: 12) {
            Image(report.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(report.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(report.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                Text(report.status)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.vertical, 2)
            }
        }
        .modifier(CardModifier())
    }
}
