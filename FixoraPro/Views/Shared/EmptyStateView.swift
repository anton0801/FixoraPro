import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.accentCyan.opacity(0.15), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                Circle()
                    .strokeBorder(Color.accentCyan.opacity(0.25), lineWidth: 1)
                    .frame(width: 100, height: 100)

                Image(systemName: icon)
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(Color.accentCyan.opacity(0.7))
                    .scaleEffect(appeared ? 1 : 0.5)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.1), value: appeared)
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(FixoraFont.title3)
                    .foregroundColor(Color.textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2), value: appeared)

                Text(subtitle)
                    .font(FixoraFont.body(14))
                    .foregroundColor(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: appeared)
            }
            .padding(.horizontal, 32)

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text(actionTitle)
                    }
                    .font(FixoraFont.bodyMedium(14))
                    .foregroundColor(Color.bgPrimary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentCyan, Color.accentCyan.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .cyanGlow()
                }
                .scaleEffect(appeared ? 1 : 0.8)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.4), value: appeared)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            appeared = true
        }
        .onDisappear {
            appeared = false
        }
    }
}
