import SwiftUI

enum Theme {
    static let rose = Color(red: 0.91, green: 0.45, blue: 0.48)
    static let lavender = Color(red: 0.72, green: 0.55, blue: 0.88)
    static let cream = Color(red: 0.99, green: 0.82, blue: 0.45)
    static let mint = Color(red: 0.55, green: 0.84, blue: 0.64)
    static let sage = Color(red: 0.38, green: 0.65, blue: 0.48)

    static let beige = Color(red: 0.98, green: 0.96, blue: 0.93)
    static let warmCream = Color(red: 1.0, green: 0.96, blue: 0.90)
    static let blush = Color(red: 0.95, green: 0.52, blue: 0.55)
    static let dustyRose = Color(red: 0.91, green: 0.45, blue: 0.48)
    static let roseGold = Color(red: 0.93, green: 0.58, blue: 0.52)

    static let accent = Color(red: 0.91, green: 0.45, blue: 0.48)
    static let gold = Color(red: 0.99, green: 0.78, blue: 0.28)
    static let deep = Color(red: 0.22, green: 0.24, blue: 0.26)

    static let warmBg = Color(red: 0.98, green: 0.96, blue: 0.93)
    static let roseMist = Color(red: 0.96, green: 0.72, blue: 0.72)
    static let goldMist = Color(red: 1.0, green: 0.90, blue: 0.62)

    static let softPink = Color(red: 0.95, green: 0.52, blue: 0.58)
    static let softLavender = Color(red: 0.72, green: 0.55, blue: 0.88)
    static let lavenderMist = Color(red: 0.82, green: 0.72, blue: 0.94)
    static let lavenderLight = Color(red: 0.88, green: 0.80, blue: 0.96)

    static let softMint = Color(red: 0.55, green: 0.84, blue: 0.64)
    static let softPeach = Color(red: 1.0, green: 0.72, blue: 0.48)
    static let softSky = Color(red: 0.45, green: 0.72, blue: 0.95)
    static let softLemon = Color(red: 1.0, green: 0.88, blue: 0.38)

    static let cardBackground = Color(red: 1.0, green: 0.99, blue: 0.97)
    static let subtleCard = Color(red: 0.98, green: 0.97, blue: 0.95)

    static let roseCard = Color(red: 0.91, green: 0.45, blue: 0.48).opacity(0.12)
    static let lavenderCard = Color(red: 0.72, green: 0.55, blue: 0.88).opacity(0.14)
    static let creamCard = Color(red: 0.99, green: 0.82, blue: 0.45).opacity(0.22)
    static let mintCard = Color(red: 0.55, green: 0.84, blue: 0.64).opacity(0.16)
    static let sageCard = Color(red: 0.38, green: 0.65, blue: 0.48).opacity(0.14)

    static var pageBg: some View {
        Color(red: 0.98, green: 0.96, blue: 0.93)
            .ignoresSafeArea()
    }

    static let fontName = "Palatino"
    static let fontNameBold = "Palatino-Bold"
    static let fontNameItalic = "Palatino-Italic"

    static func font(_ size: CGFloat) -> Font {
        .custom(fontName, size: size)
    }

    static func fontBold(_ size: CGFloat) -> Font {
        .custom(fontNameBold, size: size)
    }

    static var largeTitleFont: Font { .custom(fontNameBold, size: 34) }
    static var titleFont: Font { .custom(fontNameBold, size: 28) }
    static var title2Font: Font { .custom(fontNameBold, size: 22) }
    static var title3Font: Font { .custom(fontName, size: 20) }
    static var headlineFont: Font { .custom(fontNameBold, size: 17) }
    static var bodyFont: Font { .custom(fontName, size: 17) }
    static var calloutFont: Font { .custom(fontName, size: 16) }
    static var subheadlineFont: Font { .custom(fontName, size: 15) }
    static var footnoteFont: Font { .custom(fontName, size: 13) }
    static var captionFont: Font { .custom(fontName, size: 12) }
    static var caption2Font: Font { .custom(fontName, size: 11) }
}
