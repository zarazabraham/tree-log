//
//  AddPlantView.swift
//  Plantydex
//
//  Created by Claude Code on 1/4/26.
//

import SwiftUI
import PhotosUI

struct AddPlantView: View {
    @Environment(\.theme) private var theme
    @Binding var isPresented: Bool
    let onComplete: () -> Void

    @State private var selectedImageData: Data?
    @State private var isUploading = false
    @State private var error: String?
    @State private var identifyResult: IdentifyResult?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.sectionSpacing) {
                    // Image picker
                    if selectedImageData == nil {
                        DSImagePicker(selectedImageData: $selectedImageData)
                            .padding(.horizontal, theme.spacing.screenEdge)
                    } else if let imageData = selectedImageData,
                              let uiImage = UIImage(data: imageData) {
                        imagePreviewSection(image: uiImage)
                    }

                    // Error display
                    if let error {
                        DSInlineError(message: error) {
                            self.error = nil
                            selectedImageData = nil
                            identifyResult = nil
                        }
                        .padding(.horizontal, theme.spacing.screenEdge)
                    }

                    // Identification result
                    if let result = identifyResult {
                        identificationResultSection(result: result)
                    }
                }
            }
            .navigationTitle("Add Plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func imagePreviewSection(image: UIImage) -> some View {
        DSCard(padding: .cardPadding) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                HStack {
                    Text("Selected Photo")
                        .font(theme.typography.headingMedium)
                        .foregroundColor(theme.colors.textPrimary)

                    Spacer()

                    if identifyResult == nil {
                        Button("Change") {
                            selectedImageData = nil
                            error = nil
                        }
                        .font(theme.typography.bodySmall)
                        .foregroundColor(theme.colors.primary)
                    }
                }

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: theme.radii.card))
                    .elevation(.level2)

                // Identify button
                if identifyResult == nil && !isUploading {
                    DSButton(
                        "Identify Plant",
                        icon: "leaf.fill",
                        style: .primary,
                        action: uploadAndIdentify
                    )
                }

                // Loading state
                if isUploading {
                    DSInlineLoading(message: "Identifying plant...")
                }
            }
        }
        .padding(.horizontal, theme.spacing.screenEdge)
    }

    @ViewBuilder
    private func identificationResultSection(result: IdentifyResult) -> some View {
        DSCard(elevation: .level2, padding: .cardPadding) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                // Success header
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(theme.typography.headingMedium)
                        .foregroundColor(theme.colors.success)

                    Text("Plant Identified!")
                        .font(theme.typography.headingMedium)
                        .foregroundColor(theme.colors.success)

                    Spacer()
                }

                Divider()

                // Plant name
                VStack(alignment: .leading, spacing: theme.spacing.xxxs) {
                    Text(result.name)
                        .font(theme.typography.displaySmall)
                        .foregroundColor(theme.colors.textPrimary)

                    if let scientific = result.scientificName {
                        Text(scientific)
                            .font(theme.typography.scientificName)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }

                // Confidence
                if let confidence = result.confidence {
                    HStack {
                        Text("Confidence:")
                            .font(theme.typography.bodyMediumEmphasized)
                            .foregroundColor(theme.colors.textPrimary)
                        Text("\(Int(confidence * 100))%")
                            .font(theme.typography.bodyMedium)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }

                // Taxonomy
                if result.family != nil || result.genus != nil {
                    VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                        if let family = result.family {
                            HStack {
                                Text("Family:")
                                    .font(theme.typography.bodyMediumEmphasized)
                                    .foregroundColor(theme.colors.textPrimary)
                                Text(family)
                                    .font(theme.typography.scientificName)
                                    .foregroundColor(theme.colors.textSecondary)
                            }
                        }
                        if let genus = result.genus {
                            HStack {
                                Text("Genus:")
                                    .font(theme.typography.bodyMediumEmphasized)
                                    .foregroundColor(theme.colors.textPrimary)
                                Text(genus)
                                    .font(theme.typography.scientificName)
                                    .foregroundColor(theme.colors.textSecondary)
                            }
                        }
                    }
                }

                // Reference images
                if let images = result.referenceImages, !images.isEmpty {
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        Text("Reference Images")
                            .font(theme.typography.headingSmall)
                            .foregroundColor(theme.colors.textPrimary)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: theme.spacing.xs) {
                            ForEach(Array(images.prefix(6).enumerated()), id: \.offset) { _, image in
                                if let urlString = image.url,
                                   let url = URL(string: urlString) {
                                    AsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let img):
                                            img
                                                .resizable()
                                                .scaledToFill()
                                                .frame(height: 80)
                                                .clipped()
                                                .clipShape(RoundedRectangle(cornerRadius: theme.radii.image))
                                        case .failure:
                                            theme.colors.surfaceSecondary
                                                .frame(height: 80)
                                                .clipShape(RoundedRectangle(cornerRadius: theme.radii.image))
                                        case .empty:
                                            ZStack {
                                                theme.colors.surfaceSecondary
                                                ProgressView()
                                            }
                                            .frame(height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: theme.radii.image))
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Divider()

                // Action buttons
                HStack(spacing: theme.spacing.sm) {
                    DSButton(
                        "Go to Log",
                        icon: "list.bullet",
                        style: .primary
                    ) {
                        onComplete()
                        isPresented = false
                    }

                    DSButton(
                        "Identify Another",
                        icon: "arrow.clockwise",
                        style: .secondary
                    ) {
                        selectedImageData = nil
                        error = nil
                        identifyResult = nil
                    }
                }
            }
        }
        .padding(.horizontal, theme.spacing.screenEdge)
    }

    // MARK: - Upload and Identify

    private func uploadAndIdentify() {
        print("DEBUG: uploadAndIdentify called")

        guard let imageData = selectedImageData else {
            print("DEBUG: No image data selected")
            return
        }

        print("DEBUG: Image data size: \(imageData.count) bytes")

        isUploading = true
        error = nil
        identifyResult = nil

        Task {
            do {
                print("DEBUG: Starting upload task")

                // Convert to JPEG if needed
                let jpegData: Data
                if let uiImage = UIImage(data: imageData),
                   let converted = uiImage.jpegData(compressionQuality: 0.9) {
                    print("DEBUG: Converted image to JPEG")
                    jpegData = converted
                } else {
                    print("DEBUG: Using original image data")
                    jpegData = imageData
                }

                // 1. Upload to Supabase Storage
                let fileName = "\(UUID().uuidString).jpg"
                let path = "uploads/\(fileName)"

                let uploadURL = SupabaseConfig.url
                    .appendingPathComponent("storage/v1/object/tree-photos/\(path)")

                var uploadRequest = URLRequest(url: uploadURL)
                uploadRequest.httpMethod = "POST"
                uploadRequest.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
                uploadRequest.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
                uploadRequest.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
                uploadRequest.httpBody = jpegData

                print("DEBUG: Uploading to: \(uploadURL)")
                print("DEBUG: Upload path: \(path)")
                print("DEBUG: Image size: \(jpegData.count) bytes")

                let (uploadData, uploadResponse) = try await URLSession.shared.data(for: uploadRequest)

                guard let httpResponse = uploadResponse as? HTTPURLResponse else {
                    throw NSError(domain: "Upload", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: "Invalid upload response"
                    ])
                }

                print("DEBUG: Upload status code: \(httpResponse.statusCode)")
                let responseBody = String(data: uploadData, encoding: .utf8) ?? ""
                print("DEBUG: Upload response body: \(responseBody)")

                guard (200...299).contains(httpResponse.statusCode) else {
                    throw NSError(domain: "Upload", code: httpResponse.statusCode, userInfo: [
                        NSLocalizedDescriptionKey: "Upload failed with status \(httpResponse.statusCode): \(responseBody)"
                    ])
                }

                // 2. Get public URL
                let publicURL = "\(SupabaseConfig.url)/storage/v1/object/public/tree-photos/\(path)"

                // 3. Call identify edge function
                let identifyURL = SupabaseConfig.url
                    .appendingPathComponent("functions/v1/identify-tree")

                var identifyRequest = URLRequest(url: identifyURL)
                identifyRequest.httpMethod = "POST"
                identifyRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                identifyRequest.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
                identifyRequest.setValue("Bearer \(SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")

                let requestBody = ["imageUrl": publicURL]
                identifyRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

                let (identifyData, identifyResponse) = try await URLSession.shared.data(for: identifyRequest)

                guard let httpIdentifyResponse = identifyResponse as? HTTPURLResponse else {
                    throw NSError(domain: "Identify", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: "Invalid response"
                    ])
                }

                print("DEBUG: Identify status code: \(httpIdentifyResponse.statusCode)")
                let identifyBody = String(data: identifyData, encoding: .utf8) ?? ""
                print("DEBUG: Identify response body: \(identifyBody)")

                if !(200...299).contains(httpIdentifyResponse.statusCode) {
                    throw NSError(domain: "Identify", code: httpIdentifyResponse.statusCode, userInfo: [
                        NSLocalizedDescriptionKey: "Identify failed: \(identifyBody)"
                    ])
                }

                let result = try JSONDecoder().decode(IdentifyResult.self, from: identifyData)

                await MainActor.run {
                    identifyResult = result
                    isUploading = false
                }

            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isUploading = false
                }
            }
        }
    }
}

#Preview {
    AddPlantView(isPresented: .constant(true)) {
        print("Completed")
    }
}
