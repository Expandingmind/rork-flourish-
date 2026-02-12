import SwiftUI

struct FloatingFlower: View {
    let size: CGFloat
    let color: Color
    let rotation: Double
    let opacity: Double

    init(size: CGFloat = 28, color: Color = Theme.softPink, rotation: Double = 0, opacity: Double = 0.45) {
        self.size = size
        self.color = color
        self.rotation = rotation
        self.opacity = opacity
    }

    var body: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { i in
                Ellipse()
                    .fill(color)
                    .frame(width: size * 0.45, height: size * 0.7)
                    .offset(y: -size * 0.28)
                    .rotationEffect(.degrees(Double(i) * 72))
            }
            Circle()
                .fill(Theme.cream.opacity(0.9))
                .frame(width: size * 0.28, height: size * 0.28)
        }
        .opacity(opacity)
        .rotationEffect(.degrees(rotation))
    }
}

struct TinyDaisy: View {
    let size: CGFloat
    let color: Color
    let rotation: Double
    let opacity: Double

    init(size: CGFloat = 22, color: Color = Theme.lavenderMist, rotation: Double = 0, opacity: Double = 0.5) {
        self.size = size
        self.color = color
        self.rotation = rotation
        self.opacity = opacity
    }

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                Capsule()
                    .fill(color)
                    .frame(width: size * 0.3, height: size * 0.6)
                    .offset(y: -size * 0.3)
                    .rotationEffect(.degrees(Double(i) * 60))
            }
            Circle()
                .fill(Theme.softLemon.opacity(0.8))
                .frame(width: size * 0.25, height: size * 0.25)
        }
        .opacity(opacity)
        .rotationEffect(.degrees(rotation))
    }
}

struct BackgroundFlowerScatter: View {
    let seed: Int

    init(seed: Int = 0) {
        self.seed = seed
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                FloatingFlower(size: 30, color: Theme.softPink, rotation: 15, opacity: 0.35)
                    .position(x: w * 0.08, y: h * 0.08)

                TinyDaisy(size: 26, color: Theme.lavenderMist, rotation: -20, opacity: 0.4)
                    .position(x: w * 0.93, y: h * 0.18)

                FloatingFlower(size: 22, color: Theme.gold, rotation: 40, opacity: 0.38)
                    .position(x: w * 0.06, y: h * 0.42)

                TinyDaisy(size: 28, color: Theme.softPink, rotation: 10, opacity: 0.35)
                    .position(x: w * 0.92, y: h * 0.55)

                FloatingFlower(size: 24, color: Theme.softLemon, rotation: -35, opacity: 0.35)
                    .position(x: w * 0.05, y: h * 0.72)

                TinyDaisy(size: 22, color: Theme.gold, rotation: 45, opacity: 0.4)
                    .position(x: w * 0.94, y: h * 0.88)
            }
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

struct FlowerBackgroundModifier: ViewModifier {
    let seed: Int

    func body(content: Content) -> some View {
        ZStack {
            Color(red: 0.98, green: 0.96, blue: 0.93)
                .ignoresSafeArea()
            BackgroundFlowerScatter(seed: seed)
            content
        }
    }
}

extension View {
    func flowerBackground(seed: Int = 0) -> some View {
        modifier(FlowerBackgroundModifier(seed: seed))
    }
}
