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
import RollbarNotifier
import SwiftUI

struct RefreshTokenResponse: Decodable {
    let token: String
}

final class UserManager: ObservableObject {
    static let shared = UserManager()
    private let logger = InvisibilityLogger(subsystem: AppConfig.subsystem, category: "UserManager")

    public let sessionId: String

    @Published public var user: User?
    @Published public var isPaid: Bool = false
    @Published public var confettis: Int = 0
    @Published public var inviteCount: Int = 0

    @Published var isLoginStatusChecked: Bool = false
    @Published var isLoggedIn: Bool = false

    @Published private(set) var canSendMessages: Bool = false {
        didSet {
            if canSendMessages != oldValue {
                logger.debug("canSendMessages changed from \(oldValue) to \(canSendMessages)")
            }
        }
    }

    @AppStorage("token") public var token: String?
    @AppStorage("numMessagesSentToday") public var numMessagesSentToday: Int = 0
    @AppStorage("lastResetDate") public var lastResetDate: String = "" {
        didSet {
            if lastResetDate.isEmpty {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                lastResetDate = dateFormatter.string(from: Date())
            }
        }
    }

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

    private init() {
        self.sessionId = UUID().uuidString
        logger.debug("Using session id: \(sessionId)")
        resetMessagesIfNeeded()
    }

    private func updateCanSendMessages() {
        // canSendMessages = isPaid || numMessagesLeft > 0
        canSendMessages = isPaid
    }

    private func resetMessagesIfNeeded() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())

        if lastResetDate.isEmpty {
            lastResetDate = today
        }

        if lastResetDate != today {
            numMessagesSentToday = 0
            lastResetDate = today
            updateCanSendMessages()
        }
    }

    func incrementMessagesSentToday() {
        numMessagesSentToday += 1
        updateCanSendMessages()
        logger.debug("Incremented messages sent today: \(numMessagesSentToday)")
        logger.debug("Messages left: \(numMessagesLeft)")
        logger.debug("Can send messages: \(canSendMessages)")
    }

    @MainActor
    func setup() async {
        resetMessagesIfNeeded()
        if await userIsLoggedIn() {
            self.confettis = 1
            if let user {
                // Identify for logs
                PostHogSDK.shared.identify(
                    user.email,
                    userProperties: ["name": "\(user.firstName ?? "") \(user.lastName ?? "")", "email": user.email, "id": user.id]
                )

                // And crash reporting
                let config = RollbarConfig.mutableConfig(withAccessToken: AppConfig.rollbar_key)
                config.setPersonId(user.id, username: "\(user.firstName ?? "") \(user.lastName ?? "")", email: user.email)
                Rollbar.initWithConfiguration(config)
            }
            if await checkPaymentStatus() {
                self.isPaid = true
                self.confettis = 2

            } else {
                self.isPaid = false
            }
        }
        updateCanSendMessages()
        LLMManager.shared.setup()
        await MessageViewModel.shared.fetchAPI()
        getInviteCount()
    }

    @MainActor
    func userIsLoggedIn() async -> Bool {
        guard token != nil else {
            isLoggedIn = false
            logger.debug("User is not logged in")
            isLoginStatusChecked = true
            return false
        }
        if await getUser() != nil {
            isLoggedIn = true
            logger.debug("User is logged in")
            isLoginStatusChecked = true
            return true
        } else {
            isLoggedIn = false
            logger.debug("User is not logged in")
            isLoginStatusChecked = true
            return false
        }
    }

    @MainActor
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

    @MainActor
    func fetchUser() async throws -> User? {
        let urlString = AppConfig.invisibility_api_base + "/auth/user"
        guard let jwtToken = self.token else {
            logger.warning("No JWT token")
            return nil
        }

        return try await withCheckedThrowingContinuation { continuation in
            AF.request(urlString, method: .get, headers: ["Authorization": "Bearer \(jwtToken)"])
                .validate()
                .responseDecodable(of: User.self, decoder: iso8601Decoder()) { response in
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

    @MainActor
    func checkPaymentStatus() async -> Bool {
        guard let jwtToken = self.token else {
            logger.warning("No JWT token")
            logger.debug("User is not paid")
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
                            // self.logger.debug("User is paid")
                            continuation.resume(returning: true)
                        } else {
                            self.logger.debug("User is not paid")
                            continuation.resume(returning: false)
                        }
                    case .failure:
                        self.logger.warning("User is not paid because of failure")
                        continuation.resume(returning: false)
                    }
                }
        }
    }

    @MainActor
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
                // self.logger.debug("Fetched \(userInvites.count) invites")
                case .failure:
                    self.logger.error("Error fetching invites")
                }
            }
    }

    func manage() {
        defer { PostHogSDK.shared.capture("manage_stripe") }
        if let url = URL(string: "https://billing.stripe.com/p/login/eVa17KdHk6D62qcbII") {
            NSWorkspace.shared.open(url)
        }
    }

    func pay() {
        guard let user = self.user else {
            logger.error("No user for payment")
            return
        }

        defer { PostHogSDK.shared.capture("pay", properties: ["num_messages_left": numMessagesLeft]) }

        if let url = URL(string: AppConfig.invisibility_api_base + "/pay/checkout?email=\(user.email)") {
            NSWorkspace.shared.open(url)
            Task { await WindowManager.shared.hideWindow() }
        }
    }

    func login() {
        defer { PostHogSDK.shared.capture("login") }
        // Open the login page in the default browser
        if let url = URL(string: AppConfig.invisibility_api_base + "/auth/login") {
            NSWorkspace.shared.open(url)
        }
    }

    func signup() {
        defer { PostHogSDK.shared.capture("signup") }
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
                                DispatchQueue.main.async {
                                    self.token = refreshTokenResponse.token
                                }
                                if await self.userIsLoggedIn() {
                                    self.logger.debug("Token refreshed")
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

    @MainActor
    func logout() {
        defer { PostHogSDK.shared.capture("logout", properties: ["num_messages_left": numMessagesLeft]) }
        self.isLoggedIn = false
        self.token = nil
        self.user = nil
        MessageViewModel.shared.clearAll()
    }
}
