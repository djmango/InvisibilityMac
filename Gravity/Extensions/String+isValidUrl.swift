//
//  String+isValidUrl.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 2/14/24.
//

import Foundation

extension String {
    /// Check if a string is a valid URL, by checking if it can be converted to a URL and if it has a scheme and a host.
    func isValidURL() -> Bool {
        guard let url = URL(string: self),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        else {
            return false
        }

        // Check if the URL has a scheme and a host, which are good indicators of a valid URL.
        // This allows for schemes other than http/https, such as ftp, file, etc.
        return components.scheme != nil && components.host != nil
    }
}
