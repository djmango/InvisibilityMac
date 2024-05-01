//
//  UserManager.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 3/4/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Alamofire
import Foundation
import OSLog
import PostHog
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

struct RefreshTokenResponse: Decodable {
    let token: String
}

final class UserManager: ObservableObject {
    static let shared = UserManager()
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "LLMManager")

    @Published public var user: User?
    @Published public var isPaid: Bool = false
    @Published public var confettis: Int = 0

    @AppStorage("token") public var token: String? {
        didSet {
            if token != nil {
                Task {
                    await setup()
                }
            }
        }
    }

    private init() {}

    @MainActor
    func setup() async {
        if await userIsLoggedIn() {
            self.confettis = 1
            if let user {
                PostHogSDK.shared.identify(
                    user.email,
                    userProperties: ["name": "\(user.firstName ?? "") \(user.lastName ?? "")", "email": user.email, "id": user.id]
                )
            }
            if await checkPaymentStatus() {
                self.isPaid = true
                self.confettis = 2

            } else {
                self.pay()
            }
        }
        LLMManager.shared.setup()
    }

    func userIsLoggedIn() async -> Bool {
        guard token != nil else {
            logger.info("User is not logged in")
            return false
        }
        if await getUser() != nil {
            logger.info("User is logged in")
            return true
        } else {
            logger.info("User is not logged in")
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
            await MainActor.run {
                self.user = user
            }
            return user
        } else {
            return nil
        }
    }

    func fetchUser() async throws -> User? {
        let urlString = AppConfig.invisibility_api_base + "/auth/user"
        guard let jwtToken = self.token else {
            logger.warning("No JWT token")
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
            logger.warning("No JWT token")
            logger.info("User is not paid")
            return false
        }

        let url = AppConfig.invisibility_api_base + "/pay/paid"

        return await withCheckedContinuation { continuation in
            AF.request(url, method: .get, headers: ["Authorization": "Bearer \(jwtToken)"])
                .validate()
                .response { response in
                    switch response.result {
                    case .success:
                        if response.response?.statusCode == 200 {
                            self.logger.info("User is paid")
                            continuation.resume(returning: true)
                        } else {
                            self.logger.info("User is not paid")
                            continuation.resume(returning: false)
                        }
                    case .failure:
                        self.logger.info("User is not paid")
                        continuation.resume(returning: false)
                    }
                }
        }
    }

    func manage() {
        if let url = URL(string: "https://billing.stripe.com/p/login/eVa17KdHk6D62qcbII") {
            NSWorkspace.shared.open(url)
        }
    }

    func pay() {
        guard let user = self.user else {
            logger.error("No user for payment")
            return
        }

        if let url = URL(string: AppConfig.invisibility_api_base + "/pay/checkout?email=\(user.email)") {
            NSWorkspace.shared.open(url)
        }
    }

    func login() {
        // Open the login page in the default browser
        if let url = URL(string: AppConfig.invisibility_api_base + "/auth/login") {
            NSWorkspace.shared.open(url)
        }
    }

    func signup() {
        // Open the signup page in the default browser
        if let url = URL(string: AppConfig.invisibility_api_base + "/auth/signup") {
            NSWorkspace.shared.open(url)
        }
    }

    func refresh_jwt() async -> Bool {
        guard let jwtToken = self.token else {
            logger.warning("No JWT token to refresh")
            return false
        }

        let url = AppConfig.invisibility_api_base + "/auth/token/refresh"

        return await withCheckedContinuation { continuation in
            AF.request(url, method: .get, headers: ["Authorization": "Bearer \(jwtToken)"])
                .validate()
                .responseDecodable(of: RefreshTokenResponse.self) { response in
                    switch response.result {
                    case let .success(refreshTokenResponse):
                        if response.response?.statusCode == 200 {
                            // Set the new token from the response
                            Task {
                                let oldToken = self.token
                                self.token = refreshTokenResponse.token
                                if await self.userIsLoggedIn() {
                                    self.logger.info("Token refreshed")
                                    continuation.resume(returning: true)
                                } else {
                                    self.token = oldToken
                                    self.logger.error("Error refreshing token, invalid token")
                                    continuation.resume(returning: false)
                                }
                            }
                        } else {
                            self.logger.error("Error refreshing token, status code: \(response.response?.statusCode ?? -1)")
                            continuation.resume(returning: false)
                        }
                    case .failure:
                        self.logger.error("Error refreshing token, response: \(response)")
                        continuation.resume(returning: false)
                    }
                }
        }
    }

    func logout() {
        self.token = nil
        DispatchQueue.main.async {
            self.user = nil
        }
    }
}
