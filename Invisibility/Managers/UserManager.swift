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

struct RefreshTokenResponse: Decodable {
    let token: String
}

final class UserManager: ObservableObject {
    static let shared = UserManager()
    private let logger = SentryLogger(subsystem: AppConfig.subsystem, category: "UserManager")

    @Published public var user: User?
    @Published public var isPaid: Bool = false
    @Published public var confettis: Int = 0
    @Published public var inviteCount: Int = 0
    @Published var isLoggedIn: Bool = false
    
    @AppStorage("token") public var token: String? {
        didSet {
            if token != nil {
                Task {
                    logger.debug("token set, thus triggering setup")
                    await setup()
                }
            }
        }
    }
    
    // TODO: published somehow
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

    var canSendMessages: Bool {
        isPaid || numMessagesLeft > 0
    }

    private init() {
        resetMessagesIfNeeded()
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
        }
    }

    func incrementMessagesSentToday() {
        numMessagesSentToday += 1
        logger.debug("Incremented messages sent today: \(numMessagesSentToday)")
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
        await MessageViewModel.shared.fetchAPI()
        getInviteCount()
    }

    func userIsLoggedIn() async -> Bool {
        guard token != nil else {
            isLoggedIn = false
            logger.debug("User is not logged in")
            return false
        }
        if await getUser() != nil {
            isLoggedIn = true
            logger.debug("User is logged in")
            return true
        } else {
            isLoggedIn = false
            logger.debug("User is not logged in")
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
        self.token = nil
        self.user = nil
        self.isLoggedIn = false
        MessageViewModel.shared.clearAll()
    }
}
