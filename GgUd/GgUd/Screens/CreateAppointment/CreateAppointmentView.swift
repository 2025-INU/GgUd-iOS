import SwiftUI

struct CreateAppointmentView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var selectedDate: Date?
    @State private var selectedTime: Date?

    @State private var showDateDialog = false
    @State private var showTimeDialog = false

    @State private var isNameFocused = false
    @State private var isDateFocused = false
    @State private var isTimeFocused = false

    @State private var dateDraft = Date()
    @State private var timeDraft = Date()

    @State private var navigateToWaitingRoom = false

    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && selectedDate != nil
        && selectedTime != nil
    }

    private var dateText: String {
        guard let selectedDate else { return "-/-/-" }
        return selectedDate.formatted(.dateTime.year().month(.twoDigits).day(.twoDigits).locale(Locale(identifier: "ko_KR")))
    }

    private var timeText: String {
        guard let selectedTime else { return "--:--" }
        return selectedTime.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(Locale(identifier: "ko_KR")))
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                AppBar(title: "약속 만들기", onBack: { dismiss() })

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 11)

                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#38BDF8"), Color(hex: "#3B82F6")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .overlay(
                                PromiseCreateIcon()
                                    .frame(width: 25, height: 25)
                            )

                        Spacer().frame(height: 24)

                        Text("새로운 약속을 만들어보세요")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(Color(hex: "#111827"))

                        Spacer().frame(height: 8)

                        Text("친구들과의 만남을 위한 정보를 입력해주세요")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color(hex: "#4B5563"))

                        Spacer().frame(height: 32)

                        VStack(alignment: .leading, spacing: 0) {
                            Text("약속 이름 *")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color(hex: "#374151"))

                            Spacer().frame(height: 12)

                            TextField("약속 이름을 입력하세요", text: $title)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(Color(hex: "#111827"))
                                .padding(17)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(isNameFocused ? Color(hex: "#3B82F6") : Color(hex: "#E5E7EB"), lineWidth: 1)
                                )
                                .onTapGesture {
                                    isNameFocused = true
                                    isDateFocused = false
                                    isTimeFocused = false
                                }
                                .onChange(of: title) { _, newValue in
                                    if newValue.count > 50 {
                                        title = String(newValue.prefix(50))
                                    }
                                }

                            Spacer().frame(height: 8)

                            HStack {
                                Text("예: 대학 동기 모임, 회사 회식, 생일 파티")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundStyle(Color(hex: "#6B7280"))
                                Spacer()
                                Text("\(title.count)/50")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundStyle(Color(hex: "#6B7280"))
                            }
                        }

                        Spacer().frame(height: 24)

                        VStack(alignment: .leading, spacing: 0) {
                            Text("만날 날짜 *")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color(hex: "#374151"))

                            Spacer().frame(height: 12)

                            Button {
                                hideAllFocus()
                                isDateFocused = true
                                dateDraft = selectedDate ?? Date()
                                showDateDialog = true
                            } label: {
                                HStack {
                                    Text(dateText)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundStyle(Color(hex: "#111827"))
                                    Spacer()
                                    Image(systemName: "calendar")
                                        .font(.system(size: 18, weight: .regular))
                                        .foregroundStyle(Color(hex: "#111827"))
                                }
                                .padding(17)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(isDateFocused ? Color(hex: "#3B82F6") : Color(hex: "#E5E7EB"), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer().frame(height: 24)

                        VStack(alignment: .leading, spacing: 0) {
                            Text("만날 시간 *")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color(hex: "#374151"))

                            Spacer().frame(height: 12)

                            Button {
                                hideAllFocus()
                                isTimeFocused = true
                                timeDraft = selectedTime ?? Date()
                                showTimeDialog = true
                            } label: {
                                HStack {
                                    Text(timeText)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundStyle(Color(hex: "#111827"))
                                    Spacer()
                                    Image(systemName: "clock")
                                        .font(.system(size: 18, weight: .regular))
                                        .foregroundStyle(Color(hex: "#111827"))
                                }
                                .padding(17)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(isTimeFocused ? Color(hex: "#3B82F6") : Color(hex: "#E5E7EB"), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer().frame(height: 48)

                        Button {
                            navigateToWaitingRoom = true
                        } label: {
                            Text("약속 생성하기")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 58)
                                .background(
                                    LinearGradient(
                                        colors: isFormValid
                                        ? [Color(hex: "#38BDF8"), Color(hex: "#2563EB")]
                                        : [Color(hex: "#8ECDF3"), Color(hex: "#8AA6E8")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(!isFormValid)

                        Spacer().frame(height: 12)

                        Text("모든 필수 정보를 입력해주세요")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color(hex: "#6B7280"))

                        Spacer().frame(height: 24)
                    }
                    .padding(.horizontal, 24)
                }
            }

            NavigationLink(destination: DepartureSetupView(), isActive: $navigateToWaitingRoom) {
                EmptyView()
            }
            .hidden()
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showDateDialog) {
            SelectionSheet(
                title: "날짜 선택",
                onCancel: {
                    showDateDialog = false
                    isDateFocused = false
                },
                onConfirm: {
                    selectedDate = dateDraft
                    showDateDialog = false
                    isDateFocused = false
                }
            ) {
                DatePicker("", selection: $dateDraft, displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "ko_KR"))
            }
        }
        .sheet(isPresented: $showTimeDialog) {
            SelectionSheet(
                title: "시간 선택",
                onCancel: {
                    showTimeDialog = false
                    isTimeFocused = false
                },
                onConfirm: {
                    selectedTime = timeDraft
                    showTimeDialog = false
                    isTimeFocused = false
                }
            ) {
                DatePicker("", selection: $timeDraft, displayedComponents: [.hourAndMinute])
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "ko_KR"))
            }
        }
    }

    private func hideAllFocus() {
        isNameFocused = false
        isDateFocused = false
        isTimeFocused = false
    }
}

private struct PromiseCreateIcon: View {
    var body: some View {
        PromiseCreateIconShape()
            .fill(Color.white)
            .accessibilityHidden(true)
    }
}

private struct PromiseCreateIconShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 18.75, y: 2.5))
        path.addLine(to: CGPoint(x: 23.75, y: 2.5))
        path.addCurve(to: CGPoint(x: 24.6375, y: 2.8625), control1: CGPoint(x: 24.1, y: 2.5), control2: CGPoint(x: 24.3958, y: 2.62083))
        path.addCurve(to: CGPoint(x: 25.0, y: 3.75), control1: CGPoint(x: 24.8792, y: 3.10417), control2: CGPoint(x: 25.0, y: 3.4))
        path.addLine(to: CGPoint(x: 25.0, y: 23.75))
        path.addCurve(to: CGPoint(x: 24.6375, y: 24.6375), control1: CGPoint(x: 25.0, y: 24.1), control2: CGPoint(x: 24.8792, y: 24.3958))
        path.addCurve(to: CGPoint(x: 23.75, y: 25.0), control1: CGPoint(x: 24.3958, y: 24.8792), control2: CGPoint(x: 24.1, y: 25.0))
        path.addLine(to: CGPoint(x: 1.25, y: 25.0))
        path.addCurve(to: CGPoint(x: 0.3625, y: 24.6375), control1: CGPoint(x: 0.9, y: 25.0), control2: CGPoint(x: 0.604167, y: 24.8792))
        path.addCurve(to: CGPoint(x: 0.0, y: 23.75), control1: CGPoint(x: 0.120833, y: 24.3958), control2: CGPoint(x: 0.0, y: 24.1))
        path.addLine(to: CGPoint(x: 0.0, y: 3.75))
        path.addCurve(to: CGPoint(x: 0.3625, y: 2.8625), control1: CGPoint(x: 0.0, y: 3.4), control2: CGPoint(x: 0.120833, y: 3.10417))
        path.addCurve(to: CGPoint(x: 1.25, y: 2.5), control1: CGPoint(x: 0.604167, y: 2.62083), control2: CGPoint(x: 0.9, y: 2.5))
        path.addLine(to: CGPoint(x: 6.25, y: 2.5))
        path.addLine(to: CGPoint(x: 6.25, y: 0.0))
        path.addLine(to: CGPoint(x: 8.75, y: 0.0))
        path.addLine(to: CGPoint(x: 8.75, y: 2.5))
        path.addLine(to: CGPoint(x: 16.25, y: 2.5))
        path.addLine(to: CGPoint(x: 16.25, y: 0.0))
        path.addLine(to: CGPoint(x: 18.75, y: 0.0))
        path.addLine(to: CGPoint(x: 18.75, y: 2.5))
        path.closeSubpath()

        path.move(to: CGPoint(x: 2.5, y: 10.0))
        path.addLine(to: CGPoint(x: 2.5, y: 22.5))
        path.addLine(to: CGPoint(x: 22.5, y: 22.5))
        path.addLine(to: CGPoint(x: 22.5, y: 10.0))
        path.addLine(to: CGPoint(x: 2.5, y: 10.0))
        path.closeSubpath()

        path.move(to: CGPoint(x: 5.0, y: 15.0))
        path.addLine(to: CGPoint(x: 11.25, y: 15.0))
        path.addLine(to: CGPoint(x: 11.25, y: 20.0))
        path.addLine(to: CGPoint(x: 5.0, y: 20.0))
        path.addLine(to: CGPoint(x: 5.0, y: 15.0))
        path.closeSubpath()

        let scaleX = rect.width / 25.0
        let scaleY = rect.height / 25.0
        return path.applying(CGAffineTransform(scaleX: scaleX, y: scaleY))
    }
}

private struct SelectionSheet<Content: View>: View {
    let title: String
    let onCancel: () -> Void
    let onConfirm: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                content
                    .padding()
                Spacer()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소", action: onCancel)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("확인", action: onConfirm)
                }
            }
            .background(Color.white)
        }
        .presentationDetents([.medium, .large])
    }
}
