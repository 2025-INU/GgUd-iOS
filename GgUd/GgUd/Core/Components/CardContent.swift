import SwiftUI

struct HomePromise: Identifiable {
    let id = UUID()
    let title: String
    let date: String
    let time: String
    let people: Int
    let place: String
    let statusText: String
    let confirmedPlace: String?
}

struct CardContent: View {
    let item: HomePromise
    let isScheduled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color(hex: "#111827"))

                    HStack(spacing: 8) {
                        HomeDateIcon()
                            .frame(width: 12, height: 12)
                        Text(item.date)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color(hex: "#4B5563"))
                    }

                    HStack(spacing: 8) {
                        HomeTimeIcon()
                            .frame(width: 12, height: 12)
                        Text(item.time)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color(hex: "#4B5563"))
                    }
                }

                Spacer()

                Text(item.statusText)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(isScheduled ? Color(hex: "#2563EB") : Color(hex: "#16A34A"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(isScheduled ? Color(hex: "#DBEAFE") : Color(hex: "#DCFCE7"))
                    .clipShape(Capsule())
            }

            Spacer().frame(height: 24)

            HStack(alignment: .center) {
                avatarGroup

                Text("\(item.people)명")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: "#4B5563"))
                    .padding(.leading, 12)

                Spacer()
            }

            Spacer().frame(height: 16)

            HStack(spacing: 6) {
                HomeLocationPinIcon()
                    .frame(width: 11, height: 13)
                Text(item.place)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: "#4B5563"))
            }

            if isScheduled, let confirmed = item.confirmedPlace {
                Spacer().frame(height: 12)

                VStack(alignment: .leading, spacing: 8) {
                    Text("확정된 장소")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "#374151"))

                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hex: "#3B82F6"))
                            .frame(width: 8, height: 8)
                        Text(confirmed)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(hex: "#4B5563"))
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "#F3F4F6"))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(25)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: "#E5E7EB"), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var avatarGroup: some View {
        HStack(spacing: -8) {
            ForEach(0..<min(item.people, 4), id: \.self) { i in
                Circle()
                    .fill(avatarColor(at: i))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .overlay(
                        Circle().stroke(Color.white, lineWidth: 2)
                    )
            }

            if item.people > 4 {
                Circle()
                    .fill(Color(hex: "#C5CAD3"))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text("+\(item.people - 4)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color(hex: "#4B5563"))
                    )
                    .overlay(
                        Circle().stroke(Color.white, lineWidth: 2)
                    )
            }
        }
    }

    private func avatarColor(at index: Int) -> Color {
        let palette: [Color] = [
            Color(hex: "#EF4444"),
            Color(hex: "#3B82F6"),
            Color(hex: "#22C55E"),
            Color(hex: "#A855F7")
        ]
        let seed = abs(item.id.uuidString.hashValue)
        return palette[(seed + index) % palette.count]
    }
}
