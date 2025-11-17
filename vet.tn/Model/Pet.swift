//
//  Pet.swift
//  vet.tn
//
//  Created by Mac on 7/11/2025.
//

import Foundation

// MARK: - Pet Model (matches backend API)

struct Pet: Codable, Identifiable {
    let id: String
    let name: String
    let species: String
    let breed: String?
    let age: Double?
    let gender: String?
    let color: String?
    let weight: Double?
    let height: Double?
    let photo: String?
    let microchipId: String?
    let owner: PetOwner?
    let medicalHistory: MedicalHistory?
    
    enum CodingKeys: String, CodingKey {
        case id
        case _id
        case name
        case species
        case breed
        case age
        case gender
        case color
        case weight
        case height
        case photo
        case photoUrl
        case image
        case imageUrl
        case microchipId
        case owner
        case medicalHistory
    }

    init(
        id: String,
        name: String,
        species: String,
        breed: String? = nil,
        age: Double? = nil,
        gender: String? = nil,
        color: String? = nil,
        weight: Double? = nil,
        height: Double? = nil,
        photo: String? = nil,
        microchipId: String? = nil,
        owner: PetOwner? = nil,
        medicalHistory: MedicalHistory? = nil
    ) {
        self.id = id
        self.name = name
        self.species = species
        self.breed = breed
        self.age = age
        self.gender = gender
        self.color = color
        self.weight = weight
        self.height = height
        self.photo = photo
        self.microchipId = microchipId
        self.owner = owner
        self.medicalHistory = medicalHistory
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle id/_id
        if let id = try? c.decode(String.self, forKey: .id) {
            self.id = id
        } else if let id = try? c.decode(String.self, forKey: ._id) {
            self.id = id
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.id,
                .init(codingPath: decoder.codingPath, debugDescription: "Missing id/_id")
            )
        }
        
        self.name = try c.decode(String.self, forKey: .name)
        self.species = try c.decode(String.self, forKey: .species)
        self.breed = try? c.decode(String.self, forKey: .breed)
        self.age = try? c.decode(Double.self, forKey: .age)
        self.gender = try? c.decode(String.self, forKey: .gender)
        self.color = try? c.decode(String.self, forKey: .color)
        self.weight = try? c.decode(Double.self, forKey: .weight)
        self.height = try? c.decode(Double.self, forKey: .height)
        
        // Try multiple possible field names for photo
        if let photo = try? c.decode(String.self, forKey: .photo) {
            self.photo = photo
        } else if let photo = try? c.decode(String.self, forKey: .photoUrl) {
            self.photo = photo
        } else if let photo = try? c.decode(String.self, forKey: .image) {
            self.photo = photo
        } else if let photo = try? c.decode(String.self, forKey: .imageUrl) {
            self.photo = photo
        } else {
            self.photo = nil
        }
        
        self.microchipId = try? c.decode(String.self, forKey: .microchipId)
        self.owner = try? c.decode(PetOwner.self, forKey: .owner)
        self.medicalHistory = try? c.decode(MedicalHistory.self, forKey: .medicalHistory)
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(species, forKey: .species)
        try c.encodeIfPresent(breed, forKey: .breed)
        try c.encodeIfPresent(age, forKey: .age)
        try c.encodeIfPresent(gender, forKey: .gender)
        try c.encodeIfPresent(color, forKey: .color)
        try c.encodeIfPresent(weight, forKey: .weight)
        try c.encodeIfPresent(height, forKey: .height)
        try c.encodeIfPresent(photo, forKey: .photo)
        try c.encodeIfPresent(microchipId, forKey: .microchipId)
        try c.encodeIfPresent(owner, forKey: .owner)
        try c.encodeIfPresent(medicalHistory, forKey: .medicalHistory)
    }
    
    // MARK: - Computed Properties
    
    var emoji: String {
        switch species.lowercased() {
        case "dog": return "🐕"
        case "cat": return "🐈"
        case "bird": return "🐦"
        default: return "🐾"
        }
    }
    
    var ageText: String {
        guard let age = age else { return "Unknown" }
        if age < 1 {
            let months = Int(age * 12)
            return "\(months) month\(months == 1 ? "" : "s") old"
        }
        let years = Int(age)
        return "\(years) year\(years == 1 ? "" : "s") old"
    }
    
    var weightText: String {
        guard let weight = weight else { return "-" }
        return String(format: "%.1f kg", weight)
    }
    
    var heightText: String {
        guard let height = height else { return "-" }
        return String(format: "%.1f cm", height)
    }
    
    var medsCount: Int {
        medicalHistory?.currentMedications?.count ?? 0
    }
}

// MARK: - Pet Owner

struct PetOwner: Codable {
    let id: String?
    let name: String?
    let email: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case _id
        case name
        case email
    }
    
    init(
        id: String? = nil,
        name: String? = nil,
        email: String? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let id = try? c.decode(String.self, forKey: .id) {
            self.id = id
        } else {
            self.id = try? c.decode(String.self, forKey: ._id)
        }
        self.name = try? c.decode(String.self, forKey: .name)
        self.email = try? c.decode(String.self, forKey: .email)
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(email, forKey: .email)
    }
}

// MARK: - Medical History

struct MedicalHistory: Codable {
    let id: String?
    let vaccinations: [String]?
    let chronicConditions: [String]?
    let currentMedications: [Medication]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case _id
        case vaccinations
        case chronicConditions
        case currentMedications
    }
    
    init(
        id: String? = nil,
        vaccinations: [String]? = nil,
        chronicConditions: [String]? = nil,
        currentMedications: [Medication]? = nil
    ) {
        self.id = id
        self.vaccinations = vaccinations
        self.chronicConditions = chronicConditions
        self.currentMedications = currentMedications
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let id = try? c.decode(String.self, forKey: .id) {
            self.id = id
        } else {
            self.id = try? c.decode(String.self, forKey: ._id)
        }
        self.vaccinations = try? c.decode([String].self, forKey: .vaccinations)
        self.chronicConditions = try? c.decode([String].self, forKey: .chronicConditions)
        self.currentMedications = try? c.decode([Medication].self, forKey: .currentMedications)
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(vaccinations, forKey: .vaccinations)
        try c.encodeIfPresent(chronicConditions, forKey: .chronicConditions)
        try c.encodeIfPresent(currentMedications, forKey: .currentMedications)
    }
}

// MARK: - Medication

struct Medication: Codable {
    let name: String
    let dosage: String
}

// MARK: - Create Pet Request

struct CreatePetRequest: Encodable {
    let name: String
    let species: String
    let breed: String?
    let age: Double?
    let gender: String?
    let color: String?
    let weight: Double?
    let height: Double?
    let photo: String?
    let microchipId: String?
    let medicalHistory: MedicalHistoryRequest?
}

struct MedicalHistoryRequest: Encodable {
    let vaccinations: [String]?
    let chronicConditions: [String]?
    let currentMedications: [Medication]?
}

// MARK: - Update Pet Request

struct UpdatePetRequest: Encodable {
    let name: String?
    let species: String?
    let breed: String?
    let age: Double?
    let gender: String?
    let color: String?
    let weight: Double?
    let height: Double?
    let photo: String?
    let microchipId: String?
    let medicalHistory: MedicalHistoryRequest?
}

