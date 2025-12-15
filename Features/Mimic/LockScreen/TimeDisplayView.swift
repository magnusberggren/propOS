//
//  TimeDisplayView.swift
//  PropPhone
//
//  Created by Claude Code
//

import SwiftUI

struct TimeDisplayView: View {
    let time: Date

    var body: some View {
        VStack(spacing: Spacing.lockScreenTimeDateSpacing) {
            // Large time
            Text(TimeController.shared.formatTime(time))
                .font(.lockScreenTime)
                .foregroundColor(.lockScreenText)

            // Date below
            Text(TimeController.shared.formatDate(time))
                .font(.lockScreenDate)
                .foregroundColor(.lockScreenText.opacity(0.8))
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        TimeDisplayView(time: Date())
    }
}
