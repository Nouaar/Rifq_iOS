//
//  StatusBadge.swift
//  vet.tn
//

import SwiftUI

struct StatusBadge: View {
    let status: BookingStatus
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.system(size: 12, weight: .bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(statusColor.opacity(0.15))
            .foregroundColor(statusColor)
            .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch status {
        case .pending:
            return .orange
        case .accepted:
            return .green
        case .rejected:
            return .red
        case .completed:
            return .blue
        case .cancelled:
            return .gray
        }
    }
}

