//
//  CreateAppointmentView.swift
//  GgUd
//
//  Created by 🍑혜리미 맥북🍑 on 1/22/26.
//
import SwiftUI

struct CreateAppointmentView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var date: Date = Date()
    @State private var time: Date = Date()
    @State private var didSelectDate: Bool = true
    @State private var didSelectTime: Bool = true
    @State private var navigateToWaitingRoom: Bool = false

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && didSelectDate
        && didSelectTime
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {

                // Top Bar
                HStack(spacing: 12) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(AppColors.text)
                            .frame(width: 24, height: 24)
                    }
                    .buttonStyle(.plain)

                    Text("약속 만들기")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(AppColors.text)

                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
                .padding(.leading, 24)
                .padding(.top, 16)
                .padding(.bottom, 17)
                .background(Color.white)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(AppColors.border)
                        .frame(height: 1)
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // 아이콘 박스
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(LinearGradient(
                                colors: [Color(red: 0.30, green: 0.70, blue: 1.0),
                                         Color(red: 0.22, green: 0.56, blue: 0.98)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 96, height: 96)
                            .overlay(
                                Image(systemName: "calendar")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.top, 12)

                        VStack(spacing: 8) {
                            Text("새로운 약속을 만들어보세요")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(AppColors.text)
                            Text("친구들과의 만남을 위한 정보를 입력해주세요")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(AppColors.subText)
                        }
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("약속 이름 *")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppColors.text)

                            TextField("약속 이름을 입력하세요", text: $title)
                                .textInputAutocapitalization(.never)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(AppColors.border, lineWidth: 1)
                                )

                            HStack {
                                Text("예: 대학 동기 모임, 회사 회식, 생일 파티")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundStyle(AppColors.subText)
                                Spacer()
                                Text("\(min(title.count, 50))/50")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundStyle(AppColors.subText)
                            }
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("만날 날짜 *")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppColors.text)

                            ZStack(alignment: .trailing) {
                                DatePicker(
                                    "",
                                    selection: $date,
                                    displayedComponents: [.date]
                                )
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .environment(\.locale, Locale(identifier: "ko_KR"))
                                .onChange(of: date) { _ in
                                    didSelectDate = true
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                Image(systemName: "calendar")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(AppColors.text)
                                    .padding(.trailing, 14)
                                    .allowsHitTesting(false)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("만날 시간 *")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppColors.text)

                            ZStack(alignment: .trailing) {
                                DatePicker(
                                    "",
                                    selection: $time,
                                    displayedComponents: [.hourAndMinute]
                                )
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .environment(\.locale, Locale(identifier: "ko_KR"))
                                .onChange(of: time) { _ in
                                    didSelectTime = true
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)

                                Image(systemName: "clock")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(AppColors.text)
                                    .padding(.trailing, 14)
                                    .allowsHitTesting(false)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(AppColors.border, lineWidth: 1)
                            )
                        }

                        Button(action: { navigateToWaitingRoom = true }) {
                            Text("약속 생성하기")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(isValid ? Color.white : Color.white.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(
                                    LinearGradient(
                                        colors: isValid
                                        ? [Color(red: 0.07, green: 0.65, blue: 0.96),
                                           Color(red: 0.16, green: 0.40, blue: 0.95)]
                                        : [Color(red: 0.55, green: 0.80, blue: 0.98),
                                           Color(red: 0.52, green: 0.67, blue: 0.95)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: Color.black.opacity(isValid ? 0.12 : 0.06), radius: 12, x: 0, y: 6)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                        .disabled(!isValid)

                        NavigationLink(
                            destination: DepartureSetupView(),
                            isActive: $navigateToWaitingRoom
                        ) {
                            EmptyView()
                        }
                        .hidden()

                        Text("모든 필수 정보를 입력해주세요")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(AppColors.subText)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar) // ✅ 탭바 숨김
    }
}
