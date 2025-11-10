import SwiftUI

struct CreateReportView: View {
    @State private var description = ""

    var body: some View {
        VStack(spacing: 20) {
            TopBar(title: "New report")
            Button("Ajouter une photo") {
                // Image picker
            }
            .buttonStyle(PrimaryButtonStyle())

            TextField("Décrivez la situation...", text: $description)
                .padding()
                .background(Color.vetBackground.opacity(0.3))
                .cornerRadius(10)

            Button("Envoyer le signalement") {
                // Send logic
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding()
        .background(Color.vetBackground.ignoresSafeArea())
    }
}
