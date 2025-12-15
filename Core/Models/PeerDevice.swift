//
//  PeerDevice.swift
//  PropPhone
//
//  Created by Claude Code
//

import Foundation
import MultipeerConnectivity

/// Represents a connected or discovered peer device
struct PeerDevice: Identifiable, Hashable {
    let id: String              // peerID.displayName
    let peerID: MCPeerID
    var mode: AppMode
    var isConnected: Bool
    var lastSeen: Date

    init(peerID: MCPeerID, mode: AppMode, isConnected: Bool = false) {
        self.id = peerID.displayName
        self.peerID = peerID
        self.mode = mode
        self.isConnected = isConnected
        self.lastSeen = Date()
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: PeerDevice, rhs: PeerDevice) -> Bool {
        lhs.id == rhs.id
    }
}
