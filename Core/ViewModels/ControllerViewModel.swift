//
//  ControllerViewModel.swift
//  PropPhone
//
//  Created by Claude Code
//

import Foundation
import MultipeerConnectivity

/// ViewModel for Controller mode - manages sending commands to Mimic devices
@Observable
class ControllerViewModel {
    let multipeerService: MultipeerService
    let phoneStorage: CharacterPhoneStorageService
    var discoveredDevices: [PeerDevice] = []
    var connectedDevices: [PeerDevice] = []

    // CharacterPhone selection
    private var selectedPhoneId: UUID?
    var selectedPhone: CharacterPhone? {
        get {
            guard let id = selectedPhoneId else { return nil }
            return phoneStorage.phones.first { $0.id == id }
        }
        set {
            selectedPhoneId = newValue?.id
        }
    }
    var selectedContact: Contact?

    // Screen state tracking
    enum ScreenState { case idle, lockScreen }
    var currentScreenState: ScreenState = .idle

    // Message composition
    var draftMessageText: String = ""
    var draftMessageIsUrgent: Bool = false

    // Legacy draft states (for compatibility during transition)
    var draftCall: CallState?
    var draftNotification: PropNotification?
    var customTime: Date = Date()
    var freezeTime: Bool = false

    init(multipeerService: MultipeerService, phoneStorage: CharacterPhoneStorageService = .shared) {
        self.multipeerService = multipeerService
        self.phoneStorage = phoneStorage

        // Listen for peer discoveries and connections
        multipeerService.onPeerDiscovered = { [weak self] peer in
            self?.handlePeerDiscovered(peer)
        }

        multipeerService.onPeerConnected = { [weak self] peer in
            self?.handlePeerConnected(peer)
        }

        multipeerService.onPeerDisconnected = { [weak self] peer in
            self?.handlePeerDisconnected(peer)
        }
    }

    // MARK: - Connection Management

    func connectTo(device: PeerDevice) {
        multipeerService.invitePeer(device.peerID)
    }

    func disconnectFrom(device: PeerDevice) {
        multipeerService.disconnectPeer(device.peerID)
    }

    private func handlePeerDiscovered(_ peer: PeerDevice) {
        if !discoveredDevices.contains(where: { $0.id == peer.id }) {
            discoveredDevices.append(peer)
        }
    }

    private func handlePeerConnected(_ peer: PeerDevice) {
        if !connectedDevices.contains(where: { $0.id == peer.id }) {
            connectedDevices.append(peer)
        }
        // Remove from discovered list
        discoveredDevices.removeAll { $0.id == peer.id }
    }

    private func handlePeerDisconnected(_ peer: PeerDevice) {
        connectedDevices.removeAll { $0.id == peer.id }
        // Add back to discovered if in range
        if !discoveredDevices.contains(where: { $0.id == peer.id }) {
            discoveredDevices.append(peer)
        }
    }

    // MARK: - Sending Commands

    func triggerCall(_ call: CallState, to devices: [PeerDevice]? = nil) {
        let message = NetworkMessage.triggerCall(call)
        sendMessage(message, to: devices)
    }

    func dismissCall(on devices: [PeerDevice]? = nil) {
        let message = NetworkMessage.dismissCall
        sendMessage(message, to: devices)
    }

    func addNotification(_ notification: PropNotification, to devices: [PeerDevice]? = nil) {
        let message = NetworkMessage.addNotification(notification)
        sendMessage(message, to: devices)
    }

    func removeNotification(id: UUID, from devices: [PeerDevice]? = nil) {
        let message = NetworkMessage.removeNotification(id)
        sendMessage(message, to: devices)
    }

    func clearAllNotifications(on devices: [PeerDevice]? = nil) {
        let message = NetworkMessage.clearAllNotifications
        sendMessage(message, to: devices)
    }

    func updateTime(_ time: Date, freeze: Bool, on devices: [PeerDevice]? = nil) {
        let message = NetworkMessage.updateTime(time, freeze: freeze)
        sendMessage(message, to: devices)
    }

    func switchToLockScreen(on devices: [PeerDevice]? = nil) {
        currentScreenState = .lockScreen
        let message = NetworkMessage.switchToLockScreen
        sendMessage(message, to: devices)
    }

    func switchToIdle(on devices: [PeerDevice]? = nil) {
        currentScreenState = .idle
        let message = NetworkMessage.switchToIdle
        sendMessage(message, to: devices)
    }

    func setScreenBlackout(_ blackout: Bool, on devices: [PeerDevice]? = nil) {
        let message = NetworkMessage.setScreenBlackout(blackout)
        sendMessage(message, to: devices)
    }

    private func sendMessage(_ message: NetworkMessage, to devices: [PeerDevice]? = nil) {
        let targetDevices = devices ?? connectedDevices
        let peers = targetDevices.map { $0.peerID }
        multipeerService.send(message, to: peers)
    }

    // MARK: - Draft Helpers

    func createDraftCall() {
        draftCall = CallState(
            callerName: "",
            callerNumber: nil,
            callerPhotoURL: "person.circle.fill",
            isVideo: false
        )
    }

    func createDraftNotification() {
        draftNotification = PropNotification(
            appName: "Messages",
            appIcon: "message.fill",
            title: "",
            body: "",
            isUrgent: false
        )
    }

    // MARK: - CharacterPhone Actions

    /// Load a phone's configuration onto connected Mimic devices
    func loadPhone(_ phone: CharacterPhone, on devices: [PeerDevice]? = nil) {
        selectedPhoneId = phone.id
        selectedContact = nil
        draftMessageText = ""

        let config = phone.toPhoneConfig()
        let message = NetworkMessage.loadPhoneConfig(config)
        sendMessage(message, to: devices)
    }

    /// Trigger a call from a contact
    func callContact(_ contact: Contact, isVideo: Bool = false, on devices: [PeerDevice]? = nil) {
        let call = CallState.from(contact: contact, isVideo: isVideo)
        triggerCall(call, to: devices)
    }

    /// Send a message notification from a contact
    func messageContact(_ contact: Contact, text: String, isUrgent: Bool = false, on devices: [PeerDevice]? = nil) {
        let notification = PropNotification.message(from: contact, text: text, isUrgent: isUrgent)
        addNotification(notification, to: devices)
    }

    /// Send the current draft message from selected contact
    func sendDraftMessage(on devices: [PeerDevice]? = nil) {
        guard let contact = selectedContact, !draftMessageText.isEmpty else { return }
        messageContact(contact, text: draftMessageText, isUrgent: draftMessageIsUrgent, on: devices)
        draftMessageText = ""
        draftMessageIsUrgent = false
    }
}
