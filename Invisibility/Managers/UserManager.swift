//
//  UserManager.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 3/4/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation
import KeychainAccess
import OSLog
import SwiftUI

struct User: Decodable {
    var object: String
    var id: String
    var email: String
    var firstName: String?
    var lastName: String?
    var emailVerified: Bool?
    var profilePictureUrl: String?
    var createdAt: Date
    var updatedAt: Date

    private enum CodingKeys: String, CodingKey {
        case object, id, email, emailVerified
        case firstName = "first_name"
        case lastName = "last_name"
        case profilePictureUrl = "profile_picture_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

@Observable
final class UserManager: ObservableObject {
    static let shared = UserManager()

    private let logger = Logger(subsystem: "so.invisibility.app", category: "LLMManager")
    private let keychain = Keychain(service: "so.invisibility.app")

    private let tokenKey = "invis_jwt"

    var user: User?
    var token: String? {
        get {
            // Try to get the token from the keychain
            do {
                return try keychain.get(tokenKey)
            } catch {
                // Handle any errors (e.g., item not found, access denied)
                logger.error("Keychain read error: \(error)")
                return nil
            }
        }

        set {
            // newValue is the new value of token
            do {
                if let newValue {
                    // Set the token in the keychain
                    try keychain.set(newValue, key: tokenKey)
                } else {
                    // Remove the token from the keychain if newValue is nil
                    try keychain.remove(tokenKey)
                }
            } catch {
                // Handle any errors (e.g., unable to save, access denied)
                logger.error("Keychain write error: \(error)")
            }
        }
    }

    private init() {}

    func setup() async {
        if await userIsLoggedIn() {
            logger.info("User is logged in")
        } else {
            logger.info("User is not logged in")
        }
    }

    func userIsLoggedIn() async -> Bool {
        guard token != nil else {
            return false
        }
        if await getUser() != nil {
            return true
        } else {
            return false
        }
    }

    func getUser() async -> User? {
        guard token != nil else {
            return nil
        }
        if self.user != nil {
            return self.user
        }
        if let user = await fetchUser() {
            self.user = user
            return user
        } else {
            return nil
        }
    }

    func fetchUser() async -> User? {
        let urlString = "https://cloak.invisibility.so/auth/user"
        guard let url = URL(string: urlString) else {
            logger.error("Invalid URL")
            return nil
        }
        guard let jwtToken = self.token else {
            logger.error("No JWT token")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)

            logger.debug("Fetched user data: \(String(data: data, encoding: .utf8) ?? "nil")")

            let decoder = JSONDecoder()

            // Define a custom DateFormatter
            let iso8601Formatter = DateFormatter()
            iso8601Formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            iso8601Formatter.calendar = Calendar(identifier: .iso8601)
            iso8601Formatter.timeZone = TimeZone(secondsFromGMT: 0)
            iso8601Formatter.locale = Locale(identifier: "en_US_POSIX")

            // Setup decoder with the custom date decoding strategy
            decoder.dateDecodingStrategy = .formatted(iso8601Formatter)

            let user = try decoder.decode(User.self, from: data)
            return user
        } catch {
            print("Error fetching user:", error)
            return nil
        }
    }

    func login() {
        // Open the login page in the default browser
        // if let url = URL(string: "https://cloak.invisibility.so/auth/login") {
        if let url = URL(string: "https://courteous-poem-46-staging.authkit.app/") {
            NSWorkspace.shared.open(url)
        }
    }

    func logout() {
        self.token = nil
        self.user = nil
    }
}
