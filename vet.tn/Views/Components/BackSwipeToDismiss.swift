//
//  BackSwipeToDismiss.swift
//  vet.tn
//
//  Created by Mac on 4/11/2025.
//

import Foundation
import SwiftUI

// BackSwipeToDismiss.swift
import SwiftUI

// BackSwipe.swift
import SwiftUI

struct BackSwipe: ViewModifier {
    let edgeWidth: CGFloat
    let trigger: CGFloat
    let onBack: () -> Void

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onEnded { value in
                        let startX = value.startLocation.x
                        let dx = value.translation.width
                        let dy = value.translation.height
                        if startX <= edgeWidth && dx > trigger && abs(dy) < 60 {
                            onBack()
                        }
                    }
            )
    }
}

extension View {
    /// Swipe depuis le bord gauche pour déclencher une action "back" personnalisée.
    func backSwipe(edgeWidth: CGFloat = 24, trigger: CGFloat = 80, onBack: @escaping () -> Void) -> some View {
        modifier(BackSwipe(edgeWidth: edgeWidth, trigger: trigger, onBack: onBack))
    }
}
