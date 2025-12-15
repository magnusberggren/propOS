//
//  CallControlView.swift
//  PropPhone
//
//  Created by Claude Code
//

import SwiftUI
import PhotosUI

struct CallControlView: View {
    @Environment(ControllerViewModel.self) private var controllerVM
    @State private var callerName: String = ""
    @State private var callerNumber: String = ""
    @State private var isVideo: Bool = false
    @State private var selectedIcon: String = "person.circle.fill"
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var callerPhotoData: Data?
    @State private var showTemplatesPicker: Bool = false
    @State private var showSaveTemplate: Bool = false
    @State private var isScreenBlackedOut: Bool = false
    @FocusState private var focusedField: Field?

    private let templateService = TemplateStorageService.shared

    private enum Field {
        case name, number
    }

    private let iconOptions = [
        "person.circle.fill",
        "person.crop.circle.fill",
        "person.2.circle.fill",
        "phone.circle.fill",
        "briefcase.circle.fill",
        "house.circle.fill"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.black.opacity(0.04))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "phone.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.green)
                    )

                Text("Incoming Call")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)

                Spacer()

                Button {
                    showTemplatesPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Templates")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
                }
            }

            VStack(spacing: 18) {
                // Caller Name field
                glassTextField(
                    label: "Caller Name",
                    placeholder: "Enter name",
                    text: $callerName,
                    isFocused: focusedField == .name
                )
                .focused($focusedField, equals: .name)
                .onTapGesture { focusedField = .name }

                // Caller Number field
                glassTextField(
                    label: "Caller Number",
                    placeholder: "(555) 123-4567",
                    text: $callerNumber,
                    isFocused: focusedField == .number
                )
                .focused($focusedField, equals: .number)
                .keyboardType(.phonePad)
                .onTapGesture { focusedField = .number }

                // Caller Image section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Caller Image")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            // Photo picker button
                            photoPickerButton

                            // Icon options
                            ForEach(iconOptions, id: \.self) { icon in
                                iconButton(icon: icon)
                            }
                        }
                    }
                }

                // Video call toggle
                videoToggle

                // Save as template button
                if !callerName.isEmpty {
                    saveTemplateButton
                }

                // Action buttons
                HStack(spacing: 12) {
                    triggerButton
                    dismissButton
                }

                // Screen blackout toggle (proximity sensor simulation)
                screenBlackoutToggle
            }
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black.opacity(0.06), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        .sheet(isPresented: $showTemplatesPicker) {
            CallTemplatePickerView(templateService: templateService) { template in
                applyTemplate(template)
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showSaveTemplate) {
            SaveCallTemplateSheet(
                templateService: templateService,
                callerName: callerName,
                callerNumber: callerNumber.isEmpty ? nil : callerNumber,
                callerIcon: selectedIcon,
                callerPhotoData: callerPhotoData,
                isVideo: isVideo
            )
            .presentationDetents([.medium])
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    callerPhotoData = templateService.compressImage(data)
                }
            }
        }
    }

    private func glassTextField(label: String, placeholder: String, text: Binding<String>, isFocused: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)

            TextField(placeholder, text: text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .padding(14)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isFocused ? Color.blue.opacity(0.5) : Color.black.opacity(0.06), lineWidth: 0.5)
                )
        }
    }

    private func iconButton(icon: String) -> some View {
        let isSelected = selectedIcon == icon && callerPhotoData == nil
        return Button {
            selectedIcon = icon
            callerPhotoData = nil
            selectedPhotoItem = nil
        } label: {
            Image(systemName: icon)
                .font(.system(size: 26, weight: .medium))
                .foregroundColor(isSelected ? .blue : .primary.opacity(0.4))
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(isSelected ? Color.blue.opacity(0.1) : Color.black.opacity(0.04))
                )
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.blue.opacity(0.3) : Color.black.opacity(0.06), lineWidth: 0.5)
                )
        }
    }

    private var photoPickerButton: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            Group {
                if let photoData = callerPhotoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                        )
                } else {
                    Image(systemName: "photo.circle.fill")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundColor(.primary.opacity(0.4))
                        .frame(width: 50, height: 50)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.04))
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
                        )
                }
            }
        }
    }

    private var saveTemplateButton: some View {
        Button {
            showSaveTemplate = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 14, weight: .semibold))
                Text("Save as Template")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var videoToggle: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.blue.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "video.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.blue)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Video Call")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                Text("FaceTime style call")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isVideo)
                .labelsHidden()
                .tint(.blue)
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var triggerButton: some View {
        Button { triggerCall() } label: {
            HStack(spacing: 8) {
                Image(systemName: "phone.arrow.down.left.fill")
                    .font(.system(size: 14, weight: .semibold))
                Text("Trigger")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(callerName.isEmpty ? Color.gray.opacity(0.3) : Color.green)
            .cornerRadius(10)
        }
        .disabled(callerName.isEmpty)
    }

    private var dismissButton: some View {
        Button { dismissCall() } label: {
            HStack(spacing: 8) {
                Image(systemName: "phone.down.fill")
                    .font(.system(size: 14, weight: .semibold))
                Text("Dismiss")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.red)
            .cornerRadius(10)
        }
    }

    private var screenBlackoutToggle: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 10)
                .fill(isScreenBlackedOut ? Color.black : Color.gray.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: isScreenBlackedOut ? "moon.fill" : "sun.max.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isScreenBlackedOut ? .white : .gray)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Screen Off")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                Text("Proximity sensor simulation")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isScreenBlackedOut)
                .labelsHidden()
                .tint(.black)
                .onChange(of: isScreenBlackedOut) { _, newValue in
                    controllerVM.setScreenBlackout(newValue)
                }
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func triggerCall() {
        let call = CallState(
            callerName: callerName,
            callerNumber: callerNumber.isEmpty ? nil : callerNumber,
            callerPhotoURL: selectedIcon,
            isVideo: isVideo
        )
        controllerVM.triggerCall(call)
    }

    private func dismissCall() {
        controllerVM.dismissCall()
        controllerVM.setScreenBlackout(false)
        callerName = ""
        callerNumber = ""
        isVideo = false
        callerPhotoData = nil
        selectedPhotoItem = nil
        selectedIcon = "person.circle.fill"
        isScreenBlackedOut = false
    }

    private func applyTemplate(_ template: CallTemplate) {
        callerName = template.callerName
        callerNumber = template.callerNumber ?? ""
        selectedIcon = template.callerIcon
        callerPhotoData = template.callerPhotoData
        isVideo = template.isVideo
    }
}

#Preview {
    ZStack {
        AppGradients.cosmicBackground.ignoresSafeArea()
        CallControlView()
            .padding()
            .environment(ControllerViewModel(multipeerService: MultipeerService(mode: .controller)))
    }
}
