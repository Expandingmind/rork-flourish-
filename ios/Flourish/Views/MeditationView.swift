import SwiftUI

struct MeditationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isBreathing: Bool = false
    @State private var breathPhase: BreathPhase = .ready
    @State private var circleScale: CGFloat = 0.6
    @State private var elapsedSeconds: Int = 0
    @State private var timerActive: Bool = false
    @State private var sessionComplete: Bool = false
    @State private var showCelebration: Bool = false

    private let totalDuration: Int = 120

    enum BreathPhase: String {
        case ready = "Ready when you are"
        case breatheIn = "Breathe in"
        case hold = "Hold"
        case breatheOut = "Let it go"
        case complete = "You're centered."
    }

    var body: some View {
        ZStack {
            Theme.pageBg

            VStack(spacing: 40) {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(Theme.title2Font)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                ZStack {
                    Circle()
                        .fill(Theme.softLavender.opacity(0.15))
                        .frame(width: 260, height: 260)
                    Circle()
                        .fill(Theme.sage.opacity(0.15))
                        .frame(width: 200, height: 200)
                        .scaleEffect(circleScale)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Theme.sage.opacity(0.4), Theme.sage.opacity(0.15)],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 140, height: 140)
                        .scaleEffect(circleScale)
                }

                VStack(spacing: 12) {
                    Text(breathPhase.rawValue)
                        .font(Theme.title2Font)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.deep)
                        .animation(.easeInOut(duration: 0.3), value: breathPhase)

                    if timerActive {
                        Text(timeString)
                            .font(Theme.subheadlineFont)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }

                Spacer()

                if sessionComplete {
                    VStack(spacing: 16) {
                        Text("Session complete.")
                            .font(Theme.headlineFont)
                            .foregroundStyle(Theme.sage)
                        Text("You showed up for yourself. That's evidence.")
                            .font(Theme.subheadlineFont)
                            .foregroundStyle(.secondary)
                        Button {
                            dismiss()
                        } label: {
                            Text("Return")
                                .font(Theme.bodyFont)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 40)
                                .padding(.vertical, 14)
                                .background(Theme.sage, in: Capsule())
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else if !isBreathing {
                    Button {
                        startSession()
                    } label: {
                        Text("Begin")
                            .font(Theme.bodyFont)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 48)
                            .padding(.vertical, 14)
                            .background(Theme.sage, in: Capsule())
                    }
                } else {
                    Button {
                        stopSession()
                    } label: {
                        Text("End early")
                            .font(Theme.subheadlineFont)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
                    .frame(height: 40)
            }
        }
        .celebration(
            isShowing: $showCelebration,
            message: "You showed up.",
            subtitle: "Stillness is a power move.",
            style: .zen,
            duration: 3.0
        )
    }

    private var timeString: String {
        let remaining = max(totalDuration - elapsedSeconds, 0)
        let mins = remaining / 60
        let secs = remaining % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func startSession() {
        isBreathing = true
        timerActive = true
        elapsedSeconds = 0
        runBreathCycle()
        runTimer()
    }

    private func stopSession() {
        isBreathing = false
        timerActive = false
        withAnimation(.easeInOut(duration: 0.5)) {
            sessionComplete = true
            breathPhase = .complete
            circleScale = 0.6
        }
        showCelebration = true
    }

    private func runTimer() {
        Task {
            while timerActive && elapsedSeconds < totalDuration {
                try? await Task.sleep(for: .seconds(1))
                guard timerActive else { return }
                elapsedSeconds += 1
                if elapsedSeconds >= totalDuration {
                    stopSession()
                }
            }
        }
    }

    private func runBreathCycle() {
        Task {
            while isBreathing {
                withAnimation(.easeInOut(duration: 4)) {
                    breathPhase = .breatheIn
                    circleScale = 1.0
                }
                try? await Task.sleep(for: .seconds(4))
                guard isBreathing else { return }

                withAnimation(.easeInOut(duration: 2)) {
                    breathPhase = .hold
                }
                try? await Task.sleep(for: .seconds(2))
                guard isBreathing else { return }

                withAnimation(.easeInOut(duration: 4)) {
                    breathPhase = .breatheOut
                    circleScale = 0.6
                }
                try? await Task.sleep(for: .seconds(4))
                guard isBreathing else { return }
            }
        }
    }
}
