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
    // static let urlBase = "https://cloak.invisibility.so"
    static let urlBase = "http://localhost:8000"

    private let logger = Logger(subsystem: "so.invisibility.app", category: "LLMManager")

    public var user: User?
    public var isPaid: Bool = false
    public var confettis: Int = 0

    @ObservationIgnored @AppStorage("token") public var token: String? {
        didSet {
            if token != nil {
                Task {
                    await setup()
                }
            }
        }
    }

    private init() {}

    func setup() async {
        if await userIsLoggedIn() {
            self.confettis = 1
            logger.info("User is logged in")
            if await checkPaymentStatus() {
                logger.info("User is paid")
                self.isPaid = true
                self.confettis = 2
            } else {
                logger.info("User is not paid")
                self.pay()
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
        let urlString = UserManager.urlBase + "/auth/user"
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

        let url = UserManager.urlBase + "/pay/paid"

        return await withCheckedContinuation { continuation in
            AF.request(url, method: .get, headers: ["Authorization": "Bearer \(jwtToken)"])
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
        if let url = URL(string: "https://billing.stripe.com/p/login/eVa17KdHk6D62qcbII") {
            NSWorkspace.shared.open(url)
        }
        // guard let token = self.token else {
        //     return
        // }

        // let url = UserManager.urlBase + "/pay/manage"

        // AF.request(url, method: .get, headers: ["Authorization": "Bearer \(token)"])
        //     .validate()
        //     .response { response in
        //         switch response.result {
        //         case .success:
        //             if response.response?.statusCode == 200 {
        //                 // Get url from response body json
        //                 self.logger.info("Got manage url")
        //                 if let data = response.data {
        //                     do {
        //                         let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        //                         if let url = json?["url"] as? String {
        //                             if let url = URL(string: url) {
        //                                 NSWorkspace.shared.open(url)
        //                             }
        //                         }
        //                     } catch {
        //                         self.logger.error("Error parsing manage url")
        //                     }
        //                 }
        //             } else {
        //                 self.logger.error("Error getting manage url")
        //             }
        //         case .failure:
        //             self.logger.error("Error creating billing session")
        //         }
        //     }
    }

    func pay() {
        guard let user = self.user else {
            logger.error("No user")
            return
        }

        if let url = URL(string: UserManager.urlBase + "/pay/checkout?email=\(user.email)") {
            NSWorkspace.shared.open(url)
        }
    }

    func login() {
        // Open the login page in the default browser
        if let url = URL(string: "https://authkit.invisibility.so/") {
            NSWorkspace.shared.open(url)
        }
    }

    func signup() {
        // Open the signup page in the default browser
        if let url = URL(string: "https://authkit.invisibility.so/sign-up") {
            NSWorkspace.shared.open(url)
        }
    }

    func logout() {
        self.token = nil
        self.user = nil
    }
}
