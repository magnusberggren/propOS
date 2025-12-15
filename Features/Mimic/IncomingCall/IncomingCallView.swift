//
//  IncomingCallView.swift
//  PropPhone
//
//  Created by Claude Code
//

import SwiftUI

struct IncomingCallView: View {
    let call: CallState
    var customCallerImage: UIImage? = nil

    var body: some View {
        ZStack {
            // Background - dark blur
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top section with caller info
                VStack(spacing: Spacing.md) {
                    // "iPhone" or call type label
                    Text(call.isVideo ? "FaceTime Video" : "iPhone")
                        .font(.callScreenLabel)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, Spacing.callScreenTopPadding)

                    // Caller photo
                    CallerPhotoView(photoURL: call.callerPhotoURL, customImage: customCallerImage)
                        .padding(.top, Spacing.lg)

                    // Caller name
                    Text(call.callerName)
                        .font(.callScreenCallerName)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)

                    // Caller number/subtitle
                    Text(call.subtitle)
                        .font(.callScreenSubtitle)
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                // Action buttons at bottom
                CallActionButtons()
                    .padding(.bottom, Spacing.callScreenBottomPadding)
            }
        }
    }
}

struct CallerPhotoView: View {
    let photoURL: String?
    var customImage: UIImage? = nil

    var body: some View {
        ZStack {
            if let image = customImage {
                // Custom photo
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: Spacing.callScreenAvatarSize, height: Spacing.callScreenAvatarSize)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 2)
                    )
            } else {
                // System icon or default
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: Spacing.callScreenAvatarSize, height: Spacing.callScreenAvatarSize)

                if let iconName = photoURL {
                    Image(systemName: iconName)
                        .font(.system(size: 60, weight: .thin))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: Spacing.callScreenAvatarSize))
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
        }
    }
}

#Preview {
    IncomingCallView(
        call: CallState(
            callerName: "Mom",
            callerNumber: "(555) 123-4567",
            callerPhotoURL: "person.circle.fill",
            isVideo: false
        )
    )
}
