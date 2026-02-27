import SwiftUI

struct SyringeView: View {
    let fillFraction: Double // 0...1
    let units: Double

    private let syringeWidth: CGFloat = 50
    private let barrelHeight: CGFloat = 140
    private let tickCount = 10

    var body: some View {
        VStack(spacing: 4) {
            Text("\(String(format: "%.1f", units)) units")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(fillFraction > 0 ? .green : .secondary)

            GeometryReader { geo in
                let centerX = geo.size.width / 2

                ZStack {
                    // Barrel outline
                    syringeBarrel(centerX: centerX)

                    // Fill
                    syringeFill(centerX: centerX)

                    // Tick marks
                    syringeTicks(centerX: centerX)

                    // Needle
                    syringeNeedle(centerX: centerX)

                    // Plunger
                    syringePlunger(centerX: centerX)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: fillFraction)
    }

    private func syringeBarrel(centerX: CGFloat) -> some View {
        let barrelRect = CGRect(
            x: centerX - syringeWidth / 2,
            y: 20,
            width: syringeWidth,
            height: barrelHeight
        )
        return RoundedRectangle(cornerRadius: 6)
            .stroke(Color(.systemGray3), lineWidth: 2)
            .frame(width: barrelRect.width, height: barrelRect.height)
            .position(x: centerX, y: barrelRect.midY)
    }

    private func syringeFill(centerX: CGFloat) -> some View {
        let clampedFill = min(max(fillFraction, 0), 1)
        let fillHeight = barrelHeight * clampedFill
        let barrelBottom: CGFloat = 20 + barrelHeight

        return RoundedRectangle(cornerRadius: 4)
            .fill(
                LinearGradient(
                    colors: [.green.opacity(0.3), .green.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: syringeWidth - 4, height: fillHeight)
            .position(x: centerX, y: barrelBottom - fillHeight / 2)
    }

    private func syringeTicks(centerX: CGFloat) -> some View {
        ForEach(0...tickCount, id: \.self) { i in
            let y = 20 + barrelHeight - (barrelHeight * CGFloat(i) / CGFloat(tickCount))
            let isMajor = i % 5 == 0
            let tickWidth: CGFloat = isMajor ? 14 : 8

            HStack(spacing: 2) {
                Rectangle()
                    .fill(Color(.systemGray3))
                    .frame(width: tickWidth, height: 1)

                if isMajor {
                    Text("\(i * 10)")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
            }
            .position(x: centerX + syringeWidth / 2 + tickWidth / 2 + 4, y: y)
        }
    }

    private func syringeNeedle(centerX: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Needle tip
            Rectangle()
                .fill(Color(.systemGray3))
                .frame(width: 2, height: 20)

            // Hub
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(.systemGray4))
                .frame(width: 14, height: 8)
        }
        .position(x: centerX, y: 20 + barrelHeight + 18)
    }

    private func syringePlunger(centerX: CGFloat) -> some View {
        let clampedFill = min(max(fillFraction, 0), 1)
        let plungerY = 20 + barrelHeight * (1 - clampedFill)

        return VStack(spacing: 0) {
            // Plunger rod
            Rectangle()
                .fill(Color(.systemGray3))
                .frame(width: 4, height: max(plungerY - 10, 0))

            // Plunger top handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(.systemGray4))
                .frame(width: 30, height: 6)
        }
        .position(x: centerX, y: (plungerY - 10) / 2)
    }
}

#Preview {
    VStack(spacing: 30) {
        SyringeView(fillFraction: 0.25, units: 25)
            .frame(height: 200)
        SyringeView(fillFraction: 0.5, units: 50)
            .frame(height: 200)
    }
}
