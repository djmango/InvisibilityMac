//
//  UserManager.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 3/4/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Alamofire
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

    public var user: User?
    public var isPaid: Bool = false

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
                    logger.debug("Setting token in keychain")
                    try keychain.set(newValue, key: tokenKey)
                } else {
                    // Remove the token from the keychain if newValue is nil
                    logger.debug("Removing token from keychain")
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
            if await checkPaymentStatus() {
                logger.info("User is paid")
                self.isPaid = true
            } else {
                logger.info("User is not paid")
            }
        } else {
            logger.info("User is not logged in")
        }
        LLMManager.shared.setup()
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
        if let user = try? await fetchUser() {
            self.user = user
            return user
        } else {
            return nil
        }
    }

    func fetchUser() async throws -> User? {
        let urlString = "https://cloak.invisibility.so/auth/user"
        // let urlString = "http://localhost:8000/auth/user"
        guard let jwtToken = self.token else {
            logger.error("No JWT token")
            return nil
        }

        return try await withCheckedThrowingContinuation { continuation in
            AF.request(urlString, method: .get, headers: ["Authorization": "Bearer \(jwtToken)"])
                .validate()
                .responseDecodable(of: User.self, decoder: customDecoder()) { response in
                    switch response.result {
                    case let .success(user):
                        self.logger.debug("Fetched user: \(user.email)")
                        continuation.resume(returning: user)
                    case let .failure(error):
                        self.logger.error("Error fetching user: \(error)")
                        continuation.resume(throwing: error)
                    }
                }
        }

        func customDecoder() -> JSONDecoder {
            let decoder = JSONDecoder()

            // Define a custom DateFormatter
            let iso8601Formatter = DateFormatter()
            iso8601Formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            iso8601Formatter.calendar = Calendar(identifier: .iso8601)
            iso8601Formatter.timeZone = TimeZone(secondsFromGMT: 0)
            iso8601Formatter.locale = Locale(identifier: "en_US_POSIX")

            // Set up the decoder with the custom date decoding strategy
            decoder.dateDecodingStrategy = .formatted(iso8601Formatter)

            return decoder
        }
    }

    func checkPaymentStatus() async -> Bool {
        guard let jwtToken = self.token else {
            logger.error("No JWT token")
            return false
        }

        return await withCheckedContinuation { continuation in
            AF.request("https://cloak.invisibility.so/pay/paid", method: .get, headers: ["Authorization": "Bearer \(jwtToken)"])
                .validate()
                .response { response in
                    switch response.result {
                    case .success:
                        if response.response?.statusCode == 200 {
                            continuation.resume(returning: true)
                        } else {
                            continuation.resume(returning: false)
                        }
                    case .failure:
                        continuation.resume(returning: false)
                    }
                }
        }
    }

    func manage() {
        guard token != nil else {
            return
        }
    }

    func login() {
        // Open the login page in the default browser
        if let url = URL(string: "https://authkit.invisibility.so/") {
            NSWorkspace.shared.open(url)
        }
    }

    func logout() {
        self.token = nil
        self.user = nil
    }
}
