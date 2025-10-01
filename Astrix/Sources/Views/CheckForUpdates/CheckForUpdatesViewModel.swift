//
//  CheckForUpdatesViewModel.swift
//  Astrix
//
//  Created by Thom van den Broek on 01/10/2025.
//

import SwiftUI
import Sparkle

class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false

    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
}
