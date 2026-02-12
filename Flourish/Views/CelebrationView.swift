import SwiftUI

struct ConfettiPiece: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let size: CGFloat
    let color: Color
    let rotation: Double
    let rotationSpeed: Double
    let xVelocity: CGFloat
    var yVelocity: CGFloat
    let shape: ConfettiShape
    let opacity: Double
    let delay: Double

    enum ConfettiShape: CaseIterable {
        case circle, rectangle, star, diamond, triangle, ring
    }
}

struct FireworkParticle: Identifiable {
    let id = UUID()
    let originX: CGFloat
    let originY: CGFloat
    let angle: Double
    let speed: CGFloat
    let color: Color
    let size: CGFloat
    let delay: Double
}

struct RippleRing: Identifiable {
    let id = UUID()
    let color: Color
    let delay: Double
    let maxScale: CGFloat
    let lineWidth: CGFloat
    let originX: CGFloat
    let originY: CGFloat
}

struct ShimmerDot: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let color: Color
    let delay: Double
    let pulseSpeed: Double
}

struct CelebrationOverlay: View {
    let isShowing: Bool
    let message: String
    let subtitle: String
    let style: CelebrationStyle

    enum CelebrationStyle {
        case confetti
        case sparkle
        case gold
        case zen

        var colors: [Color] {
            switch self {
            case .confetti:
                return [Theme.accent, Theme.gold, Theme.softLavender, Theme.sage, Theme.dustyRose, Theme.softPink, Theme.blush, .white, Color(red: 1.0, green: 0.84, blue: 0.0)]
            case .sparkle:
                return [Theme.softLavender, Theme.lavenderMist, .white, Theme.accent, Theme.softPink, Color(red: 0.85, green: 0.75, blue: 1.0)]
            case .gold:
                return [Theme.gold, Theme.goldMist, Color(red: 0.85, green: 0.72, blue: 0.35), .white, Theme.accent, Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 0.95, green: 0.78, blue: 0.2)]
            case .zen:
                return [Theme.sage, Color(red: 0.65, green: 0.72, blue: 0.60), .white, Theme.lavenderMist, Theme.softLavender]
            }
        }

        var sfSymbol: String {
            switch self {
            case .confetti: return "sparkles"
            case .sparkle: return "star.fill"
            case .gold: return "crown.fill"
            case .zen: return "leaf.fill"
            }
        }

        var iconGradient: [Color] {
            switch self {
            case .confetti: return [Theme.gold, Theme.accent]
            case .sparkle: return [Theme.softLavender, Theme.accent]
            case .gold: return [Color(red: 1.0, green: 0.84, blue: 0.0), Theme.gold]
            case .zen: return [Theme.sage, Color(red: 0.65, green: 0.72, blue: 0.60)]
            }
        }
    }

    @State private var pieces: [ConfettiPiece] = []
    @State private var fireworks: [FireworkParticle] = []
    @State private var rippleRings: [RippleRing] = []
    @State private var shimmerDots: [ShimmerDot] = []
    @State private var showMessage: Bool = false
    @State private var messageScale: CGFloat = 0.1
    @State private var messageOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var flashOpacity: Double = 0
    @State private var startTime: Date = .now
    @State private var iconBounce: CGFloat = 0
    @State private var iconRotation: Double = 0
    @State private var ringScale: CGFloat = 0
    @State private var ringOpacity: Double = 0
    @State private var secondRingScale: CGFloat = 0
    @State private var secondRingOpacity: Double = 0
    @State private var thirdRingScale: CGFloat = 0
    @State private var thirdRingOpacity: Double = 0
    @State private var outerGlowScale: CGFloat = 0.8
    @State private var outerGlowOpacity: Double = 0
    @State private var secondBurstFired: Bool = false
    @State private var thirdBurstFired: Bool = false

    var body: some View {
        ZStack {
            if isShowing {
                Color.white.opacity(flashOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)

                Color.black.opacity(0.12)
                    .ignoresSafeArea()
                    .transition(.opacity)

                TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                    Canvas { context, size in
                        let elapsed = timeline.date.timeIntervalSince(startTime)

                        for piece in pieces {
                            let t = elapsed - piece.delay
                            guard t > 0 else { continue }
                            let gravity: CGFloat = 80
                            let currentY = piece.y + piece.yVelocity * t + gravity * t * t
                            let wobble = sin(t * 4 + Double(piece.x)) * 20
                            let currentX = piece.x + piece.xVelocity * t + wobble
                            let currentRotation = piece.rotation + piece.rotationSpeed * t
                            let fadeStart = 2.5
                            let alpha = t > fadeStart ? max(0, piece.opacity - (t - fadeStart) * 0.4) : piece.opacity

                            guard alpha > 0, currentY < size.height + 50 else { continue }

                            var transform = context
                            transform.translateBy(x: currentX, y: currentY)
                            transform.rotate(by: .degrees(currentRotation))
                            transform.opacity = alpha

                            let s = piece.size
                            switch piece.shape {
                            case .circle:
                                let rect = CGRect(x: -s / 2, y: -s / 2, width: s, height: s)
                                transform.fill(Circle().path(in: rect), with: .color(piece.color))
                            case .rectangle:
                                let rect = CGRect(x: -s / 2, y: -s / 4, width: s, height: s / 2)
                                transform.fill(Rectangle().path(in: rect), with: .color(piece.color))
                            case .star:
                                let rect = CGRect(x: -s / 2, y: -s / 2, width: s, height: s)
                                transform.fill(starPath(in: rect), with: .color(piece.color))
                            case .diamond:
                                let rect = CGRect(x: -s / 2, y: -s / 2, width: s, height: s)
                                transform.fill(diamondPath(in: rect), with: .color(piece.color))
                            case .triangle:
                                let rect = CGRect(x: -s / 2, y: -s / 2, width: s, height: s)
                                transform.fill(trianglePath(in: rect), with: .color(piece.color))
                            case .ring:
                                let rect = CGRect(x: -s / 2, y: -s / 2, width: s, height: s)
                                transform.stroke(Circle().path(in: rect), with: .color(piece.color), lineWidth: 2)
                            }
                        }

                        for particle in fireworks {
                            let t = elapsed - particle.delay
                            guard t > 0 else { continue }
                            let dx = cos(particle.angle) * Double(particle.speed) * t
                            let dy = sin(particle.angle) * Double(particle.speed) * t + 60 * t * t
                            let px = particle.originX + dx
                            let py = particle.originY + dy
                            let alpha = max(0, 1.0 - t * 0.7)
                            guard alpha > 0 else { continue }

                            var transform = context
                            transform.translateBy(x: px, y: py)
                            transform.opacity = alpha

                            let trailLength = min(t * 30, 12)
                            let trailRect = CGRect(x: -1.5, y: -trailLength / 2, width: 3, height: trailLength)
                            transform.fill(Capsule().path(in: trailRect), with: .color(particle.color))

                            let glowRect = CGRect(x: -particle.size, y: -particle.size, width: particle.size * 2, height: particle.size * 2)
                            transform.opacity = alpha * 0.4
                            transform.fill(Circle().path(in: glowRect), with: .color(particle.color))
                        }

                        for ring in rippleRings {
                            let t = elapsed - ring.delay
                            guard t > 0 && t < 1.8 else { continue }
                            let progress = t / 1.8
                            let scale = 0.2 + progress * Double(ring.maxScale)
                            let alpha = progress < 0.3 ? progress / 0.3 : max(0, 1.0 - (progress - 0.3) / 0.7)
                            let ringSize = 60.0 * scale
                            let rect = CGRect(
                                x: ring.originX - ringSize / 2,
                                y: ring.originY - ringSize / 2,
                                width: ringSize,
                                height: ringSize
                            )
                            var transform = context
                            transform.opacity = alpha * 0.6
                            transform.stroke(Circle().path(in: rect), with: .color(ring.color), lineWidth: ring.lineWidth * (1.0 - progress * 0.5))
                        }

                        for dot in shimmerDots {
                            let t = elapsed - dot.delay
                            guard t > 0 else { continue }
                            let pulse = sin(t * dot.pulseSpeed) * 0.5 + 0.5
                            let fadeIn = min(t / 0.3, 1.0)
                            let fadeOut = t > 2.5 ? max(0, 1.0 - (t - 2.5) * 0.8) : 1.0
                            let alpha = fadeIn * fadeOut * pulse
                            guard alpha > 0 else { continue }

                            var transform = context
                            transform.translateBy(x: dot.x, y: dot.y)
                            transform.opacity = alpha

                            let s = dot.size * (0.6 + pulse * 0.4)
                            let rect = CGRect(x: -s / 2, y: -s / 2, width: s, height: s)
                            transform.fill(Circle().path(in: rect), with: .color(dot.color))

                            let glowS = s * 2.5
                            let glowRect = CGRect(x: -glowS / 2, y: -glowS / 2, width: glowS, height: glowS)
                            transform.opacity = alpha * 0.2
                            transform.fill(Circle().path(in: glowRect), with: .color(dot.color))
                        }
                    }
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
                    .onChange(of: timeline.date) { _, newDate in
                        let elapsed = newDate.timeIntervalSince(startTime)
                        if elapsed > 0.4 && !secondBurstFired {
                            secondBurstFired = true
                            addConfettiBurst(delay: 0, count: 50)
                            triggerBurstHaptic()
                        }
                        if elapsed > 0.9 && !thirdBurstFired {
                            thirdBurstFired = true
                            addConfettiBurst(delay: 0, count: 35)
                            addFireworkBurst(delay: 0)
                        }
                    }
                }

                if showMessage {
                    ZStack {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: style.iconGradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 200, height: 200)
                            .scaleEffect(ringScale)
                            .opacity(ringOpacity)

                        Circle()
                            .stroke(
                                (style.colors.first ?? Theme.accent).opacity(0.4),
                                lineWidth: 2
                            )
                            .frame(width: 200, height: 200)
                            .scaleEffect(secondRingScale)
                            .opacity(secondRingOpacity)

                        Circle()
                            .stroke(
                                (style.colors.last ?? Theme.blush).opacity(0.25),
                                lineWidth: 1.5
                            )
                            .frame(width: 200, height: 200)
                            .scaleEffect(thirdRingScale)
                            .opacity(thirdRingOpacity)

                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        (style.colors.first ?? Theme.accent).opacity(0.12),
                                        .clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 140
                                )
                            )
                            .frame(width: 280, height: 280)
                            .scaleEffect(outerGlowScale)
                            .opacity(outerGlowOpacity)

                        VStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: style.iconGradient.map { $0.opacity(0.15) },
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 72, height: 72)

                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: style.iconGradient.map { $0.opacity(0.3) },
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                                    .frame(width: 72, height: 72)

                                Image(systemName: style.sfSymbol)
                                    .font(Theme.font(30))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: style.iconGradient,
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .rotationEffect(.degrees(iconRotation))
                            }
                            .scaleEffect(1.0 + iconBounce * 0.15)

                            Text(message)
                                .font(Theme.title2Font)
                                .fontWeight(.heavy)
                                .foregroundStyle(Theme.deep)
                                .multilineTextAlignment(.center)

                            Text(subtitle)
                                .font(Theme.subheadlineFont)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 36)
                        .padding(.vertical, 28)
                        .background {
                            RoundedRectangle(cornerRadius: 28)
                                .fill(Theme.warmCream)
                                .shadow(color: (style.colors.first ?? Theme.accent).opacity(glowOpacity * 0.4), radius: 40, y: 0)
                                .shadow(color: .black.opacity(0.12), radius: 24, y: 10)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 28)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    (style.colors.first ?? Theme.accent).opacity(0.2),
                                                    .clear,
                                                    (style.colors.last ?? Theme.blush).opacity(0.15),
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                }
                        }
                        .scaleEffect(messageScale)
                        .opacity(messageOpacity)
                    }
                    .transition(.identity)
                }
            }
        }
        .onChange(of: isShowing) { _, newValue in
            if newValue {
                triggerCelebration()
            } else {
                resetState()
            }
        }
    }

    private func triggerCelebration() {
        startTime = .now
        secondBurstFired = false
        thirdBurstFired = false

        generateInitialBurst()
        generateFireworks()
        generateRippleRings()
        generateShimmerDots()
        triggerHapticSequence()

        withAnimation(.easeOut(duration: 0.08)) {
            flashOpacity = 0.6
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.easeOut(duration: 0.25)) {
                flashOpacity = 0
            }
        }

        withAnimation(.spring(response: 0.45, dampingFraction: 0.5, blendDuration: 0)) {
            showMessage = true
            messageScale = 1.0
            messageOpacity = 1.0
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.4).delay(0.1)) {
            ringScale = 2.5
        }
        withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
            ringOpacity = 0.7
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            ringOpacity = 0
        }

        withAnimation(.spring(response: 0.7, dampingFraction: 0.35).delay(0.25)) {
            secondRingScale = 3.0
        }
        withAnimation(.easeOut(duration: 0.3).delay(0.25)) {
            secondRingOpacity = 0.5
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
            secondRingOpacity = 0
        }

        withAnimation(.spring(response: 0.8, dampingFraction: 0.3).delay(0.4)) {
            thirdRingScale = 3.5
        }
        withAnimation(.easeOut(duration: 0.3).delay(0.4)) {
            thirdRingOpacity = 0.4
        }
        withAnimation(.easeOut(duration: 0.6).delay(0.85)) {
            thirdRingOpacity = 0
        }

        withAnimation(.easeOut(duration: 0.6).delay(0.15)) {
            outerGlowScale = 1.6
            outerGlowOpacity = 0.8
        }
        withAnimation(.easeOut(duration: 0.8).delay(1.0)) {
            outerGlowOpacity = 0
        }

        withAnimation(.easeInOut(duration: 0.8).repeatCount(4, autoreverses: true)) {
            glowOpacity = 1.0
        }

        animateIconBounce()
    }

    private func animateIconBounce() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.3).delay(0.2)) {
            iconBounce = 1.0
            iconRotation = -8
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.3)) {
                iconBounce = 0.7
                iconRotation = 8
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.3)) {
                iconBounce = 1.0
                iconRotation = -4
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                iconBounce = 0
                iconRotation = 0
            }
        }
    }

    private func generateInitialBurst() {
        let colors = style.colors
        let screenWidth = UIScreen.main.bounds.width

        pieces = (0..<120).map { i in
            let burstAngle = Double.random(in: -.pi ..< .pi)
            let burstSpeed = CGFloat.random(in: 60...220)
            return ConfettiPiece(
                x: screenWidth / 2 + CGFloat.random(in: -40...40),
                y: CGFloat.random(in: -60 ... -10),
                size: CGFloat.random(in: 4...14),
                color: colors.randomElement() ?? Theme.accent,
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -500...500),
                xVelocity: cos(burstAngle) * burstSpeed,
                yVelocity: CGFloat.random(in: 30...160),
                shape: ConfettiPiece.ConfettiShape.allCases.randomElement() ?? .circle,
                opacity: Double.random(in: 0.7...1.0),
                delay: Double(i) * 0.003
            )
        }
    }

    private func addConfettiBurst(delay: Double, count: Int) {
        let colors = style.colors
        let screenWidth = UIScreen.main.bounds.width
        let newPieces = (0..<count).map { i in
            ConfettiPiece(
                x: CGFloat.random(in: 0...screenWidth),
                y: CGFloat.random(in: -80 ... -20),
                size: CGFloat.random(in: 3...12),
                color: colors.randomElement() ?? Theme.accent,
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -400...400),
                xVelocity: CGFloat.random(in: -80...80),
                yVelocity: CGFloat.random(in: 50...200),
                shape: ConfettiPiece.ConfettiShape.allCases.randomElement() ?? .star,
                opacity: Double.random(in: 0.6...1.0),
                delay: delay + Double(i) * 0.005
            )
        }
        pieces.append(contentsOf: newPieces)
    }

    private func generateFireworks() {
        let screenWidth = UIScreen.main.bounds.width
        let colors = style.colors
        var allParticles: [FireworkParticle] = []

        let origins: [(CGFloat, CGFloat, Double)] = [
            (screenWidth * 0.25, 120, 0.15),
            (screenWidth * 0.75, 90, 0.35),
            (screenWidth * 0.5, 60, 0.65),
        ]

        for (ox, oy, baseDelay) in origins {
            for j in 0..<18 {
                let angle = (Double(j) / 18.0) * 2 * .pi
                allParticles.append(FireworkParticle(
                    originX: ox,
                    originY: oy,
                    angle: angle,
                    speed: CGFloat.random(in: 80...160),
                    color: colors.randomElement() ?? .white,
                    size: CGFloat.random(in: 3...6),
                    delay: baseDelay
                ))
            }
        }

        fireworks = allParticles
    }

    private func addFireworkBurst(delay: Double) {
        let screenWidth = UIScreen.main.bounds.width
        let colors = style.colors
        let ox = CGFloat.random(in: screenWidth * 0.2 ... screenWidth * 0.8)
        let oy = CGFloat.random(in: 60...150)

        let newParticles = (0..<14).map { j in
            let angle = (Double(j) / 14.0) * 2 * .pi
            return FireworkParticle(
                originX: ox,
                originY: oy,
                angle: angle,
                speed: CGFloat.random(in: 70...140),
                color: colors.randomElement() ?? .white,
                size: CGFloat.random(in: 3...5),
                delay: delay
            )
        }
        fireworks.append(contentsOf: newParticles)
    }

    private func generateRippleRings() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let colors = style.colors

        rippleRings = (0..<12).map { i in
            RippleRing(
                color: colors.randomElement() ?? Theme.accent,
                delay: Double(i) * 0.15 + Double.random(in: 0...0.1),
                maxScale: CGFloat.random(in: 2.0...5.0),
                lineWidth: CGFloat.random(in: 1.5...4.0),
                originX: CGFloat.random(in: screenWidth * 0.1 ... screenWidth * 0.9),
                originY: CGFloat.random(in: screenHeight * 0.1 ... screenHeight * 0.7)
            )
        }
    }

    private func generateShimmerDots() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let colors = style.colors

        shimmerDots = (0..<20).map { i in
            ShimmerDot(
                x: CGFloat.random(in: 20...screenWidth - 20),
                y: CGFloat.random(in: 40...screenHeight - 100),
                size: CGFloat.random(in: 3...8),
                color: colors.randomElement() ?? .white,
                delay: Double(i) * 0.08 + Double.random(in: 0...0.2),
                pulseSpeed: Double.random(in: 4...10)
            )
        }
    }

    private func triggerHapticSequence() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred(intensity: 1.0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred(intensity: 0.8)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred(intensity: 0.9)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
        }
    }

    private func triggerBurstHaptic() {
        let impact = UIImpactFeedbackGenerator(style: .rigid)
        impact.impactOccurred(intensity: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            let impact2 = UIImpactFeedbackGenerator(style: .soft)
            impact2.impactOccurred()
        }
    }

    private func resetState() {
        pieces = []
        fireworks = []
        rippleRings = []
        shimmerDots = []
        showMessage = false
        messageScale = 0.1
        messageOpacity = 0
        glowOpacity = 0
        flashOpacity = 0
        iconBounce = 0
        iconRotation = 0
        ringScale = 0
        ringOpacity = 0
        secondRingScale = 0
        secondRingOpacity = 0
        thirdRingScale = 0
        thirdRingOpacity = 0
        outerGlowScale = 0.8
        outerGlowOpacity = 0
        secondBurstFired = false
        thirdBurstFired = false
    }

    private func starPath(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = rect.width / 2
        let innerRadius = outerRadius * 0.4
        var path = Path()
        for i in 0..<10 {
            let angle = Double(i) * .pi / 5 - .pi / 2
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }

    private func diamondPath(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }

    private func trianglePath(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct CelebrationModifier: ViewModifier {
    @Binding var isShowing: Bool
    let message: String
    let subtitle: String
    let style: CelebrationOverlay.CelebrationStyle
    let duration: Double

    func body(content: Content) -> some View {
        content
            .overlay {
                CelebrationOverlay(
                    isShowing: isShowing,
                    message: message,
                    subtitle: subtitle,
                    style: style
                )
            }
            .onChange(of: isShowing) { _, newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            isShowing = false
                        }
                    }
                }
            }
    }
}

extension View {
    func celebration(
        isShowing: Binding<Bool>,
        message: String = "You did it!",
        subtitle: String = "Keep building momentum.",
        style: CelebrationOverlay.CelebrationStyle = .confetti,
        duration: Double = 3.0
    ) -> some View {
        modifier(CelebrationModifier(
            isShowing: isShowing,
            message: message,
            subtitle: subtitle,
            style: style,
            duration: duration
        ))
    }
}
