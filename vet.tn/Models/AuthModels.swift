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
    }

    init(id: String, email: String, name: String?, avatarUrl: String?, isVerified: Bool? = nil) {
        self.id = id
        self.email = email
        self.name = name
        self.avatarUrl = avatarUrl
        self.isVerified = isVerified
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
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(email, forKey: .email)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(avatarUrl, forKey: .avatarUrl)
        try c.encodeIfPresent(isVerified, forKey: .isVerified)
    }
}

struct AuthResponse: Codable {
    let user: AppUser
    let tokens: AuthTokens
}
