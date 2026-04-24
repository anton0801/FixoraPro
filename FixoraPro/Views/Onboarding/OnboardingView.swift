import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0

    let pages = OnboardingPage.allPages

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            GridBackgroundView(animate: false)
                .opacity(0.15)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .font(FixoraFont.body(15))
                    .foregroundColor(Color.textInactive)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { idx, page in
                        OnboardingPageView(page: page, isActive: currentPage == idx)
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)

                // Dots + Next
                VStack(spacing: 28) {
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(i == currentPage ? Color.accentCyan : Color.divider)
                                .frame(width: i == currentPage ? 24 : 6, height: 6)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                        }
                    }

                    Button(currentPage < pages.count - 1 ? "Next" : "Get Started") {
                        if currentPage < pages.count - 1 {
                            withAnimation { currentPage += 1 }
                        } else {
                            completeOnboarding()
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 32)
                }
                .padding(.bottom, 48)
            }
        }
    }

    private func completeOnboarding() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            appState.hasCompletedOnboarding = true
        }
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let illustration: AnyView

    static let allPages: [OnboardingPage] = [
        OnboardingPage(
            title: "Map Your Cables",
            subtitle: "Draw precise cable routes on your floor plan. Know exactly where every wire runs behind your walls.",
            illustration: AnyView(OnboardingIllustration1())
        ),
        OnboardingPage(
            title: "Avoid Damage",
            subtitle: "Safety zones warn you before drilling. Never accidentally hit a live wire again.",
            illustration: AnyView(OnboardingIllustration2())
        ),
        OnboardingPage(
            title: "Keep Home Safe",
            subtitle: "Export your cable map as a report. Share it with electricians or keep for future renovations.",
            illustration: AnyView(OnboardingIllustration3())
        )
    ]
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    var isActive: Bool
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 40) {
            // Illustration
            page.illustration
                .frame(height: 280)
                .scaleEffect(appeared ? 1.0 : 0.85)
                .opacity(appeared ? 1.0 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.1), value: appeared)

            // Text
            VStack(spacing: 16) {
                Text(page.title)
                    .font(FixoraFont.display(30))
                    .foregroundColor(Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: appeared)

                Text(page.subtitle)
                    .font(FixoraFont.body(16))
                    .foregroundColor(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: appeared)
            }

            Spacer()
        }
        .padding(.top, 20)
        .onAppear {
            if isActive {
                appeared = true
            }
        }
        .onChange(of: isActive) { active in
            if active { appeared = true }
            else { appeared = false }
        }
    }
}

// MARK: - Illustrations
struct OnboardingIllustration1: View {
    @State private var draw = false
    @State private var pulseDot = false

    var body: some View {
        ZStack {
            // Room outline
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.wallOutline, lineWidth: 2)
                .frame(width: 260, height: 200)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.wallFill.opacity(0.5))
                )

            // Grid
            Canvas { ctx, size in
                let step: CGFloat = 20
                var x: CGFloat = 0
                while x <= size.width {
                    var p = Path()
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x, y: size.height))
                    ctx.stroke(p, with: .color(Color.gridLine.opacity(0.4)), lineWidth: 0.5)
                    x += step
                }
                var y: CGFloat = 0
                while y <= size.height {
                    var p = Path()
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: size.width, y: y))
                    ctx.stroke(p, with: .color(Color.gridLine.opacity(0.4)), lineWidth: 0.5)
                    y += step
                }
            }
            .frame(width: 240, height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Animated cable lines
            if draw {
                // Electric
                Path { p in
                    p.move(to: CGPoint(x: -110, y: -60))
                    p.addLine(to: CGPoint(x: 20, y: -60))
                    p.addLine(to: CGPoint(x: 20, y: 40))
                    p.addLine(to: CGPoint(x: 100, y: 40))
                }
                .trim(from: 0, to: draw ? 1 : 0)
                .stroke(Color.cableElectric, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .animation(.easeInOut(duration: 0.8).delay(0.2), value: draw)

                // Internet
                Path { p in
                    p.move(to: CGPoint(x: -110, y: 20))
                    p.addLine(to: CGPoint(x: 60, y: 20))
                    p.addLine(to: CGPoint(x: 60, y: 80))
                }
                .trim(from: 0, to: draw ? 1 : 0)
                .stroke(Color.cableInternet, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .animation(.easeInOut(duration: 0.8).delay(0.5), value: draw)
            }

            // Endpoint dots
            ForEach([
                (CGPoint(x: 100, y: 40), Color.cableElectric),
                (CGPoint(x: 60, y: 80), Color.cableInternet)
            ], id: \.0.x) { pt, color in
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                    .scaleEffect(pulseDot ? 1.3 : 1.0)
                    .position(x: pt.x + 130, y: pt.y + 100)
                    .opacity(draw ? 1 : 0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true).delay(0.8), value: pulseDot)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                draw = true
                pulseDot = true
            }
        }
    }
}

struct OnboardingIllustration2: View {
    @State private var showZone = false
    @State private var drillOffset: CGFloat = 0
    @State private var showWarning = false

    var body: some View {
        ZStack {
            if #available(iOS 17.0, *) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.wallFill.opacity(0.5))
                    .stroke(Color.wallOutline, lineWidth: 2)
                    .frame(width: 260, height: 200)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.wallFill.opacity(0.5))
                    .frame(width: 260, height: 200)
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.wallOutline, lineWidth: 2)
                    .frame(width: 260, height: 200)
            }

            // Safety zone
            if showZone {
                if #available(iOS 17.0, *) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.statusDanger.opacity(0.15))
                        .stroke(Color.statusDanger.opacity(0.6), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                        .frame(width: 120, height: 80)
                        .offset(x: 20, y: -10)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.statusDanger.opacity(0.15))
                        .frame(width: 120, height: 80)
                        .offset(x: 20, y: -10)
                        .transition(.scale.combined(with: .opacity))
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.statusDanger.opacity(0.6), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                        .frame(width: 120, height: 80)
                        .offset(x: 20, y: -10)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            // Warning icon
            if showWarning {
                VStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Color.statusDanger)
                        .cyanGlow(radius: 8)

                    Text("Danger Zone")
                        .font(FixoraFont.caption(11))
                        .foregroundColor(Color.statusDanger)
                }
                .offset(x: 20, y: -50)
                .transition(.scale.combined(with: .opacity))
            }

            // Cable in zone
            Path { p in
                p.move(to: CGPoint(x: -100, y: -10))
                p.addLine(to: CGPoint(x: 80, y: -10))
                p.addLine(to: CGPoint(x: 80, y: 30))
            }
            .stroke(Color.cableElectric, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

            // Drill
            Image(systemName: "screwdriver.fill")
                .font(.system(size: 32))
                .foregroundColor(Color.textSecondary)
                .rotationEffect(.degrees(45))
                .offset(x: drillOffset, y: -10)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
                showZone = true
            }
            withAnimation(.easeInOut(duration: 0.8).delay(0.6)) {
                drillOffset = 10
            }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(1.0)) {
                showWarning = true
            }
        }
    }
}

struct OnboardingIllustration3: View {
    @State private var progress: CGFloat = 0
    @State private var showCheck = false

    var body: some View {
        ZStack {
            // Report paper
            if #available(iOS 17.0, *) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBg)
                    .stroke(Color.divider, lineWidth: 1)
                    .frame(width: 220, height: 280)
                    .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBg)
                    .frame(width: 220, height: 280)
                    .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
                
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.divider, lineWidth: 1)
                    .frame(width: 220, height: 280)
                    .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
            }

            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(Color.accentCyan)
                    Text("Cable Report")
                        .font(FixoraFont.heading(15))
                        .foregroundColor(Color.textPrimary)
                    Spacer()
                    if showCheck {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(Color.statusSafe)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                Divider().background(Color.divider)

                // Lines
                ForEach(Array([
                    ("Electric", Color.cableElectric, 0.85),
                    ("Internet", Color.cableInternet, 0.60),
                    ("TV Cable", Color.cableTV, 0.40),
                    ("Signal", Color.cableSignal, 0.70)
                ].enumerated()), id: \.offset) { i, item in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Circle()
                                .fill(item.1)
                                .frame(width: 8, height: 8)
                            Text(item.0)
                                .font(FixoraFont.caption(12))
                                .foregroundColor(Color.textSecondary)
                            Spacer()
                            Text("\(Int(item.2 * 100))%")
                                .font(FixoraFont.mono(11))
                                .foregroundColor(item.1)
                        }
                        GeometryReader { g in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.divider)
                                .frame(height: 4)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(item.1)
                                .frame(width: g.size.width * progress * item.2, height: 4)
                                .animation(.easeInOut(duration: 0.8).delay(Double(i) * 0.15), value: progress)
                        }
                        .frame(height: 4)
                    }
                }
            }
            .padding(20)
            .frame(width: 220)
        }
        .onAppear {
            withAnimation { progress = 1.0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    showCheck = true
                }
            }
        }
    }
}
