//
//  Wallpaper.swift
//  PropPhone

import SwiftUI

enum Wallpaper: String, CaseIterable, Identifiable, Equatable {
    // Custom image wallpapers
    case wallpaper1 = "Wallpaper 1"
    case wallpaper2 = "Wallpaper 2"
    case wallpaper3 = "Wallpaper 3"
    case wallpaper4 = "Wallpaper 4"
    case wallpaper5 = "Wallpaper 5"
    case wallpaper6 = "Wallpaper 6"
    case wallpaper7 = "Wallpaper 7"
    case wallpaper8 = "Wallpaper 8"
    case wallpaper9 = "Wallpaper 9"
    case wallpaper10 = "Wallpaper 10"

    // Solid colors
    case black = "Black"
    case darkBlue = "Dark Blue"

    var id: String { rawValue }

    /// The asset image name for image-based wallpapers
    private var imageName: String? {
        switch self {
        case .wallpaper1: return "Wallpaper1"
        case .wallpaper2: return "Wallpaper2"
        case .wallpaper3: return "Wallpaper3"
        case .wallpaper4: return "Wallpaper4"
        case .wallpaper5: return "Wallpaper5"
        case .wallpaper6: return "Wallpaper6"
        case .wallpaper7: return "Wallpaper7"
        case .wallpaper8: return "Wallpaper8"
        case .wallpaper9: return "Wallpaper9"
        case .wallpaper10: return "Wallpaper10"
        default: return nil
        }
    }

    @ViewBuilder
    var background: some View {
        if let imageName = imageName {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            switch self {
            case .black:
                Color.black
            case .darkBlue:
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.1, blue: 0.2),
                        Color(red: 0.0, green: 0.0, blue: 0.1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            default:
                Color.black
            }
        }
    }
}
