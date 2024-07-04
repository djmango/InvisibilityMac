//
//  WhatsNewFeature.swift
//  Invisibility
//
//  Created by Braeden Hall on 7/4/24.
//  Copyright © 2024 Invisibility Inc. All rights reserved.
//

import SwiftUI

struct WhatsNewFeature: Identifiable, Hashable {
    let id = UUID()
    let iconName: String
    let iconColor: Color
    let title: String
    let description: String
}
