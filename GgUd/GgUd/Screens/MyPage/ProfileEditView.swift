//
//  ProfileEditView.swift
//  GgUd
//


import SwiftUI

struct ProfileEditView: View {

    @Environment(\.dismiss) private var dismiss

    // 더미
    @State private var name: String = "이은우"

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {

                // ✅ 상단바 (69 / padding 16-24-17 / bottom border #E5E7EB)
                ProfileEditTopBar(title: "프로필 수정") {
                    dismiss()
                }

                ScrollView {
                    VStack(spacing: 0) {

                        // ✅ 2-1 프로필 사진 칸 (폭 327 / 높이 284 / bottom padding 24)
                        ProfilePhotoCard()
                            .frame(height: 284)
                            .padding(.bottom, 24)

                        // ✅ 2-2 기본정보 (폭 327 / 높이 175 / radius 16 / padding 24 / shadow)
                        BasicInfoCard(name: $name)
                            .frame(height: 175)

                        // ✅ 2-3 버튼 영역 (폭 327 / 높이 150 / padding-top 32)
                        ButtonsSection(
                            onSave: { print("저장: \(name)") },
                            onCancel: { dismiss() }
                        )
                        .padding(.top, 32)
                    }
                    // ✅ 본문 좌우 패딩 24 → 컨텐츠 폭 327
                    .padding(.horizontal, 24)
                    .padding(.top, 24) // 피그마에 명시 없으면 여기서 자연스럽게 맞춰줌
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarHidden(true)
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
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppColors.text)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppColors.text)

                Spacer()

                // 좌우 균형 맞추기용
                Color.clear.frame(width: 24, height: 24)
            }
            .padding(.top, ProfileEditStyle.topBarPaddingTop)
            .padding(.horizontal, ProfileEditStyle.topBarPaddingH)
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
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("프로필 사진")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppColors.text)

            Spacer()

            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 92, height: 92)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Color.gray.opacity(0.7))
                    )

                Circle()
                    .fill(AppColors.primary)
                    .frame(width: 34, height: 34)
                    .overlay(
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .offset(x: 6, y: 6) // 살짝 겹침
            }
            .frame(maxWidth: .infinity)

            Spacer()

            Text("프로필 사진을 변경하려면 카메라 아이콘을 터치\n하세요")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(AppColors.subText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(ProfileEditStyle.cardPadding)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: ProfileEditStyle.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ProfileEditStyle.cardRadius, style: .continuous)
                .stroke(AppColors.border.opacity(0.7), lineWidth: 1)
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
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppColors.subText)

            TextField("", text: $name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppColors.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(AppColors.border, lineWidth: 1)
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
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: ProfileEditStyle.buttonsGap) {

                Button(action: onSave) {
                    Text("변경사항 저장")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: ProfileEditStyle.buttonHeight)
                        .background(AppColors.primary) // #3B82F6
                        .clipShape(RoundedRectangle(cornerRadius: ProfileEditStyle.buttonRadius, style: .continuous))
                }
                .buttonStyle(.plain)

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

            }
            .frame(height: ProfileEditStyle.buttonsWrapperHeight, alignment: .top)

            Spacer()
        }
        .frame(height: ProfileEditStyle.buttonsSectionHeight)
        .frame(maxWidth: .infinity)
    }
}
