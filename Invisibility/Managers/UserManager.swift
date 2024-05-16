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

struct UserInvite: Decodable {
    var email: String
    var code: String
    var createdAt: Date

    private enum CodingKeys: String, CodingKey {
        case email
        case code
        case createdAt = "created_at"
    }
}

// Extension for decoding a date in the custom ISO8601 format with nanoseconds
extension DateFormatter {
    static let extendedISO8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSSSX"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}

struct RefreshTokenResponse: Decodable {
    let token: String
}

final class UserManager: ObservableObject {
    static let shared = UserManager()
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "UserManager")

    @Published public var user: User?
    @Published public var isPaid: Bool = true
    @Published public var confettis: Int = 0
    @Published public var inviteCount: Int = 0

    @AppStorage("token") public var token: String? {
        didSet {
            if token != nil {
                Task {
                    await setup()
                }
            }
        }
    }

    @AppStorage("numMessagesSentToday") public var numMessagesSentToday: Int = 0
    @AppStorage("lastResetDate") public var lastResetDate: String = ""

    var inviteLink: String {
        "https://invite.i.inc/\(user?.firstName?.lowercased() ?? "")"
    }

    /// per day free 10 messages + 20 per invite also per day
    var numMessagesAllowed: Int {
        10 + (20 * inviteCount)
    }

    var numMessagesLeft: Int {
        resetMessagesIfNeeded()
        return max(0, numMessagesAllowed - numMessagesSentToday)
    }

    var canSendMessages: Bool {
        numMessagesLeft > 0 || isPaid
    }

    private init() {}

    private func resetMessagesIfNeeded() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())

        if lastResetDate != today {
            numMessagesSentToday = 0
            lastResetDate = today
        }
    }

    @MainActor
    func setup() async {
        resetMessagesIfNeeded()
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
                self.isPaid = false
            }
        }
        LLMManager.shared.setup()
        getInviteCount()
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

    func getInviteCount() {
        // Unwrap the user.firstName safely
        guard let firstName = user?.firstName else {
            logger.warning("User's first name is not available")
            return
        }

        let url = AppConfig.invisibility_api_base + "/pay/list_invites?code=" + firstName.lowercased()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.extendedISO8601)

        AF.request(url, method: .get)
            .validate()
            .responseDecodable(of: [UserInvite].self, decoder: decoder) { response in
                switch response.result {
                case let .success(userInvites):
                    DispatchQueue.main.async {
                        self.inviteCount = userInvites.count
                    }
                    self.logger.info("Fetched \(userInvites.count) invites")
                case .failure:
                    self.logger.error("Error fetching invites")
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

        defer {
            PostHogSDK.shared.capture(
                "send_message", properties: ["email": user.email, "num_messages_left": numMessagesLeft]
            )
        }

        if let url = URL(string: AppConfig.invisibility_api_base + "/pay/checkout?email=\(user.email)") {
            NSWorkspace.shared.open(url)
            Task { await WindowManager.shared.hideWindow() }
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
