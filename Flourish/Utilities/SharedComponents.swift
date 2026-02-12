import SwiftUI

struct BloomingFlower: View {
    let size: CGFloat
    let petalColor: Color
    let centerColor: Color
    let petalCount: Int
    @State private var bloomScale: CGFloat = 0.0
    @State private var rotation: Double = 0
    let delay: Double

    var body: some View {
        ZStack {
            ForEach(0..<petalCount, id: \.self) { i in
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [petalColor, petalColor.opacity(0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size * 0.4, height: size * 0.65)
                    .offset(y: -size * 0.3)
                    .rotationEffect(.degrees(Double(i) * (360.0 / Double(petalCount))))
            }
            Circle()
                .fill(
                    RadialGradient(
                        colors: [centerColor, centerColor.opacity(0.6)],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.18
                    )
                )
                .frame(width: size * 0.3, height: size * 0.3)
        }
        .scaleEffect(bloomScale)
        .rotationEffect(.degrees(rotation))
        .onAppear {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.5).delay(delay)) {
                bloomScale = 1.0
            }
            withAnimation(.linear(duration: Double.random(in: 25...45)).repeatForever(autoreverses: false).delay(delay)) {
                rotation = Bool.random() ? 360 : -360
            }
        }
    }
}
