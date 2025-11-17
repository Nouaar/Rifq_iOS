//
//  AuthModels.swift
//  vet.tn
//
//  Created by Mac on 7/11/2025.
//

import Foundation

struct AuthTokens: Codable {
    let accessToken: String
    let refreshToken: String
}

struct AppUser: Codable {
    let id: String
    let email: String
    let name: String?
    let avatarUrl: String?
    let isVerified: Bool?
    let phone: String?
    let country: String?
    let city: String?
    let pets: [UserPet]?
    let hasPhoto: Bool?
    let hasPets: Bool?
    let role: String? // Role: 'owner', 'vet', 'sitter', 'admin'
    let latitude: Double?
    let longitude: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case _id
        case email
        case name
        case avatarUrl
        case profileImage
        case isVerified
        case verified
        case emailVerified
        case phone
        case phoneNumber
        case mobile
        case country
        case countryName
        case countryCode
        case city
        case locationCity
        case pets
        case hasPhoto
        case hasPets
        case role
        case latitude
        case longitude
    }

    init(
        id: String,
        email: String,
        name: String?,
        avatarUrl: String?,
        isVerified: Bool? = nil,
        phone: String? = nil,
        country: String? = nil,
        city: String? = nil,
        pets: [UserPet]? = nil,
        hasPhoto: Bool? = nil,
        hasPets: Bool? = nil,
        role: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.avatarUrl = avatarUrl
        self.isVerified = isVerified
        self.phone = phone
        self.country = country
        self.city = city
        self.pets = pets
        self.hasPhoto = hasPhoto
        self.hasPets = hasPets
        self.role = role
        self.latitude = latitude
        self.longitude = longitude
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        // id can be "id" or "_id"
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

        self.email = try c.decode(String.self, forKey: .email)
        self.name = try? c.decode(String.self, forKey: .name)

        // avatarUrl can be "avatarUrl" or "profileImage"
        if let avatar = try? c.decode(String.self, forKey: .avatarUrl) {
            self.avatarUrl = avatar
        } else if let profile = try? c.decode(String.self, forKey: .profileImage) {
            self.avatarUrl = profile
        } else {
            self.avatarUrl = nil
        }

        // isVerified could be "isVerified", "verified", or "emailVerified"
        if let v = try? c.decode(Bool.self, forKey: .isVerified) {
            self.isVerified = v
        } else if let v = try? c.decode(Bool.self, forKey: .verified) {
            self.isVerified = v
        } else if let v = try? c.decode(Bool.self, forKey: .emailVerified) {
            self.isVerified = v
        } else {
            self.isVerified = nil
        }

        // Optional profile details
        if let phone = try? c.decode(String.self, forKey: .phone) {
            self.phone = phone
        } else if let phone = try? c.decode(String.self, forKey: .phoneNumber) {
            self.phone = phone
        } else if let phone = try? c.decode(String.self, forKey: .mobile) {
            self.phone = phone
        } else {
            self.phone = nil
        }

        if let country = try? c.decode(String.self, forKey: .country) {
            self.country = country
        } else if let country = try? c.decode(String.self, forKey: .countryName) {
            self.country = country
        } else if let country = try? c.decode(String.self, forKey: .countryCode) {
            self.country = country
        } else {
            self.country = nil
        }

        if let city = try? c.decode(String.self, forKey: .city) {
            self.city = city
        } else if let city = try? c.decode(String.self, forKey: .locationCity) {
            self.city = city
        } else {
            self.city = nil
        }

        self.pets = try? c.decode([UserPet].self, forKey: .pets)
        self.hasPhoto = try? c.decode(Bool.self, forKey: .hasPhoto)
        self.hasPets = try? c.decode(Bool.self, forKey: .hasPets)
        self.role = try? c.decode(String.self, forKey: .role)
        self.latitude = try? c.decode(Double.self, forKey: .latitude)
        self.longitude = try? c.decode(Double.self, forKey: .longitude)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(email, forKey: .email)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(avatarUrl, forKey: .avatarUrl)
        try c.encodeIfPresent(isVerified, forKey: .isVerified)
        try c.encodeIfPresent(phone, forKey: .phoneNumber)
        try c.encodeIfPresent(country, forKey: .country)
        try c.encodeIfPresent(city, forKey: .city)
        try c.encodeIfPresent(pets, forKey: .pets)
        try c.encodeIfPresent(hasPhoto, forKey: .hasPhoto)
        try c.encodeIfPresent(hasPets, forKey: .hasPets)
        try c.encodeIfPresent(role, forKey: .role)
        try c.encodeIfPresent(latitude, forKey: .latitude)
        try c.encodeIfPresent(longitude, forKey: .longitude)
    }

    func updating(
        name: String? = nil,
        avatarUrl: String? = nil,
        phone: String? = nil,
        country: String? = nil,
        city: String? = nil,
        pets: [UserPet]? = nil,
        hasPhoto: Bool? = nil,
        hasPets: Bool? = nil,
        role: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) -> AppUser {
        AppUser(
            id: id,
            email: email,
            name: name ?? self.name,
            avatarUrl: avatarUrl ?? self.avatarUrl,
            isVerified: isVerified,
            phone: phone ?? self.phone,
            country: country ?? self.country,
            city: city ?? self.city,
            pets: pets ?? self.pets,
            hasPhoto: hasPhoto ?? self.hasPhoto,
            hasPets: hasPets ?? self.hasPets,
            role: role ?? self.role,
            latitude: latitude ?? self.latitude,
            longitude: longitude ?? self.longitude
        )
    }
}

struct AuthResponse: Codable {
    let user: AppUser
    let tokens: AuthTokens
}

struct UserPet: Codable, Identifiable {
    let id: String?
    let name: String?

    init(id: String? = nil, name: String? = nil) {
        self.id = id
        self.name = name
    }
}
