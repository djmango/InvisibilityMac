//
//  TextViewModel.swift
//  Invisibility
//
//  Created by Sulaiman Ghori on 4/9/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import Foundation
import SwiftUI



final class HoverTrackerModel: ObservableObject {
    static let shared = HoverTrackerModel()

    // The text content of the chat field
    public var targetType: HoverItemType = .nil_
    public var targetItem: String? = nil

    private init() {}
}
