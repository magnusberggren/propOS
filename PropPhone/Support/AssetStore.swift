//
//  AssetStore.swift
//  PropPhone
//
//  Content-addressed storage for binary assets (voicemail audio,
//  contact photos, wallpapers). IDs are content hashes + extension,
//  so the same file imported twice dedupes and transfers are
//  idempotent across devices.
//

import CryptoKit
import Foundation
import UIKit

final class AssetStore {
    static let shared = AssetStore()

    private let directory: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        directory = base.appendingPathComponent("PropAssets", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func url(for ref: AssetRef) -> URL {
        directory.appendingPathComponent(ref.id)
    }

    func exists(_ ref: AssetRef) -> Bool {
        FileManager.default.fileExists(atPath: url(for: ref).path)
    }

    func missing(from refs: Set<AssetRef>) -> [AssetRef] {
        refs.filter { !exists($0) }
    }

    /// Store raw data, returning its content-addressed ref.
    @discardableResult
    func store(data: Data, fileExtension: String) throws -> AssetRef {
        let hash = SHA256.hash(data: data).prefix(12).map { String(format: "%02x", $0) }.joined()
        let ref = AssetRef(id: "\(hash).\(fileExtension)")
        let target = url(for: ref)
        if !FileManager.default.fileExists(atPath: target.path) {
            try data.write(to: target, options: .atomic)
        }
        return ref
    }

    /// Import an external file (audio import, recording output).
    func importFile(at source: URL) throws -> AssetRef {
        let data = try Data(contentsOf: source)
        let ext = source.pathExtension.isEmpty ? "bin" : source.pathExtension.lowercased()
        return try store(data: data, fileExtension: ext)
    }

    /// Store an incoming peer-transferred resource whose name is already an asset ID.
    func storeReceivedResource(named id: String, at tempURL: URL) {
        let target = directory.appendingPathComponent(id)
        guard !FileManager.default.fileExists(atPath: target.path) else { return }
        try? FileManager.default.copyItem(at: tempURL, to: target)
    }

    func image(for ref: AssetRef?) -> UIImage? {
        guard let ref else { return nil }
        return UIImage(contentsOfFile: url(for: ref).path)
    }

    func storeImage(_ image: UIImage) throws -> AssetRef {
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw NSError(domain: "AssetStore", code: 1)
        }
        return try store(data: data, fileExtension: "jpg")
    }
}
