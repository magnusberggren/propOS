//
//  PhoneSession.swift
//  PropPhone
//
//  Prop-phone-side session: advertises, accepts the controller,
//  renders whatever state was last pushed, requests missing assets,
//  and mirrors local interactions back.
//

import Foundation
import MultipeerConnectivity
import Observation

@Observable
final class PhoneSession {
    let runtime: PhoneRuntime
    private(set) var isConnected = false
    private(set) var controllerName: String?

    private let link: PeerLink
    private var mirrorPending = false

    init(initialState: PhoneState) {
        runtime = PhoneRuntime(state: initialState)
        link = PeerLink(role: .phone)
        link.onEvent = { [weak self] event in
            self?.handle(event)
        }
        runtime.onLocalMutation = { [weak self] state in
            self?.scheduleMirror(state)
        }
    }

    func start() { link.start() }
    func stop() { link.stop() }

    private func handle(_ event: PeerEvent) {
        switch event {
        case .connected(let peer):
            isConnected = true
            controllerName = peer.displayName
            link.send(.hello(deviceName: link.myPeerID.displayName, role: .phone), to: [peer])
            scheduleMirror(runtime.state)

        case .disconnected:
            isConnected = false
            controllerName = nil

        case .message(let message, let peer):
            switch message {
            case .statePush(let state):
                runtime.applyExternal(state)
                requestMissingAssets(for: state)
                // Confirm what we now show (also refreshes the mirror thumbnail).
                link.send(.mirror(runtime.state), to: [peer])
            case .ping:
                link.send(.pong, to: [peer])
            case .hello, .mirror, .requestAssets, .pong:
                break
            }

        case .receivedAsset:
            runtime.assetsDidChange()

        case .found, .lost, .error:
            break
        }
    }

    private func requestMissingAssets(for state: PhoneState) {
        let missing = AssetStore.shared.missing(from: state.referencedAssets)
        guard !missing.isEmpty else { return }
        link.send(.requestAssets(missing))
    }

    /// Coalesce rapid interaction bursts into ~4 mirror reports per second.
    private func scheduleMirror(_ state: PhoneState) {
        guard isConnected, !mirrorPending else { return }
        mirrorPending = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self else { return }
            self.mirrorPending = false
            self.link.send(.mirror(self.runtime.state))
        }
    }
}
