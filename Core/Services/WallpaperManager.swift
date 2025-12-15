//
//  WallpaperManager.swift
//  PropPhone
//
//  Manages custom wallpaper images
//

import SwiftUI
import UIKit

@Observable
class WallpaperManager {
    static let shared = WallpaperManager()

    var customImage: UIImage?

    private init() {}

    func setCustomImage(_ image: UIImage) {
        self.customImage = image
    }

    func clearCustomImage() {
        self.customImage = nil
    }

    var hasCustomImage: Bool {
        customImage != nil
    }
}

// View to display either preset wallpaper or custom image
struct WallpaperView: View {
    let wallpaper: Wallpaper
    let customImage: UIImage?

    var body: some View {
        if wallpaper == .black, let image = customImage {
            // Using .black as a flag for custom image
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
        } else {
            wallpaper.background
        }
    }
}
