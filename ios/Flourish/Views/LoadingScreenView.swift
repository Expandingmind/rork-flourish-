import SwiftUI

struct LoadingScreenView: View {
    @State private var letterOpacities: [Double] = Array(repeating: 0, count: 8)
    @State private var letterOffsets: [CGFloat] = Array(repeating: 20, count: 8)
    @State private var flowerScales: [CGFloat] = Array(repeating: 0, count: 12)
    @State private var flowerRotations: [Double] = Array(repeating: -30, count: 12)
    @State private var stemHeights: [CGFloat] = Array(repeating: 0, count: 6)
    @State private var leafScales: [CGFloat] = Array(repeating: 0, count: 8)
    @State private var glowOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var bgPulse: CGFloat = 1.0

    private let flourishLetters: [(Character, Int)] = Array("flourish").enumerated().map { ($1, $0) }

    private let flowerPositions: [(x: CGFloat, y: CGFloat, size: CGFloat, color: Color, delay: Double)] = [
        (0.12, 0.32, 32, Theme.softPink, 0.8),
        (0.88, 0.28, 28, Theme.lavenderMist, 0.9),
        (0.08, 0.58, 24, Theme.gold.opacity(0.8), 1.0),
        (0.92, 0.55, 30, Theme.roseMist, 1.1),
        (0.20, 0.72, 26, Theme.mint.opacity(0.7), 1.2),
        (0.80, 0.70, 22, Theme.softLavender, 1.3),
        (0.50, 0.25, 20, Theme.softPink.opacity(0.6), 1.0),
        (0.35, 0.80, 28, Theme.lavenderLight, 1.4),
        (0.65, 0.78, 24, Theme.roseGold.opacity(0.7), 1.5),
        (0.15, 0.45, 18, Theme.softLemon.opacity(0.7), 1.1),
        (0.85, 0.42, 20, Theme.mint.opacity(0.5), 1.2),
        (0.50, 0.85, 26, Theme.softPink.opacity(0.5), 1.6),
    ]

    private let stemData: [(startX: CGFloat, startY: CGFloat, height: CGFloat, side: Int, delay: Double)] = [
        (0.12, 0.50, 80, 0, 0.5),
        (0.88, 0.48, 90, 1, 0.6),
        (0.20, 0.82, 60, 0, 0.7),
        (0.80, 0.80, 70, 1, 0.8),
        (0.50, 0.90, 50, 0, 0.9),
        (0.35, 0.88, 55, 1, 0.85),
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.94, blue: 0.92),
                        Theme.beige,
                        Color(red: 0.96, green: 0.93, blue: 0.95),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .scaleEffect(bgPulse)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.softPink.opacity(0.12), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .position(x: w * 0.5, y: h * 0.45)
                    .opacity(glowOpacity)

                ForEach(0..<6, id: \.self) { i in
                    let stem = stemData[i]
                    StemShape(side: stem.side)
                        .trim(from: 0, to: stemHeights[i])
                        .stroke(
                            LinearGradient(
                                colors: [Theme.sage.opacity(0.35), Theme.mint.opacity(0.2)],
                                startPoint: .bottom,
                                endPoint: .top
                            ),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round)
                        )
                        .frame(width: 30, height: stem.height)
                        .position(x: w * stem.startX, y: h * stem.startY)
                }

                ForEach(0..<8, id: \.self) { i in
                    let angle = Double(i) * 45
                    let radius: CGFloat = 60 + (i % 2 == 0 ? 15 : 0)
                    let x = w * 0.5 + cos(angle * .pi / 180) * radius
                    let y = h * 0.45 + sin(angle * .pi / 180) * radius * 0.6
                    SplashLeafShape()
                        .fill(
                            LinearGradient(
                                colors: [Theme.sage.opacity(0.3), Theme.mint.opacity(0.15)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: 14, height: 20)
                        .rotationEffect(.degrees(angle + 90))
                        .scaleEffect(leafScales[i])
                        .position(x: x, y: y)
                }

                ForEach(0..<12, id: \.self) { i in
                    let pos = flowerPositions[i]
                    Group {
                        if i % 3 == 0 {
                            FloatingFlower(size: pos.size, color: pos.color, rotation: Double(i) * 25, opacity: 0.8)
                        } else if i % 3 == 1 {
                            TinyDaisy(size: pos.size, color: pos.color, rotation: Double(i) * -18, opacity: 0.8)
                        } else {
                            BloomingFlower(
                                size: pos.size,
                                petalColor: pos.color,
                                centerColor: Theme.softLemon.opacity(0.8),
                                petalCount: 5,
                                delay: pos.delay
                            )
                        }
                    }
                    .scaleEffect(flowerScales[i])
                    .rotationEffect(.degrees(flowerRotations[i]))
                    .position(x: w * pos.x, y: h * pos.y)
                }

                VStack(spacing: 16) {
                    HStack(spacing: 1) {
                        ForEach(flourishLetters, id: \.1) { letter, index in
                            Text(String(letter))
                                .font(.custom(Theme.fontNameBold, size: 52))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Theme.deep,
                                            Theme.softPink.opacity(0.8),
                                            Theme.deep.opacity(0.7)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .opacity(letterOpacities[index])
                                .offset(y: letterOffsets[index])
                        }
                    }

                    Text("grow into the life you deserve")
                        .font(.custom(Theme.fontNameItalic, size: 15))
                        .foregroundStyle(Theme.deep.opacity(0.4))
                        .opacity(subtitleOpacity)
                }
                .position(x: w * 0.5, y: h * 0.45)
            }
        }
        .onAppear {
            for i in 0..<8 {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(Double(i) * 0.08)) {
                    letterOpacities[i] = 1.0
                    letterOffsets[i] = 0
                }
            }

            for i in 0..<6 {
                withAnimation(.easeOut(duration: 0.8).delay(stemData[i].delay)) {
                    stemHeights[i] = 1.0
                }
            }

            for i in 0..<8 {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.7 + Double(i) * 0.06)) {
                    leafScales[i] = 1.0
                }
            }

            for i in 0..<12 {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.5).delay(flowerPositions[i].delay)) {
                    flowerScales[i] = 1.0
                    flowerRotations[i] = 0
                }
            }

            withAnimation(.easeInOut(duration: 1.0).delay(0.4)) {
                glowOpacity = 1.0
            }

            withAnimation(.easeIn(duration: 0.6).delay(0.9)) {
                subtitleOpacity = 1.0
            }

            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true).delay(1.0)) {
                bgPulse = 1.01
            }
        }
    }
}

struct StemShape: Shape {
    let side: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: w * 0.5, y: h))

        if side == 0 {
            path.addCurve(
                to: CGPoint(x: w * 0.3, y: 0),
                control1: CGPoint(x: w * 0.2, y: h * 0.6),
                control2: CGPoint(x: w * 0.6, y: h * 0.3)
            )
        } else {
            path.addCurve(
                to: CGPoint(x: w * 0.7, y: 0),
                control1: CGPoint(x: w * 0.8, y: h * 0.6),
                control2: CGPoint(x: w * 0.4, y: h * 0.3)
            )
        }

        return path
    }
}

struct SplashLeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: h),
            control: CGPoint(x: w * 1.1, y: h * 0.4)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: 0),
            control: CGPoint(x: w * -0.1, y: h * 0.4)
        )

        return path
    }
}
