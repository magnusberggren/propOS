//
//  PeerLink.swift
//  PropPhone
//
//  Thin, role-aware wrapper around MultipeerConnectivity. Controllers
//  browse and invite; phones advertise and auto-accept. All activity
//  surfaces through a single event pipe on the main queue.
//

import Foundation
import MultipeerConnectivity
import UIKit

enum PeerRole: String, Codable {
    case controller
    case phone
}

enum SyncMessage: Codable {
    case hello(deviceName: String, role: PeerRole)
    /// Controller → phone: total display state. Idempotent; latest wins.
    case statePush(PhoneState)
    /// Phone → controller: current state after a local interaction (live mirror).
    case mirror(PhoneState)
    /// Phone → controller: asset IDs it needs bytes for.
    case requestAssets([AssetRef])
    case ping
    case pong
}

enum PeerEvent {
    case found(MCPeerID)
    case lost(MCPeerID)
    case connected(MCPeerID)
    case disconnected(MCPeerID)
    case message(SyncMessage, MCPeerID)
    case receivedAsset(id: String, from: MCPeerID)
    case error(String)
}

final class PeerLink: NSObject {
    static let serviceType = "prop-phone"

    let myPeerID: MCPeerID
    private let role: PeerRole
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    /// Single event pipe; always invoked on the main queue.
    var onEvent: ((PeerEvent) -> Void)?

    var connectedPeers: [MCPeerID] { session?.connectedPeers ?? [] }

    init(role: PeerRole) {
        self.role = role
        self.myPeerID = MCPeerID(displayName: UIDevice.current.name)
        super.init()
    }

    func start() {
        stop()
        let session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        self.session = session

        switch role {
        case .phone:
            let advertiser = MCNearbyServiceAdvertiser(
                peer: myPeerID,
                discoveryInfo: ["role": role.rawValue],
                serviceType: PeerLink.serviceType
            )
            advertiser.delegate = self
            advertiser.startAdvertisingPeer()
            self.advertiser = advertiser
        case .controller:
            let browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: PeerLink.serviceType)
            browser.delegate = self
            browser.startBrowsingForPeers()
            self.browser = browser
        }
    }

    func stop() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        browser?.stopBrowsingForPeers()
        browser = nil
        session?.disconnect()
        session = nil
    }

    func invite(_ peerID: MCPeerID) {
        guard let session, let browser else { return }
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 20)
    }

    func send(_ message: SyncMessage, to peers: [MCPeerID]? = nil) {
        guard let session else { return }
        let targets = peers ?? session.connectedPeers
        guard !targets.isEmpty else { return }
        do {
            let data = try JSONCoding.encoder.encode(message)
            try session.send(data, toPeers: targets, with: .reliable)
        } catch {
            emit(.error("Send failed: \(error.localizedDescription)"))
        }
    }

    /// Transfer asset bytes; the resource name is the asset ID.
    func sendAsset(_ ref: AssetRef, to peer: MCPeerID) {
        guard let session, AssetStore.shared.exists(ref) else { return }
        session.sendResource(
            at: AssetStore.shared.url(for: ref),
            withName: ref.id,
            toPeer: peer,
            withCompletionHandler: nil
        )
    }

    private func emit(_ event: PeerEvent) {
        DispatchQueue.main.async { [weak self] in
            self?.onEvent?(event)
        }
    }
}

// MARK: - MCSessionDelegate

extension PeerLink: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected: emit(.connected(peerID))
        case .notConnected: emit(.disconnected(peerID))
        case .connecting: break
        @unknown default: break
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let message = try? JSONCoding.decoder.decode(SyncMessage.self, from: data) else {
            emit(.error("Undecodable message from \(peerID.displayName)"))
            return
        }
        emit(.message(message, peerID))
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        guard error == nil, let localURL else { return }
        AssetStore.shared.storeReceivedResource(named: resourceName, at: localURL)
        emit(.receivedAsset(id: resourceName, from: peerID))
    }
}

// MARK: - Advertiser (phone role)

extension PeerLink: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Prop phones trust any controller on the set network.
        invitationHandler(true, session)
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        emit(.error("Advertising failed: \(error.localizedDescription)"))
    }
}

// MARK: - Browser (controller role)

extension PeerLink: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        emit(.found(peerID))
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        emit(.lost(peerID))
    }

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        emit(.error("Browsing failed: \(error.localizedDescription)"))
    }
}
