import SwiftUI
import SwiftData

struct BodyMapView: View {
    @Binding var selectedSite: InjectionSite
    let injections: [Injection]
    @State private var showingSiteInfo: InjectionSite?

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Simplified body silhouette
                BodySilhouette()
                    .fill(.quaternary)
                    .frame(height: 280)

                // Site dots
                GeometryReader { geo in
                    ForEach(InjectionSite.allCases, id: \.self) { site in
                        let pos = bodyPosition(for: site)
                        let lastDate = lastInjectionDate(for: site)
                        let color = siteColor(lastUsed: lastDate)
                        let isSelected = selectedSite == site

                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedSite = site
                                showingSiteInfo = site
                            }
                        } label: {
                            Circle()
                                .fill(color.opacity(isSelected ? 1 : 0.7))
                                .frame(width: isSelected ? 32 : 24, height: isSelected ? 32 : 24)
                                .overlay {
                                    Circle()
                                        .strokeBorder(.white, lineWidth: isSelected ? 3 : 1)
                                }
                                .shadow(color: color.opacity(0.5), radius: isSelected ? 6 : 2)
                        }
                        .position(
                            x: pos.x * geo.size.width,
                            y: pos.y * geo.size.height
                        )
                    }
                }
                .frame(height: 280)
            }

            // Selected site info
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(siteColor(lastUsed: lastInjectionDate(for: selectedSite)))
                Text(selectedSite.displayName)
                    .fontWeight(.medium)
                Spacer()
                if let lastDate = lastInjectionDate(for: selectedSite) {
                    Text("Last: \(lastDate, style: .relative) ago")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Never used")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))

            // Legend
            HStack(spacing: 16) {
                LegendDot(color: .green, label: ">2 weeks")
                LegendDot(color: .yellow, label: "1-2 weeks")
                LegendDot(color: .red, label: "<1 week")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    private func lastInjectionDate(for site: InjectionSite) -> Date? {
        injections
            .filter { $0.injectionSite == site }
            .map(\.date)
            .max()
    }

    private func siteColor(lastUsed: Date?) -> Color {
        guard let lastUsed else { return .green }
        let days = Calendar.current.dateComponents([.day], from: lastUsed, to: .now).day ?? 0
        if days > 14 { return .green }
        if days >= 7 { return .yellow }
        return .red
    }

    private func bodyPosition(for site: InjectionSite) -> CGPoint {
        switch site {
        case .leftAbdomen:  return CGPoint(x: 0.58, y: 0.42)
        case .rightAbdomen: return CGPoint(x: 0.42, y: 0.42)
        case .leftThigh:    return CGPoint(x: 0.58, y: 0.65)
        case .rightThigh:   return CGPoint(x: 0.42, y: 0.65)
        case .leftArm:      return CGPoint(x: 0.78, y: 0.30)
        case .rightArm:     return CGPoint(x: 0.22, y: 0.30)
        }
    }
}

struct LegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
        }
    }
}

/// A simplified human body front-view silhouette
struct BodySilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let cx = w * 0.5

        // Head
        path.addEllipse(in: CGRect(x: cx - w * 0.07, y: h * 0.02, width: w * 0.14, height: h * 0.1))

        // Neck
        path.addRect(CGRect(x: cx - w * 0.03, y: h * 0.11, width: w * 0.06, height: h * 0.03))

        // Torso
        path.move(to: CGPoint(x: cx - w * 0.15, y: h * 0.14))
        path.addLine(to: CGPoint(x: cx - w * 0.18, y: h * 0.22))
        path.addLine(to: CGPoint(x: cx - w * 0.14, y: h * 0.52))
        path.addLine(to: CGPoint(x: cx - w * 0.10, y: h * 0.54))
        path.addLine(to: CGPoint(x: cx + w * 0.10, y: h * 0.54))
        path.addLine(to: CGPoint(x: cx + w * 0.14, y: h * 0.52))
        path.addLine(to: CGPoint(x: cx + w * 0.18, y: h * 0.22))
        path.addLine(to: CGPoint(x: cx + w * 0.15, y: h * 0.14))
        path.closeSubpath()

        // Left arm
        path.move(to: CGPoint(x: cx + w * 0.18, y: h * 0.22))
        path.addLine(to: CGPoint(x: cx + w * 0.30, y: h * 0.26))
        path.addLine(to: CGPoint(x: cx + w * 0.32, y: h * 0.42))
        path.addLine(to: CGPoint(x: cx + w * 0.27, y: h * 0.42))
        path.addLine(to: CGPoint(x: cx + w * 0.25, y: h * 0.28))
        path.addLine(to: CGPoint(x: cx + w * 0.16, y: h * 0.25))
        path.closeSubpath()

        // Right arm
        path.move(to: CGPoint(x: cx - w * 0.18, y: h * 0.22))
        path.addLine(to: CGPoint(x: cx - w * 0.30, y: h * 0.26))
        path.addLine(to: CGPoint(x: cx - w * 0.32, y: h * 0.42))
        path.addLine(to: CGPoint(x: cx - w * 0.27, y: h * 0.42))
        path.addLine(to: CGPoint(x: cx - w * 0.25, y: h * 0.28))
        path.addLine(to: CGPoint(x: cx - w * 0.16, y: h * 0.25))
        path.closeSubpath()

        // Left leg
        path.move(to: CGPoint(x: cx + w * 0.02, y: h * 0.54))
        path.addLine(to: CGPoint(x: cx + w * 0.12, y: h * 0.54))
        path.addLine(to: CGPoint(x: cx + w * 0.13, y: h * 0.82))
        path.addLine(to: CGPoint(x: cx + w * 0.15, y: h * 0.95))
        path.addLine(to: CGPoint(x: cx + w * 0.05, y: h * 0.95))
        path.addLine(to: CGPoint(x: cx + w * 0.04, y: h * 0.82))
        path.closeSubpath()

        // Right leg
        path.move(to: CGPoint(x: cx - w * 0.02, y: h * 0.54))
        path.addLine(to: CGPoint(x: cx - w * 0.12, y: h * 0.54))
        path.addLine(to: CGPoint(x: cx - w * 0.13, y: h * 0.82))
        path.addLine(to: CGPoint(x: cx - w * 0.15, y: h * 0.95))
        path.addLine(to: CGPoint(x: cx - w * 0.05, y: h * 0.95))
        path.addLine(to: CGPoint(x: cx - w * 0.04, y: h * 0.82))
        path.closeSubpath()

        return path
    }
}
