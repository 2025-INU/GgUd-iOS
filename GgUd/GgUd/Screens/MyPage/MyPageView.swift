//
//  MyPageView.swift
//  GgUd
//

import SwiftUI

struct MyPageView: View {
    private let userName = "이은우"

    var body: some View {
        ZStack {
            Color(hex: "#F9FAFB").ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                profileRow

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        sectionTitle("계정")
                        accountCard
                            .padding(.bottom, 24)

                        sectionTitle("이용 안내")
                        guideCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 120)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var topBar: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Text("마이페이지")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color(hex: "#111827"))
                Spacer()
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
            .background(Color.white)

            Rectangle()
                .fill(Color(hex: "#F3F4F6"))
                .frame(height: 1)
        }
    }

    private var profileRow: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color(hex: "#D1D5DB"))

                Text(userName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(hex: "#111827"))

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .background(Color.white)

            Rectangle()
                .fill(Color(hex: "#F3F4F6"))
                .frame(height: 1)
        }
    }

    private var accountCard: some View {
        VStack(spacing: 0) {
            menuRow(systemImage: "person.fill", title: "프로필 수정") {
                ProfileEditView()
            }
            divider
            menuRow(systemImage: "bell.fill", title: "알림 설정") {
                NotificationSettingsView()
            }
            divider
            buttonRow(systemImage: "rectangle.portrait.and.arrow.right", title: "로그아웃") {
                // TODO: logout
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var guideCard: some View {
        VStack(spacing: 0) {
            buttonRow(systemImage: "questionmark.circle", title: "문의하기") {
                // TODO
            }
            divider
            buttonRow(systemImage: "doc.text", title: "이용약관") {
                // TODO
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color(hex: "#6B7280"))
            .padding(.leading, 4)
            .padding(.bottom, 12)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color(hex: "#F9FAFB"))
            .frame(height: 1)
            .padding(.horizontal, 16)
    }

    private func menuRow<Destination: View>(systemImage: String, title: String, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink {
            destination()
        } label: {
            rowContent(systemImage: systemImage, title: title)
        }
        .buttonStyle(.plain)
    }

    private func buttonRow(systemImage: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            rowContent(systemImage: systemImage, title: title)
        }
        .buttonStyle(.plain)
    }

    private func rowContent(systemImage: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 19)
                .foregroundStyle(Color(hex: "#111827"))

            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "#111827"))

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(hex: "#9CA3AF"))
        }
        .padding(16)
        .frame(height: 60)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        MyPageView()
    }
}
