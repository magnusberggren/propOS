//
//  ControlSession.swift
//  PropPhone
//
//  Controller-side session: discovers prop phones, auto-connects,
//  pushes canonical PhoneState snapshots, serves asset bytes, and
//  keeps a live mirror of every phone's actual screen.
//

import Foundation
import MultipeerConnectivity
import Observation

@Observable
final class ControlSession {
    struct Device: Identifiable {
        let peerID: MCPeerID
        var isConnected: Bool
        /// The phone's own report of what it is showing right now.
        var mirror: PhoneState?
        /// Whether cue pushes reach this device.
        var receivesPushes: Bool = true

        var id: String { peerID.displayName }
        var name: String { peerID.displayName }
    }

    private(set) var devices: [Device] = []
    /// The state the controller believes phones should show. Cues mutate this.
    private(set) var canonicalState: PhoneState?
    private(set) var lastError: String?

    private let link: PeerLink

    init() {
        link = PeerLink(role: .controller)
        link.onEvent = { [weak self] event in
            self?.handle(event)
        }
    }

    func start() { link.start() }
    func stop() {
        link.stop()
        devices.removeAll()
    }

    var connectedDevices: [Device] { devices.filter(\.isConnected) }

    // MARK: - State pushing

    /// Load a scene baseline (also the RESET operation).
    func loadState(_ state: PhoneState) {
        var s = state
        s.revision = (canonicalState?.revision ?? 0) + 1
        canonicalState = s
        pushCanonical()
    }

    /// Fire a cue against the canonical state and push the result.
    func fire(_ action: CueAction) {
        guard var s = canonicalState else { return }
        s = PhoneStateReducer.apply(action, to: s)
        s.revision += 1
        canonicalState = s
        pushCanonical()
    }

    private func pushCanonical() {
        guard let state = canonicalState else { return }
        let targets = devices.filter { $0.isConnected && $0.receivesPushes }.map(\.peerID)
        guard !targets.isEmpty else { return }
        link.send(.statePush(state), to: targets)
    }

    func setReceivesPushes(_ value: Bool, for deviceID: String) {
        guard let i = devices.firstIndex(where: { $0.id == deviceID }) else { return }
        devices[i].receivesPushes = value
        if value, let state = canonicalState, devices[i].isConnected {
            link.send(.statePush(state), to: [devices[i].peerID])
        }
    }

    // MARK: - Events

    private func handle(_ event: PeerEvent) {
        switch event {
        case .found(let peer):
            if !devices.contains(where: { $0.peerID == peer }) {
                devices.append(Device(peerID: peer, isConnected: false))
            }
            // Zero-fiddling on set: connect to every prop phone we can see.
            link.invite(peer)

        case .lost(let peer):
            devices.removeAll { $0.peerID == peer && !$0.isConnected }

        case .connected(let peer):
            if let i = devices.firstIndex(where: { $0.peerID == peer }) {
                devices[i].isConnected = true
            } else {
                devices.append(Device(peerID: peer, isConnected: true))
            }
            // A (re)joining phone immediately converges on the canonical state.
            if let state = canonicalState,
               let device = devices.first(where: { $0.peerID == peer }), device.receivesPushes {
                link.send(.statePush(state), to: [peer])
            }

        case .disconnected(let peer):
            if let i = devices.firstIndex(where: { $0.peerID == peer }) {
                devices[i].isConnected = false
                devices[i].mirror = nil
            }

        case .message(let message, let peer):
            switch message {
            case .mirror(let state):
                if let i = devices.firstIndex(where: { $0.peerID == peer }) {
                    devices[i].mirror = state
                }
            case .requestAssets(let refs):
                for ref in refs { link.sendAsset(ref, to: peer) }
            case .ping:
                link.send(.pong, to: [peer])
            case .hello, .statePush, .mirror, .pong:
                break
            }

        case .receivedAsset:
            break

        case .error(let text):
            lastError = text
        }
    }
}
