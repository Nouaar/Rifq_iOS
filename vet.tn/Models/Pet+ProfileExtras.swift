//
//  Pet+ProfileExtras.swift
//  vet.tn
//
//  Created by Mac on 5/11/2025.
//

import Foundation

extension Pet {
    // TODO: Replace these placeholders with real properties in your model/database.
    var ageText: String { "3 years old" }                    // derive from birthDate when you add it
    var height: String { "27 cm" }
    var color: String { "Black & Tan" }
    var microchip: String { "123456789" }
    var birthDateFormatted: String { "Jan 15, 2021" }
    var activeMedication: String? { nil }                    // e.g., "Amoxicillin"
}
