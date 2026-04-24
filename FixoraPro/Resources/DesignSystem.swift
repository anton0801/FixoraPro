import SwiftUI

// MARK: - Color Palette
extension Color {
    // Backgrounds
    static let bgPrimary = Color(hex: "#020617")
    static let bgMain = Color(hex: "#0B1220")
    static let bgSoft = Color(hex: "#0F172A")
    static let cardBg = Color(hex: "#111827")
    static let cardBg2 = Color(hex: "#1E293B")
    static let divider = Color(hex: "#334155")

    // Accent - Cable Blue
    static let accentCyan = Color(hex: "#22D3EE")
    static let accentCyanActive = Color(hex: "#06B6D4")
    static let accentCyanLight = Color(hex: "#67E8F9")

    // Secondary Accent - Purple
    static let accentPurple = Color(hex: "#6366F1")
    static let accentPurpleSoft = Color(hex: "#818CF8")
    static let accentPurpleLight = Color(hex: "#A78BFA")

    // Status
    static let statusSafe = Color(hex: "#22C55E")
    static let statusWarning = Color(hex: "#FACC15")
    static let statusDanger = Color(hex: "#EF4444")

    // Cable Types
    static let cableElectric = Color(hex: "#FACC15")
    static let cableInternet = Color(hex: "#22D3EE")
    static let cableTV = Color(hex: "#A78BFA")
    static let cableSignal = Color(hex: "#3B82F6")

    // Wall/Plan
    static let wallFill = Color(hex: "#1E293B")
    static let wallOutline = Color(hex: "#475569")
    static let gridLine = Color(hex: "#334155")

    // Points
    static let pointActive = Color(hex: "#FACC15")
    static let pointNormal = Color(hex: "#CBD5E1")

    // Text
    static let textPrimary = Color(hex: "#F8FAFC")
    static let textSecondary = Color(hex: "#CBD5E1")
    static let textInactive = Color(hex: "#64748B")

    // Buttons
    static let btnPrimaryBg = Color(hex: "#22D3EE")
    static let btnPrimaryText = Color(hex: "#020617")
    static let btnSecondaryBg = Color(hex: "#1E293B")
    static let btnSecondaryText = Color(hex: "#E2E8F0")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography
struct FixoraFont {
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }
    static func heading(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func subheading(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    static func body(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
    static func bodyMedium(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
    static func mono(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .monospaced)
    }
    static func caption(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
    static var title3 = Font.system(size: 16, weight: .bold, design: .rounded)
}

// MARK: - Glow Effect
extension View {
    func cyanGlow(radius: CGFloat = 8) -> some View {
        self.shadow(color: Color.accentCyan.opacity(0.4), radius: radius, x: 0, y: 0)
    }

    func purpleGlow(radius: CGFloat = 8) -> some View {
        self.shadow(color: Color.accentPurple.opacity(0.3), radius: radius, x: 0, y: 0)
    }

    func darkShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.7), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FixoraFont.subheading(16))
            .foregroundColor(Color.btnPrimaryText)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(
                    colors: [Color.accentCyan, Color.accentCyanActive],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .cyanGlow(radius: configuration.isPressed ? 4 : 10)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FixoraFont.subheading(16))
            .foregroundColor(Color.btnSecondaryText)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.btnSecondaryBg)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.divider, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Card Modifier
struct CardModifier: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.cardBg)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.divider.opacity(0.5), lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle(padding: CGFloat = 16) -> some View {
        modifier(CardModifier(padding: padding))
    }
}

// MARK: - Custom TextField Style
struct FixoraTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .font(FixoraFont.body(15))
            .foregroundColor(Color.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.cardBg2)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.divider, lineWidth: 1)
            )
    }
}
