//
//  AppViewModel.swift
//  PropPhone
//
//  Created by Claude Code
//

import Foundation
import SwiftUI

/// Root app view model managing mode selection and global state
@Observable
class AppViewModel {
    var currentMode: AppMode?
    var multipeerService: MultipeerService?
    var controllerVM: ControllerViewModel?
    var mimicVM: MimicViewModel?

    init() {
        // Start with no mode selected
        self.currentMode = nil
    }

    /// Switch to a new mode (Controller, Mimic, or Demo)
    func switchMode(to mode: AppMode) {
        // Clean up existing mode
        cleanup()

        // Set new mode
        currentMode = mode

        // Demo mode doesn't need MultipeerService
        if mode == .demo {
            // Demo mode has no ViewModels - just shows UI directly
            return
        }

        // Initialize MultipeerService with the selected mode
        let service = MultipeerService(mode: mode)
        multipeerService = service

        // Initialize appropriate ViewModel
        switch mode {
        case .controller:
            controllerVM = ControllerViewModel(multipeerService: service)
            mimicVM = nil
        case .mimic:
            mimicVM = MimicViewModel(multipeerService: service)
            controllerVM = nil
        case .demo:
            // Already handled above
            break
        }

        // Start the service
        service.start()
    }

    /// Return to mode selection
    func returnToModeSelection() {
        cleanup()
        currentMode = nil
    }

    /// Clean up current mode and connections
    private func cleanup() {
        multipeerService?.stop()
        multipeerService = nil
        controllerVM = nil
        mimicVM = nil
    }
}
