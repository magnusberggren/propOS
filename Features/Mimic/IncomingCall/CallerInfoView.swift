//
//  CallerInfoView.swift
//  PropPhone
//
//  Created by Claude Code
//

import SwiftUI

/// Displays caller information (name, number, photo) - used in IncomingCallView
struct CallerInfoView: View {
    let call: CallState

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Caller photo
            if let photoURL = call.callerPhotoURL {
                Image(systemName: photoURL)
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .frame(width: Spacing.callScreenAvatarSize, height: Spacing.callScreenAvatarSize)
                    .background(Circle().fill(Color.gray.opacity(0.3)))
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: Spacing.callScreenAvatarSize))
                    .foregroundColor(.gray.opacity(0.5))
            }

            // Caller name
            Text(call.callerName)
                .font(.callScreenCallerName)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Caller number/subtitle
            Text(call.subtitle)
                .font(.callScreenSubtitle)
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        CallerInfoView(
            call: CallState(
                callerName: "John Appleseed",
                callerNumber: "(555) 123-4567",
                callerPhotoURL: "person.circle.fill",
                isVideo: false
            )
        )
    }
}
