//
//  ProfileEditView.swift
//  GgUd
//

import PhotosUI
import SwiftUI

struct ProfileEditView: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userSession: UserSessionStore

    @State private var name: String = ""
    @State private var isSaving = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var selectedUIImage: UIImage?

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {

                // ✅ 상단바
                AppBar(
                    title: "프로필 수정",
                    onBack: { dismiss() }
                )

                ScrollView {
                    VStack(spacing: 24) {

                        // ✅ 2-1 프로필 사진 칸 (폭 327 / 높이 284 / bottom padding 24)
                        ProfilePhotoCard(
                            selectedUIImage: selectedUIImage,
                            remoteImageURL: userSession.profileImageURL,
                            selectedPhotoItem: $selectedPhotoItem
                        )
                            .frame(width: 327, height: 284)

                        // ✅ 2-2 기본정보 (폭 327 / 높이 175 / radius 16 / padding 24 / shadow)
                        BasicInfoCard(name: $name)
                            .frame(width: 327, height: 175)

                        // ✅ 2-3 버튼 영역 (폭 327 / 높이 150 / padding-top 32)
                        ButtonsSection(
                            isSaving: isSaving,
                            onSave: saveProfile,
                            onCancel: { dismiss() }
                        )
                        .padding(.top, 8)
                    }
                    // ✅ 본문 좌우 패딩 24 → 컨텐츠 폭 327
                    .frame(width: 375)
                    .padding(.top, 11)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            if name.isEmpty {
                name = userSession.nickname
            }
        }
        .onChange(of: selectedPhotoItem) { _, newValue in
            guard let newValue else { return }
            Task {
                await loadSelectedPhoto(from: newValue)
            }
        }
        .alert("프로필 수정", isPresented: $showAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private func saveProfile() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            alertMessage = "이름을 입력해주세요."
            showAlert = true
            return
        }

        guard let accessToken = userSession.backendAccessToken, !accessToken.isEmpty else {
            alertMessage = "로그인 정보가 없습니다. 다시 로그인해주세요."
            showAlert = true
            return
        }

        isSaving = true
        let tokenType = userSession.backendTokenType ?? "Bearer"

        uploadProfileImageIfNeeded(accessToken: accessToken, tokenType: tokenType) { uploadedImageURL in
            AuthAPIClient.shared.updateMyProfile(
                accessToken: accessToken,
                tokenType: tokenType,
                nickname: trimmedName,
                profileImageUrl: uploadedImageURL ?? userSession.profileImageURL
            ) { result in
                DispatchQueue.main.async {
                    isSaving = false

                    switch result {
                    case let .success(user):
                        userSession.updateProfile(
                            userId: user.id,
                            nickname: user.nickname ?? trimmedName,
                            profileImageURL: user.profileImageUrl
                        )
                        dismiss()
                    case let .failure(error):
                        alertMessage = error.localizedDescription
                        showAlert = true
                    }
                }
            }
        }
    }

    private func uploadProfileImageIfNeeded(
        accessToken: String,
        tokenType: String,
        completion: @escaping (String?) -> Void
    ) {
        guard let selectedImageData else {
            completion(nil)
            return
        }

        let mimeType = imageMimeType(for: selectedImageData)
        let fileExtension = fileExtension(for: mimeType)
        let fileName = "profile.\(fileExtension)"

        AuthAPIClient.shared.uploadProfileImage(
            accessToken: accessToken,
            tokenType: tokenType,
            imageData: selectedImageData,
            mimeType: mimeType,
            fileName: fileName
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case let .success(user):
                    completion(user.profileImageUrl)
                case let .failure(error):
                    isSaving = false
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }

    @MainActor
    private func loadSelectedPhoto(from item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else { return }
            selectedImageData = data
            selectedUIImage = UIImage(data: data)
        } catch {
            alertMessage = "선택한 이미지를 불러오지 못했습니다."
            showAlert = true
        }
    }

    private func imageMimeType(for data: Data) -> String {
        let bytes = [UInt8](data.prefix(1))
        guard let first = bytes.first else { return "image/jpeg" }

        switch first {
        case 0x89: return "image/png"
        case 0x47: return "image/gif"
        default: return "image/jpeg"
        }
    }

    private func fileExtension(for mimeType: String) -> String {
        switch mimeType {
        case "image/png": return "png"
        case "image/gif": return "gif"
        default: return "jpg"
        }
    }
}

// MARK: - Style

private enum ProfileEditStyle {
    // TopBar
    static let topBarHeight: CGFloat = 69
    static let topBarPaddingTop: CGFloat = 16
    static let topBarPaddingH: CGFloat = 24
    static let topBarPaddingBottom: CGFloat = 17
    static let topBarBorderHeight: CGFloat = 1

    // Cards
    static let cardRadius: CGFloat = 16
    static let cardPadding: CGFloat = 24

    // Shadow: 0px 1px 2px 0px #0000000D (≈ opacity 0.05)
    static let shadowColor = Color.black.opacity(0.05)
    static let shadowRadius: CGFloat = 1 // blur 2 → radius ~1
    static let shadowX: CGFloat = 0
    static let shadowY: CGFloat = 1

    // Buttons
    static let buttonHeight: CGFloat = 53
    static let buttonRadius: CGFloat = 12
    static let buttonVPadding: CGFloat = 16
    static let buttonsWrapperHeight: CGFloat = 118
    static let buttonsSectionHeight: CGFloat = 150
    static let buttonsGap: CGFloat = 12
}

// MARK: - Top Bar

private struct ProfileEditTopBar: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppColors.text)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)

                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppColors.text)

                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
            .padding(.leading, 24)
            .padding(.top, ProfileEditStyle.topBarPaddingTop)
            .padding(.bottom, ProfileEditStyle.topBarPaddingBottom)
            .frame(height: ProfileEditStyle.topBarHeight, alignment: .center)

            Rectangle()
                .fill(AppColors.border) // #E5E7EB
                .frame(height: ProfileEditStyle.topBarBorderHeight)
        }
        .background(Color.white)
    }
}

// MARK: - Profile Photo Card

private struct ProfilePhotoCard: View {
    let selectedUIImage: UIImage?
    let remoteImageURL: String?
    @Binding var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("프로필 사진")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppColors.text)

            Spacer()

            ZStack(alignment: .bottomTrailing) {
                profileImageView

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Circle()
                        .fill(AppColors.primary)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16, weight: .bold))
                                .frame(width: 14.6, height: 20)
                                .foregroundStyle(.white)
                        )
                        .offset(x: 6, y: 6)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)

            Spacer()

            Text("프로필 사진을 변경하려면 카메라 아이콘을 터치하세요")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(AppColors.subText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(ProfileEditStyle.cardPadding)
        .frame(width: 327, height: 284)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: ProfileEditStyle.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ProfileEditStyle.cardRadius, style: .continuous)
                .stroke(AppColors.border.opacity(0.7), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var profileImageView: some View {
        if let selectedUIImage {
            Image(uiImage: selectedUIImage)
                .resizable()
                .scaledToFill()
                .frame(width: 96, height: 96)
                .clipShape(Circle())
        } else if let remoteImageURL, let url = URL(string: remoteImageURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    placeholderProfileImage
                }
            }
            .frame(width: 96, height: 96)
            .clipShape(Circle())
        } else {
            placeholderProfileImage
        }
    }

    private var placeholderProfileImage: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: 96, height: 96)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.gray.opacity(0.7))
            )
    }
}

// MARK: - Basic Info Card

private struct BasicInfoCard: View {
    @Binding var name: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("기본 정보")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppColors.text)

            Text("이름")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.subText2)

            TextField("", text: $name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppColors.text)
                .tint(AppColors.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(AppColors.border, lineWidth: 2)
                )
        }
        .padding(ProfileEditStyle.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: ProfileEditStyle.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ProfileEditStyle.cardRadius, style: .continuous)
                .stroke(AppColors.border.opacity(0.7), lineWidth: 1)
        )
    }
}

// MARK: - Buttons

private struct ButtonsSection: View {
    let isSaving: Bool
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: ProfileEditStyle.buttonsGap) {

                Button(action: onSave) {
                    Text(isSaving ? "저장 중..." : "변경사항 저장")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: ProfileEditStyle.buttonHeight)
                        .background(AppColors.primary) // #3B82F6
                        .clipShape(RoundedRectangle(cornerRadius: ProfileEditStyle.buttonRadius, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isSaving)

                Button(action: onCancel) {
                    Text("취소")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppColors.text)
                        .frame(maxWidth: .infinity)
                        .frame(height: ProfileEditStyle.buttonHeight)
                        .background(AppColors.divider) // #F3F4F6 (Cancel bg)
                        .clipShape(RoundedRectangle(cornerRadius: ProfileEditStyle.buttonRadius, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isSaving)

            }
            .frame(height: ProfileEditStyle.buttonsWrapperHeight, alignment: .top)

            Spacer()
        }
        .frame(height: ProfileEditStyle.buttonsSectionHeight)
        .frame(width: 327)
    }
}
