//
//  Pet+ProfileExtras.swift
//  vet.tn
//
//  Created by Mac on 5/11/2025.
//

import Foundation

extension Pet {
    // Additional computed properties that don't conflict with the main model
    
    // Convenience property for microchip (matches the model's microchipId)
    var microchip: String {
        microchipId ?? "—"
    }
    
    // Format birth date from age (if we had birthDate, we'd use that)
    // For now, this is a placeholder since we only have age
    var birthDateFormatted: String {
        // Since we only have age, we can't calculate exact birth date
        // This is kept for backward compatibility with views that might use it
        "—"
    }
    
    // Get first active medication name (if any)
    var activeMedication: String? {
        medicalHistory?.currentMedications?.first?.name
    }
}
