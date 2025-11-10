//
//  HelpView.swift
//  vet.tn
//
//  Created by Mac on 3/11/2025.
//

import Foundation
import SwiftUI

struct HelpView: View {
    var body: some View {
        VStack(spacing: 0) {
            TopBar(title: "Help")
            ScrollView {
            VStack(spacing: 20) {
                Text("Need Help?")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.vetTitle)

                Text("""
                If you encounter any issue while using vet.tn, 
                you can reach our support team via:
                • Email: support@vet.tn
                • Phone: +216 71 000 000
                """)
                .foregroundColor(.vetSubtitle)
                .multilineTextAlignment(.center)
                .padding()

                Spacer()
            }
            .padding(.top, 40)
            }
        }
        .background(Color.vetBackground.ignoresSafeArea())
    }
}

#Preview {
    HelpView()
}
