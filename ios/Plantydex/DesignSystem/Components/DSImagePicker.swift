//
//  DSImagePicker.swift
//  Plantydex Design System
//
//  Token-driven image picker component with camera and library options.
//

import SwiftUI
import PhotosUI

/// A design system image picker component that uses tokens for all styling.
struct DSImagePicker: View {
    @Environment(\.theme) private var theme

    @Binding var selectedImageData: Data?
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showingCamera = false

    let title: String
    let showChangeButton: Bool

    init(
        title: String = "Choose how to add your photo",
        selectedImageData: Binding<Data?>,
        showChangeButton: Bool = true
    ) {
        self.title = title
        self._selectedImageData = selectedImageData
        self.showChangeButton = showChangeButton
    }

    var body: some View {
        VStack(spacing: theme.spacing.md) {
            if selectedImageData == nil {
                // Selection buttons
                VStack(spacing: theme.spacing.md) {
                    Text(title)
                        .font(theme.typography.headingMedium)
                        .foregroundColor(theme.colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.top, theme.spacing.xs)

                    // Take Photo button
                    DSButton(
                        "Take Photo",
                        icon: "camera.fill",
                        style: .primary
                    ) {
                        showingCamera = true
                    }

                    // Choose from Library button
                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        HStack(spacing: theme.spacing.buttonIconSpacing) {
                            Image(systemName: "photo.on.rectangle")
                            Text("Choose from Library")
                                .font(theme.typography.buttonMedium)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, theme.spacing.buttonPadding)
                        .padding(.vertical, theme.spacing.sm)
                        .background(theme.colors.surfacePrimary)
                        .foregroundColor(theme.colors.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radii.button))
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.radii.button)
                                .stroke(theme.colors.borderPrimary, lineWidth: 1)
                        )
                    }
                    .onChange(of: selectedPhoto) { _, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                selectedImageData = data
                            }
                        }
                    }
                }
            } else if let imageData = selectedImageData,
                      let uiImage = UIImage(data: imageData) {
                // Image preview
                VStack(alignment: .leading, spacing: theme.spacing.md) {
                    HStack {
                        Text("Selected Photo")
                            .font(theme.typography.headingMedium)
                            .foregroundColor(theme.colors.textPrimary)

                        Spacer()

                        if showChangeButton {
                            Button("Change") {
                                selectedImageData = nil
                                selectedPhoto = nil
                            }
                            .font(theme.typography.bodySmall)
                            .foregroundColor(theme.colors.primary)
                        }
                    }

                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: theme.radii.card))
                        .elevation(.level2)
                }
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView(image: $selectedImageData, isPresented: $showingCamera)
                .ignoresSafeArea()
        }
    }
}

// MARK: - Camera View (UIKit Wrapper)

private struct CameraView: UIViewControllerRepresentable {
    @Binding var image: Data?
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage.jpegData(compressionQuality: 0.9)
            }
            parent.isPresented = false
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

// MARK: - Previews

#Preview("Image Picker - Empty") {
    ThemeProvider {
        DSImagePicker(selectedImageData: .constant(nil))
            .padding()
    }
}

#Preview("Image Picker - With Image") {
    ThemeProvider {
        DSImagePicker(selectedImageData: .constant(UIImage(systemName: "leaf.fill")?.pngData()))
            .padding()
    }
}

#Preview("Dark Mode") {
    ThemeProvider {
        DSImagePicker(selectedImageData: .constant(nil))
            .padding()
    }
    .preferredColorScheme(.dark)
}
