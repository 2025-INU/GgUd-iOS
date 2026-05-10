//
//  SettlementView.swift
//  GgUd
//
//

import SwiftUI

struct SettlementView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var userSession: UserSessionStore

    let promiseId: Int64
    let appointmentTitle: String
    let hostId: Int64?

    @State private var settlement: SettlementResponse?
    @State private var myAmountText = ""
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var isSavingMyExpense = false
    @State private var isCompletingSettlement = false
    @State private var actionMessage: String?
    @State private var isShowingActionAlert = false

    private let palette: [Color] = [
        Color(red: 0.97, green: 0.36, blue: 0.35),
        Color(red: 0.23, green: 0.52, blue: 0.98),
        Color(red: 0.21, green: 0.78, blue: 0.43),
        Color(red: 0.65, green: 0.44, blue: 0.96),
        Color(red: 0.95, green: 0.68, blue: 0.08)
    ]

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                AppBar(title: "정산하기", subtitle: appointmentTitle, onBack: { dismiss() })

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        summaryCard

                        if isLoading {
                            loadingSection
                        } else if let loadError {
                            errorSection(loadError)
                        } else if let settlement {
                            expenseSection(settlement)
                            balanceSection(settlement)
                            transferSection(settlement)
                            actionSection(settlement)
                        } else {
                            errorSection("정산 정보를 불러오지 못했어요.")
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
            }
        }
        .navigationBarHidden(true)
        .alert("정산", isPresented: $isShowingActionAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(actionMessage ?? "")
        }
        .task(id: promiseId) {
            await loadSettlement()
        }
    }

    private var summaryCard: some View {
        VStack(spacing: 12) {
            Text("총 결제 금액")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppColors.text)

            Text("\(formatAmount(totalAmount))원")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(AppColors.primary)

            Text("1인당 \(formatAmount(perPersonAmount))원")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.subText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(Color(red: 0.93, green: 0.97, blue: 1.0))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var loadingSection: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
            Text("정산 정보를 불러오는 중...")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppColors.subText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private func errorSection(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.red)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Button("다시 불러오기") {
                Task { await loadSettlement() }
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(AppColors.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private func expenseSection(_ settlement: SettlementResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("각자 결제한 금액")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppColors.text)

            VStack(spacing: 16) {
                ForEach(memberEntries) { member in
                    SettlementRow(
                        member: member,
                        amount: bindingAmount(for: member),
                        roleText: settlementRoleText(for: member),
                        roleColor: settlementRoleColor(for: member),
                        isEditable: member.isMine && !(settlement.settlementCompleted ?? false),
                        isSaving: isSavingMyExpense && member.isMine,
                        onFormat: { formatAmountString($0) },
                        onSave: {
                            Task { await saveMyExpense() }
                        }
                    )
                }
            }
        }
    }

    private func balanceSection(_ settlement: SettlementResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("정산 결과")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppColors.text)

            VStack(spacing: 12) {
                ForEach(memberEntries.filter { ($0.balanceAmount ?? 0) != 0 }) { entry in
                    BalanceRow(entry: entry)
                }
            }
        }
    }

    private func transferSection(_ settlement: SettlementResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("상세 정산 내역")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppColors.text)
                .padding(.top, 6)

            if transferItems.isEmpty {
                Text(settlement.settlementCompleted == true ? "정산이 완료되었어요." : "아직 생성된 이체 내역이 없어요.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.subText)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 12) {
                    ForEach(transferItems) { transfer in
                        TransferRow(transfer: transfer)
                    }
                }
            }
        }
    }

    private func actionSection(_ settlement: SettlementResponse) -> some View {
        VStack(spacing: 12) {
            if isCurrentUserHost {
                Button(action: {
                    Task { await completeSettlement() }
                }) {
                    HStack(spacing: 8) {
                        if isCompletingSettlement {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Image(systemName: settlement.settlementCompleted == true ? "checkmark.circle.fill" : "checkmark")
                                .font(.system(size: 16, weight: .bold))
                        }

                        Text(settlement.settlementCompleted == true ? "정산 완료됨" : "정산 완료하기")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: settlement.settlementCompleted == true
                                ? [Color(hex: "#9CA3AF"), Color(hex: "#6B7280")]
                                : [Color(red: 0.13, green: 0.77, blue: 0.37), Color(red: 0.02, green: 0.59, blue: 0.41)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.black.opacity(0.10), radius: 15, x: 0, y: 10)
                    .shadow(color: Color.black.opacity(0.10), radius: 6, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .disabled(settlement.settlementCompleted == true || isCompletingSettlement)
            } else {
                Text("호스트가 정산을 완료할 수 있어요.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppColors.subText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
            }
        }
    }

    private var totalAmount: Int {
        Int((settlement?.totalAmount ?? 0).rounded())
    }

    private var perPersonAmount: Int {
        Int((settlement?.perPersonAmount ?? 0).rounded())
    }

    private var memberEntries: [SettlementMember] {
        (settlement?.expenses ?? []).enumerated().map { index, expense in
            SettlementMember(
                userId: expense.userId,
                name: expense.nickname ?? "참여자",
                color: palette[index % palette.count],
                paidAmount: expense.paidAmount,
                balanceAmount: expense.balanceAmount,
                status: expense.status,
                isMine: expense.userId == userSession.kakaoUserId
            )
        }
    }

    private var transferItems: [TransferItem] {
        (settlement?.transfers ?? []).map { transfer in
            let fromColor = colorFor(userId: transfer.fromUserId)
            let toColor = colorFor(userId: transfer.toUserId)
            return TransferItem(
                fromName: transfer.fromNickname ?? "참여자",
                fromColor: fromColor,
                toName: transfer.toNickname ?? "참여자",
                toColor: toColor,
                amount: Int((transfer.amount ?? 0).rounded())
            )
        }
    }

    private var isCurrentUserHost: Bool {
        guard let hostId else { return false }
        return hostId == userSession.kakaoUserId
    }

    private func colorFor(userId: Int64?) -> Color {
        guard let userId,
              let index = memberEntries.firstIndex(where: { $0.userId == userId }) else {
            return palette[0]
        }
        return palette[index % palette.count]
    }

    private func bindingAmount(for member: SettlementMember) -> Binding<String> {
        guard member.isMine else {
            return .constant(formatAmount(Int((member.paidAmount ?? 0).rounded())))
        }

        return Binding(
            get: { myAmountText },
            set: { myAmountText = $0 }
        )
    }

    @MainActor
    private func loadSettlement() async {
        guard let accessToken = userSession.backendAccessToken, !accessToken.isEmpty else {
            loadError = "로그인이 필요합니다."
            settlement = nil
            return
        }

        isLoading = true
        loadError = nil

        await withCheckedContinuation { continuation in
            PromiseAPIClient.shared.getSettlement(
                promiseId: promiseId,
                accessToken: accessToken,
                tokenType: userSession.backendTokenType ?? "Bearer"
            ) { result in
                DispatchQueue.main.async {
                    isLoading = false
                    switch result {
                    case let .success(response):
                        settlement = response
                        loadError = nil
                        if let myExpense = response.expenses?.first(where: { $0.userId == userSession.kakaoUserId }) {
                            myAmountText = formatAmount(Int((myExpense.paidAmount ?? 0).rounded()))
                        }
                    case let .failure(error):
                        settlement = nil
                        loadError = error.localizedDescription
                    }
                    continuation.resume()
                }
            }
        }
    }

    @MainActor
    private func saveMyExpense() async {
        guard let accessToken = userSession.backendAccessToken, !accessToken.isEmpty else {
            actionMessage = "로그인이 필요합니다."
            isShowingActionAlert = true
            return
        }

        let numeric = Int(myAmountText.filter(\.isNumber)) ?? 0
        guard numeric >= 0 else {
            actionMessage = "정산 금액을 다시 확인해주세요."
            isShowingActionAlert = true
            return
        }
        isSavingMyExpense = true

        await withCheckedContinuation { continuation in
            PromiseAPIClient.shared.updateMyExpense(
                promiseId: promiseId,
                accessToken: accessToken,
                tokenType: userSession.backendTokenType ?? "Bearer",
                amount: numeric
            ) { result in
                DispatchQueue.main.async {
                    isSavingMyExpense = false
                    switch result {
                    case let .success(response):
                        settlement = response
                        actionMessage = "내 결제 금액을 저장했어요."
                        isShowingActionAlert = true
                    case let .failure(error):
                        print("[Settlement] saveMyExpense error:", error.localizedDescription)
                        actionMessage = friendlySettlementErrorMessage(error)
                        isShowingActionAlert = true
                    }
                    continuation.resume()
                }
            }
        }
    }

    private func friendlySettlementErrorMessage(_ error: Error) -> String {
        guard let apiError = error as? AuthAPIError else {
            return error.localizedDescription
        }

        switch apiError {
        case let .server(statusCode, message):
            if statusCode == 500 {
                return "정산 금액을 저장하지 못했어요. 서버에 잠시 문제가 있어요. 잠시 후 다시 시도해주세요."
            }
            if statusCode == 400 {
                return "지금은 정산 금액을 수정할 수 없어요. 약속 상태를 확인해주세요."
            }
            if statusCode == 403 {
                return "내 결제 금액만 수정할 수 있어요."
            }
            if statusCode == 404 {
                return "약속 정보를 찾지 못했어요."
            }
            return "정산 금액을 저장하지 못했어요. (\(statusCode))"
        default:
            return error.localizedDescription
        }
    }

    @MainActor
    private func completeSettlement() async {
        guard let accessToken = userSession.backendAccessToken, !accessToken.isEmpty else {
            actionMessage = "로그인이 필요합니다."
            isShowingActionAlert = true
            return
        }

        isCompletingSettlement = true

        await withCheckedContinuation { continuation in
            PromiseAPIClient.shared.completeSettlement(
                promiseId: promiseId,
                accessToken: accessToken,
                tokenType: userSession.backendTokenType ?? "Bearer"
            ) { result in
                DispatchQueue.main.async {
                    isCompletingSettlement = false
                    switch result {
                    case let .success(response):
                        settlement = response
                        actionMessage = "정산을 완료했어요."
                        isShowingActionAlert = true
                    case let .failure(error):
                        print("[Settlement] saveMyExpense error:", error.localizedDescription)
                        actionMessage = friendlySettlementErrorMessage(error)
                        isShowingActionAlert = true
                    }
                    continuation.resume()
                }
            }
        }
    }
}

#Preview {
    SettlementView(promiseId: 1, appointmentTitle: "친구들과 카페 모임", hostId: 1)
        .environmentObject(UserSessionStore())
}

private struct SettlementMember: Identifiable {
    let id = UUID()
    let userId: Int64?
    let name: String
    let color: Color
    let paidAmount: Double?
    let balanceAmount: Double?
    let status: String?
    let isMine: Bool
}

private struct SettlementRow: View {
    let member: SettlementMember
    @Binding var amount: String
    let roleText: String
    let roleColor: Color
    let isEditable: Bool
    let isSaving: Bool
    let onFormat: (String) -> String
    let onSave: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(member.color)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(member.isMine ? "\(member.name) (나)" : member.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.text)

                Text(roleText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(roleColor)
            }

            Spacer()

            if isEditable {
                HStack(spacing: 8) {
                    TextField("0", text: $amount)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppColors.text)
                        .padding(.horizontal, 12)
                        .frame(width: 96, height: 40)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                        .onChange(of: amount) { _, newValue in
                            let formatted = onFormat(newValue)
                            if formatted != newValue {
                                amount = formatted
                            }
                        }

                    Button(action: onSave) {
                        Group {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            } else {
                                Text("저장")
                                    .font(.system(size: 13, weight: .bold))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 40)
                        .background(AppColors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text("\(formatAmount(Int((member.paidAmount ?? 0).rounded())))원")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppColors.text)
            }
        }
        .padding(16)
        .background(Color(red: 0.97, green: 0.97, blue: 0.98))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct BalanceRow: View {
    let entry: SettlementMember

    private var amount: Int { Int((entry.balanceAmount ?? 0).rounded()) }
    private var isReceiver: Bool { amount > 0 }

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(entry.color)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.text)

                Text(isReceiver ? "받을 사람" : "보낼 사람")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isReceiver ? Color(red: 0.20, green: 0.45, blue: 0.95) : Color(red: 0.96, green: 0.45, blue: 0.20))
            }

            Spacer()

            Text(isReceiver ? "+\(formatAmount(amount))원" : "\(formatAmount(abs(amount)))원")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(isReceiver ? Color(red: 0.20, green: 0.45, blue: 0.95) : Color(red: 0.96, green: 0.45, blue: 0.20))
        }
        .padding(16)
        .background(isReceiver ? Color(red: 0.93, green: 0.96, blue: 1.0) : Color(red: 1.0, green: 0.95, blue: 0.90))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isReceiver ? Color(red: 0.70, green: 0.82, blue: 0.98) : Color(red: 0.96, green: 0.75, blue: 0.60), lineWidth: 1)
        )
    }
}

private struct TransferItem: Identifiable {
    let id = UUID()
    let fromName: String
    let fromColor: Color
    let toName: String
    let toColor: Color
    let amount: Int
}

private struct TransferRow: View {
    let transfer: TransferItem

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(transfer.fromColor)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(transfer.fromName)
                    .font(.system(size: 14, weight: .bold))
                Text("보내는 사람")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(AppColors.subText)
            }

            Image(systemName: "arrow.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppColors.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(transfer.toName)
                    .font(.system(size: 14, weight: .bold))
                Text("받는 사람")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(AppColors.subText)
            }

            Spacer()

            Text("\(formatAmount(transfer.amount))원")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppColors.primary)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(red: 0.90, green: 0.91, blue: 0.92), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

private extension SettlementView {
    static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    func formatAmountString(_ value: String) -> String {
        let digits = value.filter(\.isNumber)
        guard let number = Int(digits) else { return "" }
        return SettlementView.numberFormatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    func settlementRoleText(for member: SettlementMember) -> String {
        let value = Int((member.balanceAmount ?? 0).rounded())
        if member.isMine {
            return "내 결제 금액"
        }
        return value >= 0 ? "받을 사람" : "보낼 사람"
    }

    func settlementRoleColor(for member: SettlementMember) -> Color {
        if member.isMine {
            return AppColors.primary
        }
        let value = Int((member.balanceAmount ?? 0).rounded())
        return value >= 0 ? Color(red: 0.20, green: 0.45, blue: 0.95) : Color(red: 0.96, green: 0.45, blue: 0.20)
    }
}

private func formatAmount(_ value: Int) -> String {
    SettlementView.numberFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
}
