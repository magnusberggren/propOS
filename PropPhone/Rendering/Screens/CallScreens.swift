//
//  CallScreens.swift
//  PropPhone
//
//  Incoming call (functional slide-to-answer or decline/accept
//  buttons, per cue) and the active call screen with a running
//  timer — so answering on camera actually goes somewhere.
//

import SwiftUI

// MARK: - Incoming call

struct IncomingCallScreen: View {
    let runtime: PhoneRuntime
    let spec: CallSpec
    let displayTime: Date

    var body: some View {
        ZStack {
            WallpaperView(
                spec: runtime.state.profile.wallpaper,
                assetGeneration: runtime.assetGeneration
            )
            .overlay(.ultraThinMaterial)
            .overlay(Color.black.opacity(0.35))
            .ignoresSafeArea()

            VStack(spacing: 0) {
                IOSStatusBar(
                    style: .lockScreen,
                    spec: runtime.state.profile.statusBar,
                    time: displayTime,
                    tint: .white
                )
                .padding(.horizontal, 20)
                .padding(.top, DeviceMetrics.top - 47)

                VStack(spacing: 14) {
                    AvatarView(
                        name: spec.callerName,
                        monogram: monogram,
                        imageAsset: spec.callerImageAsset,
                        size: 96,
                        assetGeneration: runtime.assetGeneration
                    )

                    VStack(spacing: 4) {
                        Text(spec.callerName)
                            .font(.system(size: 31, weight: .regular))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Text(spec.isFaceTime ? "FaceTime Video" : spec.callerSubtitle)
                            .font(.system(size: 16))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(.top, 44)

                Spacer()

                HStack {
                    SmallCallAction(symbol: "alarm.fill", label: "Remind Me")
                    Spacer()
                    SmallCallAction(symbol: "message.fill", label: "Message")
                }
                .padding(.horizontal, 58)
                .padding(.bottom, 30)

                Group {
                    switch spec.presentation {
                    case .slider:
                        SlideToAnswer {
                            runtime.answerCall()
                        }
                        .padding(.horizontal, 22)
                    case .buttons:
                        HStack {
                            RoundCallButton(
                                symbol: "phone.down.fill", color: Color(red: 1.0, green: 0.23, blue: 0.19),
                                label: "Decline"
                            ) {
                                runtime.declineCall()
                            }
                            Spacer()
                            RoundCallButton(
                                symbol: "phone.fill", color: Color(red: 0.20, green: 0.84, blue: 0.29),
                                label: "Accept"
                            ) {
                                runtime.answerCall()
                            }
                        }
                        .padding(.horizontal, 58)
                    }
                }
                .padding(.bottom, 44)

                HomeIndicator()
            }
        }
        .environment(\.colorScheme, .dark)
    }

    private var monogram: String {
        let parts = spec.callerName.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? "?"
        let last = parts.count > 1 ? parts.last?.first.map(String.init) ?? "" : ""
        return first + last
    }
}

struct SmallCallAction: View {
    let symbol: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 22))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.9))
        }
    }
}

struct RoundCallButton: View {
    let symbol: String
    let color: Color
    let label: String
    var action: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Button(action: action) {
                ZStack {
                    Circle().fill(color)
                    Image(systemName: symbol)
                        .font(.system(size: 30))
                        .foregroundStyle(.white)
                }
                .frame(width: 75, height: 75)
            }
            .buttonStyle(.plain)

            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.9))
        }
    }
}

// MARK: - Slide to answer

struct SlideToAnswer: View {
    var onAnswer: () -> Void

    @State private var offset: CGFloat = 0
    @State private var shimmerPhase: CGFloat = -1

    private let knobSize: CGFloat = 66
    private let trackHeight: CGFloat = 76

    var body: some View {
        GeometryReader { geo in
            let maxOffset = geo.size.width - knobSize - 10

            ZStack {
                Capsule()
                    .fill(.ultraThinMaterial)

                Text("slide to answer")
                    .font(.system(size: 19))
                    .foregroundStyle(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.45), location: 0),
                                .init(color: .white, location: max(0, min(1, shimmerPhase))),
                                .init(color: .white.opacity(0.45), location: 1)
                            ],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .padding(.leading, 30)
                    .opacity(offset > 12 ? 0 : 1)

                HStack {
                    ZStack {
                        Circle().fill(.white)
                        Image(systemName: "phone.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(Color(red: 0.20, green: 0.78, blue: 0.29))
                    }
                    .frame(width: knobSize, height: knobSize)
                    .offset(x: offset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = max(0, min(maxOffset, value.translation.width))
                            }
                            .onEnded { _ in
                                if offset > maxOffset * 0.82 {
                                    withAnimation(.easeOut(duration: 0.12)) { offset = maxOffset }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        onAnswer()
                                        offset = 0
                                    }
                                } else {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        offset = 0
                                    }
                                }
                            }
                    )

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 5)
            }
            .onAppear {
                withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: false)) {
                    shimmerPhase = 2
                }
            }
        }
        .frame(height: trackHeight)
    }
}

// MARK: - Active call

struct ActiveCallScreen: View {
    let runtime: PhoneRuntime
    let call: ActiveCallState
    let displayTime: Date

    @State private var muted = false
    @State private var speakerOn = false

    var body: some View {
        ZStack {
            WallpaperView(
                spec: runtime.state.profile.wallpaper,
                assetGeneration: runtime.assetGeneration
            )
            .overlay(.ultraThinMaterial)
            .overlay(Color.black.opacity(0.45))
            .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 10) {
                    AvatarView(
                        name: call.callerName,
                        monogram: String(call.callerName.prefix(1)),
                        imageAsset: call.callerImageAsset,
                        size: 88,
                        assetGeneration: runtime.assetGeneration
                    )

                    Text(call.callerName)
                        .font(.system(size: 28))
                        .foregroundStyle(.white)

                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Text(PropFormat.callTimer(since: call.connectedAt, now: context.date))
                            .font(.system(size: 16))
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(.top, DeviceMetrics.top + 26)

                Spacer()

                VStack(spacing: 24) {
                    HStack(spacing: 32) {
                        CallGridButton(symbol: muted ? "mic.slash.fill" : "mic.fill", label: "mute", active: muted) {
                            muted.toggle()
                        }
                        CallGridButton(symbol: "circle.grid.3x3.fill", label: "keypad")
                        CallGridButton(symbol: "speaker.wave.3.fill", label: "audio", active: speakerOn) {
                            speakerOn.toggle()
                        }
                    }
                    HStack(spacing: 32) {
                        CallGridButton(symbol: "plus", label: "add call")
                        CallGridButton(symbol: "video.fill", label: "FaceTime")
                        CallGridButton(symbol: "person.crop.circle", label: "contacts")
                    }
                }
                .padding(.bottom, 54)

                Button {
                    runtime.endCall()
                } label: {
                    ZStack {
                        Circle().fill(Color(red: 1.0, green: 0.23, blue: 0.19))
                        Image(systemName: "phone.down.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 75, height: 75)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 40)

                HomeIndicator()
            }
        }
        .environment(\.colorScheme, .dark)
    }
}

struct CallGridButton: View {
    let symbol: String
    let label: String
    var active = false
    var action: () -> Void = {}

    var body: some View {
        VStack(spacing: 8) {
            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(active ? Color.white : Color.white.opacity(0.22))
                    Image(systemName: symbol)
                        .font(.system(size: 28))
                        .foregroundStyle(active ? .black : .white)
                }
                .frame(width: 75, height: 75)
            }
            .buttonStyle(.plain)

            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.9))
        }
    }
}
