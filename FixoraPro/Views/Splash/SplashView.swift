import SwiftUI

struct SplashView: View {
    var onComplete: () -> Void

    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var lineProgress: CGFloat = 0
    @State private var taglineOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            // Animated grid background
            GridBackgroundView(animate: lineProgress > 0.3)
                .opacity(0.3)

            VStack(spacing: 32) {
                Spacer()

                // Logo area
                ZStack {
                    // Glow ring
                    Circle()
                        .fill(Color.accentCyan.opacity(0.08 * glowOpacity))
                        .frame(width: 160, height: 160)
                        .scaleEffect(pulseScale)

                    Circle()
                        .stroke(Color.accentCyan.opacity(0.15 * glowOpacity), lineWidth: 1)
                        .frame(width: 130, height: 130)

                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(
                                LinearGradient(
                                    colors: [Color.cardBg2, Color.bgSoft],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 96, height: 96)
                            .overlay(
                                RoundedRectangle(cornerRadius: 28)
                                    .stroke(Color.accentCyan.opacity(0.4), lineWidth: 1.5)
                            )

                        CableIconView(progress: lineProgress)
                            .frame(width: 56, height: 56)
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                }

                // App name
                VStack(spacing: 6) {
                    HStack(spacing: 0) {
                        Text("Fixora")
                            .font(FixoraFont.display(34))
                            .foregroundColor(Color.textPrimary)
                        Text(" Pro")
                            .font(FixoraFont.display(34))
                            .foregroundColor(Color.accentCyan)
                            .cyanGlow(radius: 10)
                    }

                    Text("Know what's inside your walls")
                        .font(FixoraFont.body(14))
                        .foregroundColor(Color.textInactive)
                        .tracking(0.5)
                }
                .opacity(taglineOpacity)
                .scaleEffect(logoScale)

                Spacer()

                // Loading indicator
                HStack(spacing: 6) {
                    ForEach(0..<3) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.accentCyan)
                            .frame(width: lineProgress > Double(i) * 0.3 + 0.1 ? 24 : 6, height: 4)
                            .opacity(lineProgress > Double(i) * 0.3 + 0.1 ? 1 : 0.3)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(i) * 0.15), value: lineProgress)
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            animateSplash()
        }
    }

    private func animateSplash() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }

        withAnimation(.easeInOut(duration: 1.2).delay(0.3)) {
            lineProgress = 1.0
        }

        withAnimation(.easeIn(duration: 0.5).delay(0.5)) {
            glowOpacity = 1.0
            taglineOpacity = 1.0
        }

        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.8)) {
            pulseScale = 1.15
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.easeInOut(duration: 0.4)) {
                onComplete()
            }
        }
    }
}

struct CableIconView: View {
    var progress: CGFloat

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            // Draw cable lines
            let paths: [(Color, [(CGFloat, CGFloat)])] = [
                (.cableElectric, [(0.1, 0.2), (0.5, 0.2), (0.5, 0.6), (0.9, 0.6)]),
                (.cableInternet, [(0.1, 0.5), (0.4, 0.5), (0.4, 0.85), (0.9, 0.85)]),
                (.accentCyan, [(0.1, 0.8), (0.3, 0.8), (0.3, 0.35), (0.9, 0.35)])
            ]

            for (color, pts) in paths {
                var path = Path()
                path.move(to: CGPoint(x: pts[0].0 * w, y: pts[0].1 * h))
                for i in 1..<pts.count {
                    let prev = pts[i-1]
                    let curr = pts[i]
                    if prev.0 != curr.0 {
                        path.addLine(to: CGPoint(x: curr.0 * w, y: prev.1 * h))
                    }
                    path.addLine(to: CGPoint(x: curr.0 * w, y: curr.1 * h))
                }

                context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                // Endpoint dot
                if let last = pts.last {
                    let dotRect = CGRect(x: last.0 * w - 4, y: last.1 * h - 4, width: 8, height: 8)
                    context.fill(Path(ellipseIn: dotRect), with: .color(color))
                }
            }
        }
        .opacity(Double(progress))
    }
}

struct GridBackgroundView: View {
    var animate: Bool

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let step: CGFloat = 30
                var x: CGFloat = 0
                while x <= size.width {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    context.stroke(path, with: .color(Color.gridLine.opacity(0.5)), lineWidth: 0.5)
                    x += step
                }
                var y: CGFloat = 0
                while y <= size.height {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(path, with: .color(Color.gridLine.opacity(0.5)), lineWidth: 0.5)
                    y += step
                }
            }
        }
    }
}
