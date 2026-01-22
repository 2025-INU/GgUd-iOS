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

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {

                // Top Bar
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(AppColors.text)
                            .frame(width: 44, height: 44, alignment: .leading)
                    }

                    Spacer()

                    Text("약속 만들기")
                        .font(AppFonts.body(17))
                        .foregroundStyle(AppColors.text)

                    Spacer()

                    // 오른쪽 정렬 맞추기용 더미
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {

                        // 약속 이름
                        VStack(alignment: .leading, spacing: 8) {
                            Text("약속 이름")
                                .font(AppFonts.body(14))
                                .foregroundStyle(AppColors.text)

                            TextField("온석 생일", text: $title)
                                .textInputAutocapitalization(.never)
                                .padding(.vertical, 10)
                                .overlay(
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundStyle(.black.opacity(0.4)),
                                    alignment: .bottom
                                )
                        }

                        // 날짜/시간
                        VStack(alignment: .leading, spacing: 8) {
                            Text("날짜 / 시간")
                                .font(AppFonts.body(14))
                                .foregroundStyle(AppColors.text)

                            DatePicker(
                                "",
                                selection: $date,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .environment(\.locale, Locale(identifier: "ko_KR")) // 한국어 표시
                        }

                        // 지도 미리보기
                        MapPreviewBox()
                            .frame(height: 220)

                        // 버튼들
                        PrimaryButton(title: "친구 초대") {
                            print("친구 초대")
                        }

                        NavigationLink {
                            WaitingRoomView()
                        } label: {
                            Text("약속 만들기")
                                .font(AppFonts.body(16))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppColors.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)


                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)      // ✅ 여기 값을 크게 두면 위 공백이 커져
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar) // ✅ 탭바 숨김
    }
}
