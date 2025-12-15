//
//  MultipeerService.swift
//  PropPhone
//
//  Created by Claude Code
//

import Foundation
import MultipeerConnectivity

/// Manages peer-to-peer communication between Controller and Mimic devices
@Observable
class MultipeerService: NSObject {
    // MARK: - Properties

    private let serviceType = "prop-phone"
    private let myPeerID: MCPeerID
    private let mode: AppMode

    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    var isActive = false
    private var discoveredPeers: [MCPeerID: PeerDevice] = [:]

    // MARK: - Callbacks

    var onPeerDiscovered: ((PeerDevice) -> Void)?
    var onPeerLost: ((PeerDevice) -> Void)?
    var onPeerConnected: ((PeerDevice) -> Void)?
    var onPeerDisconnected: ((PeerDevice) -> Void)?
    var onMessageReceived: ((NetworkMessage, MCPeerID) -> Void)?
    var onError: ((Error) -> Void)?

    // MARK: - Initialization

    init(mode: AppMode) {
        self.mode = mode
        // Create unique peer ID with device name and mode
        let deviceName = UIDevice.current.name
        self.myPeerID = MCPeerID(displayName: "\(deviceName) [\(mode.rawValue)]")

        super.init()
    }

    // MARK: - Lifecycle

    func start() {
        guard !isActive else {
            print("⚠️ MultipeerService already active")
            return
        }

        print("🚀 Starting MultipeerService in \(mode.rawValue) mode")
        print("📱 My Peer ID: \(myPeerID.displayName)")

        // Create session
        session = MCSession(
            peer: myPeerID,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        session?.delegate = self

        // Start advertising or browsing based on mode
        switch mode {
        case .mimic:
            print("📡 Starting advertising...")
            startAdvertising()
        case .controller:
            print("🔍 Starting browsing...")
            startBrowsing()
        case .demo:
            print("🎬 Demo mode - no networking needed")
            break
        }

        isActive = true
        print("✅ MultipeerService started successfully")
    }

    func stop() {
        stopAdvertising()
        stopBrowsing()
        session?.disconnect()
        session = nil
        discoveredPeers.removeAll()
        isActive = false
    }

    // MARK: - Advertising (Mimic Mode)

    private func startAdvertising() {
        let discoveryInfo = ["mode": mode.rawValue]
        print("📡 Creating advertiser with service type: \(serviceType)")
        print("📡 Discovery info: \(discoveryInfo)")
        advertiser = MCNearbyServiceAdvertiser(
            peer: myPeerID,
            discoveryInfo: discoveryInfo,
            serviceType: serviceType
        )
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        print("📡 Advertiser started")
    }

    private func stopAdvertising() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
    }

    // MARK: - Browsing (Controller Mode)

    private func startBrowsing() {
        print("🔍 Creating browser with service type: \(serviceType)")
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        print("🔍 Browser started, looking for peers...")
    }

    private func stopBrowsing() {
        browser?.stopBrowsingForPeers()
        browser = nil
    }

    // MARK: - Connection Management

    func invitePeer(_ peerID: MCPeerID) {
        guard let session = session,
              let browser = browser else { return }

        browser.invitePeer(
            peerID,
            to: session,
            withContext: nil,
            timeout: 30
        )
    }

    func disconnectPeer(_ peerID: MCPeerID) {
        // MCSession doesn't have a direct disconnect method for individual peers
        // The peer will be removed when they disconnect
        // For now, we can just update our local state
        if let device = discoveredPeers[peerID] {
            onPeerDisconnected?(device)
        }
    }

    // MARK: - Messaging

    func send(_ message: NetworkMessage, to peers: [MCPeerID]) {
        guard let session = session,
              !peers.isEmpty else { return }

        do {
            let data = try message.encode()
            try session.send(data, toPeers: peers, with: .reliable)
        } catch {
            onError?(error)
        }
    }

    func broadcast(_ message: NetworkMessage) {
        guard let session = session else { return }
        let peers = session.connectedPeers
        send(message, to: peers)
    }

    private func handleReceivedData(_ data: Data, from peerID: MCPeerID) {
        do {
            let message = try NetworkMessage.decode(from: data)
            onMessageReceived?(message, peerID)
        } catch {
            onError?(error)
        }
    }
}

// MARK: - MCSessionDelegate

extension MultipeerService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("🔄 Peer \(peerID.displayName) state changed to: \(state.description)")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            switch state {
            case .connected:
                print("✅ Connected to: \(peerID.displayName)")
                let device = PeerDevice(
                    peerID: peerID,
                    mode: self.extractMode(from: peerID),
                    isConnected: true
                )
                self.discoveredPeers[peerID] = device
                self.onPeerConnected?(device)

            case .notConnected:
                print("❌ Disconnected from: \(peerID.displayName)")
                if let device = self.discoveredPeers[peerID] {
                    self.onPeerDisconnected?(device)
                }
                self.discoveredPeers.removeValue(forKey: peerID)

            case .connecting:
                print("⏳ Connecting to: \(peerID.displayName)")
                break

            @unknown default:
                break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            self?.handleReceivedData(data, from: peerID)
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Not used for this app
    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Not used for this app
    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Not used for this app
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension MultipeerService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("📨 Received invitation from: \(peerID.displayName)")

        // Mimic automatically accepts invitations from Controllers
        DispatchQueue.main.async { [weak self] in
            guard let session = self?.session else {
                print("❌ No session available, rejecting invitation")
                invitationHandler(false, nil)
                return
            }
            print("✅ Accepting invitation from: \(peerID.displayName)")
            invitationHandler(true, session)
        }
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("❌ Advertiser failed to start: \(error.localizedDescription)")

        DispatchQueue.main.async { [weak self] in
            self?.onError?(error)
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension MultipeerService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        print("🎉 Found peer: \(peerID.displayName)")
        print("🎉 Discovery info: \(info ?? [:])")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let mode = info?["mode"].flatMap { AppMode(rawValue: $0) } ?? .mimic
            let device = PeerDevice(
                peerID: peerID,
                mode: mode,
                isConnected: false
            )
            self.discoveredPeers[peerID] = device
            print("✅ Added peer to discovered list: \(device.id)")
            self.onPeerDiscovered?(device)
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("❌ Lost peer: \(peerID.displayName)")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if let device = self.discoveredPeers[peerID] {
                self.onPeerLost?(device)
            }
            self.discoveredPeers.removeValue(forKey: peerID)
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("❌ Browser failed to start: \(error.localizedDescription)")

        DispatchQueue.main.async { [weak self] in
            self?.onError?(error)
        }
    }
}

// MARK: - Helpers

extension MultipeerService {
    private func extractMode(from peerID: MCPeerID) -> AppMode {
        let displayName = peerID.displayName
        if displayName.contains("[Controller]") {
            return .controller
        } else if displayName.contains("[Mimic]") {
            return .mimic
        }
        return .mimic // Default assumption
    }
}

extension MCSessionState {
    var description: String {
        switch self {
        case .notConnected: return "Not Connected"
        case .connecting: return "Connecting"
        case .connected: return "Connected"
        @unknown default: return "Unknown"
        }
    }
}
