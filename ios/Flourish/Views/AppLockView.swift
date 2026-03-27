import SwiftUI
import LocalAuthentication

struct AppLockView: View {
    @Binding var isUnlocked: Bool
    @State private var authFailed: Bool = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var flowerRotation: Double = 0
    @State private var shimmer: Bool = false

    var body: some View {
        ZStack {
            Theme.beige.ignoresSafeArea()
            BackgroundFlowerScatter(seed: 7)

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Theme.roseMist.opacity(0.3), Theme.lavenderLight.opacity(0.15), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 120
                            )
                        )
                        .frame(width: 240, height: 240)
                        .scaleEffect(pulseScale)

                    ForEach(0..<6, id: \.self) { i in
                        FloatingFlower(
                            size: i.isMultiple(of: 2) ? 26 : 20,
                            color: [Theme.softPink, Theme.lavenderMist, Theme.roseGold, Theme.gold, Theme.roseMist, Theme.lavenderLight][i],
                            rotation: Double(i) * 30,
                            opacity: 0.55
                        )
                        .offset(y: -80)
                        .rotationEffect(.degrees(Double(i) * 60 + flowerRotation))
                    }

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.rose.opacity(0.12), Theme.lavender.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)

                    Image(systemName: "lock.fill")
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.rose, Theme.dustyRose],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Theme.rose.opacity(0.3), radius: 8, y: 2)
                }

                Spacer().frame(height: 36)

                VStack(spacing: 10) {
                    Text("Flourish")
                        .font(Theme.largeTitleFont)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.rose, Theme.dustyRose],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("Authenticate to continue")
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.deep.opacity(0.45))
                }

                if authFailed {
                    Text("Authentication failed. Try again.")
                        .font(Theme.font(14))
                        .foregroundStyle(Theme.rose)
                        .padding(.top, 16)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }

                Spacer()

                Button {
                    authenticate()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "faceid")
                            .font(.system(size: 20))
                        Text("Unlock")
                            .font(Theme.fontBold(17))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [Theme.rose, Theme.dustyRose],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(.rect(cornerRadius: 16))
                    .shadow(color: Theme.rose.opacity(0.3), radius: 12, y: 6)
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.08
            }
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                flowerRotation = 360
            }
            authenticate()
        }
    }

    private func authenticate() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock Flourish") { success, _ in
                DispatchQueue.main.async {
                    if success {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isUnlocked = true
                        }
                    } else {
                        withAnimation { authFailed = true }
                    }
                }
            }
        } else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Unlock Flourish") { success, _ in
                DispatchQueue.main.async {
                    if success {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isUnlocked = true
                        }
                    } else {
                        withAnimation { authFailed = true }
                    }
                }
            }
        } else {
            isUnlocked = true
        }
    }
}
