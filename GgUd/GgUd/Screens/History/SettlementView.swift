//
//  SettlementView.swift
//  GgUd
//
//

import SwiftUI

struct SettlementView: View {
    @Environment(\.dismiss) private var dismiss

    let appointmentTitle: String

    @State private var amounts: [String] = Array(repeating: "0", count: 4)

    private let members: [SettlementMember] = [
        .init(name: "김민수", color: Color(red: 0.97, green: 0.36, blue: 0.35)),
        .init(name: "이지은", color: Color(red: 0.23, green: 0.52, blue: 0.98)),
        .init(name: "박준호", color: Color(red: 0.21, green: 0.78, blue: 0.43)),
        .init(name: "최수영", color: Color(red: 0.65, green: 0.44, blue: 0.96))
    ]

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                AppBar(title: "정산하기", subtitle: appointmentTitle, onBack: { dismiss() })

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        summaryCard

                        Text("각자 결제한 금액")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(AppColors.text)

                        VStack(spacing: 16) {
                            ForEach(Array(members.enumerated()), id: \.offset) { index, member in
                                SettlementRow(
                                    member: member,
                                    amount: $amounts[index],
                                    roleText: balanceText(for: index),
                                    roleColor: balanceColor(for: index),
                                    onFormat: { formatAmountString($0) }
                                )
                            }
                        }

                        Text("정산 결과")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(AppColors.text)

                        VStack(spacing: 12) {
                            ForEach(Array(balances.enumerated()), id: \.offset) { index, entry in
                                BalanceRow(entry: entry)
                            }
                        }

                        Text("상세 정산 내역")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(AppColors.text)
                            .padding(.top, 6)

                        VStack(spacing: 12) {
                            ForEach(Array(transfers.enumerated()), id: \.offset) { index, t in
                                TransferRow(transfer: t)
                            }
                        }

                        Button(action: {}) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                Text("정산 완료하기")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.13, green: 0.77, blue: 0.37),
                                             Color(red: 0.02, green: 0.59, blue: 0.41)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color.black.opacity(0.10), radius: 15, x: 0, y: 10)
                            .shadow(color: Color.black.opacity(0.10), radius: 6, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var summaryCard: some View {
        VStack(spacing: 12) {
            Text("총 결제 금액")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppColors.text)

            Text("\(formatAmount(totalAmount))원")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(AppColors.primary)

            Text("1인당 \(formatAmount(perPerson))원")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.subText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(Color(red: 0.93, green: 0.97, blue: 1.0))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

#Preview {
    SettlementView(appointmentTitle: "친구들과 카페 모임")
}


private struct SettlementMember: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
}

private struct SettlementRow: View {
    let member: SettlementMember
    @Binding var amount: String
    let roleText: String
    let roleColor: Color
    let onFormat: (String) -> String

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
                Text(member.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.text)

                Text(roleText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(roleColor)
            }

            Spacer()

            HStack(spacing: 8) {
                TextField("0", text: $amount)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.text)
                    .padding(.horizontal, 12)
                    .frame(width: 84, height: 40)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                    .onChange(of: amount) { newValue in
                        let formatted = onFormat(newValue)
                        if formatted != newValue {
                            amount = formatted
                        }
                    }

                Text("원")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.subText)
            }
        }
        .padding(16)
        .background(Color(red: 0.97, green: 0.97, blue: 0.98))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct BalanceEntry {
    let member: SettlementMember
    let amount: Int
}

private struct BalanceRow: View {
    let entry: BalanceEntry

    private var isReceiver: Bool { entry.amount > 0 }

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(entry.member.color)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.member.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.text)

                Text(isReceiver ? "받을 사람" : "보낼 사람")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isReceiver ? Color(red: 0.20, green: 0.45, blue: 0.95) : Color(red: 0.96, green: 0.45, blue: 0.20))
            }

            Spacer()

            Text(isReceiver ? "+\(formatAmount(entry.amount))원" : "\(formatAmount(abs(entry.amount)))원")
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

private struct TransferItem {
    let from: SettlementMember
    let to: SettlementMember
    let amount: Int
}

private struct TransferRow: View {
    let transfer: TransferItem

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(transfer.from.color)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(transfer.from.name)
                    .font(.system(size: 14, weight: .bold))
                Text("보내는 사람")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(AppColors.subText)
            }

            Image(systemName: "arrow.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppColors.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(transfer.to.name)
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

    var numericAmounts: [Int] {
        amounts.map { Int($0.filter(\.isNumber)) ?? 0 }
    }

    var totalAmount: Int {
        numericAmounts.reduce(0, +)
    }

    var perPerson: Int {
        guard !members.isEmpty else { return 0 }
        return totalAmount / members.count
    }

    var balances: [BalanceEntry] {
        zip(members, numericAmounts).map { member, paid in
            BalanceEntry(member: member, amount: paid - perPerson)
        }
    }

    func balanceText(for index: Int) -> String {
        let value = balances[index].amount
        return value >= 0 ? "받을 사람" : "보낼 사람"
    }

    func balanceColor(for index: Int) -> Color {
        let value = balances[index].amount
        return value >= 0 ? Color(red: 0.20, green: 0.45, blue: 0.95) : Color(red: 0.96, green: 0.45, blue: 0.20)
    }

    var transfers: [TransferItem] {
        var senders = balances.filter { $0.amount < 0 }.map { (member: $0.member, amount: -$0.amount) }
        var receivers = balances.filter { $0.amount > 0 }.map { (member: $0.member, amount: $0.amount) }
        var result: [TransferItem] = []

        var i = 0
        var j = 0
        while i < senders.count && j < receivers.count {
            let send = min(senders[i].amount, receivers[j].amount)
            result.append(TransferItem(from: senders[i].member, to: receivers[j].member, amount: send))
            senders[i].amount -= send
            receivers[j].amount -= send
            if senders[i].amount == 0 { i += 1 }
            if receivers[j].amount == 0 { j += 1 }
        }
        return result
    }

}

private func formatAmount(_ value: Int) -> String {
    SettlementView.numberFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
}
