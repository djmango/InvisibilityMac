//
//  TabViewModel.swift
//  Gravity
//
//  Created by Sulaiman Ghori on 1/24/24.
//

import Foundation

class TabViewModel: ObservableObject {
    static let shared = TabViewModel()

    @Published var tabs: [String] = []
    @Published var selectedTab: Int = 0

    private init() {}
}
