import SwiftUI
import SwiftData
import PhotosUI

struct FeatureRow: Identifiable {
    let id = UUID()
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
}

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @Environment(\.modelContext) private var modelContext
    @State private var currentPage: Int = 0
    @State private var nameInput: String = ""
    @State private var biggestGoal: String = ""
    @State private var focusArea: String = ""
    @State private var dreamDestination: String = ""
    @State private var appearAnimation: Bool = false
    @State private var iconBounce: Bool = false
    @State private var isHolding: Bool = false
    @State private var holdProgress: CGFloat = 0
    @State private var launchTriggered: Bool = false
    @State private var greenFillScale: CGFloat = 0
    @State private var flowerParticles: [FlowerParticle] = []
    @State private var showParticles: Bool = false
    @State private var fingerprintCenter: CGPoint = .zero
    @State private var pulseScale: CGFloat = 1.0
    @State private var welcomeTextOpacity: Double = 0
    @State private var welcomeTextScale: CGFloat = 0.5
    @State private var visibleFeatureCount: Int = 0
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var profileImageData: Data? = nil
    @FocusState private var isTextFieldFocused: Bool
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userFocusArea") private var userFocusArea: String = ""

    private let focusAreas = [
        ("Career & Finance", "briefcase.fill", Theme.gold),
        ("Health & Fitness", "heart.fill", Theme.rose),
        ("Travel & Adventure", "airplane", Theme.softSky),
        ("Creativity & Learning", "paintbrush.fill", Theme.lavender),
        ("Relationships", "person.2.fill", Theme.softPink),
        ("Inner Peace", "leaf.fill", Theme.mint),
    ]

    private let totalPages = 8
    private let holdDuration: Double = 1.5

    var body: some View {
        ZStack {
            Theme.beige.ignoresSafeArea()

            if launchTriggered {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(red: 0.97, green: 0.91, blue: 0.88), Color(red: 0.96, green: 0.88, blue: 0.85), Color(red: 0.95, green: 0.86, blue: 0.82)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 600
                        )
                    )
                    .frame(width: 1200, height: 1200)
                    .scaleEffect(greenFillScale)
                    .position(fingerprintCenter)
                    .ignoresSafeArea()
            }

            if !launchTriggered {
                backgroundElements
            }

            if showParticles {
                ForEach(flowerParticles) { particle in
                    particle.view
                        .position(particle.position)
                        .opacity(particle.opacity)
                        .scaleEffect(particle.scale)
                        .rotationEffect(.degrees(particle.rotation))
                }
            }

            if launchTriggered {
                VStack(spacing: 8) {
                    Text("Welcome,")
                        .font(Theme.fontBold(32))
                        .foregroundStyle(Theme.deep)
                    Text(nameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Friend" : nameInput.trimmingCharacters(in: .whitespacesAndNewlines))
                        .font(Theme.fontBold(38))
                        .foregroundStyle(Theme.deep)
                }
                .opacity(welcomeTextOpacity)
                .scaleEffect(welcomeTextScale)
            }

            if !launchTriggered {
                VStack(spacing: 0) {
                    Spacer()
                    Group {
                        switch currentPage {
                        case 0: welcomePage
                        case 1: profilePhotoPage
                        case 2: featuresPage1
                        case 3: featuresPage2
                        case 4: goalQuestionPage
                        case 5: focusAreaPage
                        case 6: destinationQuestionPage
                        case 7: readyPage
                        default: EmptyView()
                        }
                    }
                    .id(currentPage)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    Spacer()
                    bottomControls
                        .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                appearAnimation = true
            }
            triggerIconBounce()
            startPulse()
        }
    }

    // MARK: - Pages

    private var welcomePage: some View {
        VStack(spacing: 28) {
            iconCircle(icon: "sparkles", color: Theme.gold, accent: Theme.softPink)

            VStack(spacing: 14) {
                Text("Welcome to Flourish")
                    .font(Theme.titleFont)
                    .foregroundStyle(Theme.deep)
                    .multilineTextAlignment(.center)

                Text("Your personal space to grow, dream, and track the life you're building.")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.deep.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)

            VStack(spacing: 8) {
                Text("What should we call you?")
                    .font(Theme.font(15))
                    .foregroundStyle(Theme.deep.opacity(0.5))

                TextField("Your name", text: $nameInput)
                    .font(Theme.font(20))
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Theme.rose.opacity(0.08), radius: 8, y: 4)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Theme.rose.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 48)
                    .focused($isTextFieldFocused)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            isTextFieldFocused = true
                        }
                    }
            }
        }
    }

    private var featuresPage1: some View {
        let features: [FeatureRow] = [
            FeatureRow(icon: "flame.fill", iconColor: Theme.rose, title: "Own Your Day", description: "Set daily intentions, build micro-habits, and check off tasks that compound."),
            FeatureRow(icon: "bolt.fill", iconColor: Theme.lavender, title: "Collect Evidence", description: "Log wins, savings, and milestones — undeniable proof of your growth."),
            FeatureRow(icon: "leaf.fill", iconColor: Theme.mint, title: "Grow Your Garden", description: "Every action plants a seed. Watch your garden bloom as you flourish."),
        ]
        return animatedFeatureGroupPage(
            title: "Built for Growth",
            subtitle: "Tools designed to help you show up every day.",
            features: features,
            accent: Theme.rose
        )
    }

    private var featuresPage2: some View {
        let features: [FeatureRow] = [
            FeatureRow(icon: "sparkles", iconColor: Theme.gold, title: "Dream Without Limits", description: "Build your bucket list with goals, experiences, and adventures waiting for you."),
            FeatureRow(icon: "pin.fill", iconColor: Theme.softSky, title: "Map Your World", description: "Pin destinations and plan the travels that excite you most."),
            FeatureRow(icon: "person.crop.circle.fill", iconColor: Theme.softPink, title: "Track Your Journey", description: "Your profile, your streaks, your story — all in one place."),
        ]
        return animatedFeatureGroupPage(
            title: "Dream & Explore",
            subtitle: "Everything you need to plan the life you want.",
            features: features,
            accent: Theme.lavender
        )
    }

    private var goalQuestionPage: some View {
        VStack(spacing: 28) {
            iconCircle(icon: "target", color: Theme.rose, accent: Theme.rose)

            VStack(spacing: 14) {
                Text("What's your biggest goal\nright now?")
                    .font(Theme.titleFont)
                    .foregroundStyle(Theme.deep)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text("We'll add it to your bucket list so you can start tracking it immediately.")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.deep.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)

            TextField("e.g. Start my own business", text: $biggestGoal)
                .font(Theme.font(18))
                .multilineTextAlignment(.center)
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: Theme.rose.opacity(0.08), radius: 8, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.rose.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 40)
                .focused($isTextFieldFocused)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        isTextFieldFocused = true
                    }
                }
        }
    }

    private var focusAreaPage: some View {
        VStack(spacing: 24) {
            iconCircle(icon: "compass.drawing", color: Theme.lavender, accent: Theme.lavender)

            VStack(spacing: 14) {
                Text("What area of life do you\nwant to focus on?")
                    .font(Theme.titleFont)
                    .foregroundStyle(Theme.deep)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text("This helps us personalise your experience.")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.deep.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(focusAreas, id: \.0) { area in
                    let isSelected = focusArea == area.0
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            focusArea = area.0
                        }
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: area.1)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(isSelected ? .white : area.2)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(isSelected ? area.2 : area.2.opacity(0.15))
                                )

                            Text(area.0)
                                .font(Theme.font(13))
                                .foregroundStyle(isSelected ? .white : Theme.deep)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isSelected ? area.2 : Color.white)
                                .shadow(color: isSelected ? area.2.opacity(0.3) : Theme.deep.opacity(0.04), radius: isSelected ? 8 : 4, y: isSelected ? 4 : 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isSelected ? Color.clear : Theme.deep.opacity(0.06), lineWidth: 1)
                        )
                        .scaleEffect(isSelected ? 1.03 : 1.0)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 28)
        }
    }

    private var destinationQuestionPage: some View {
        VStack(spacing: 28) {
            iconCircle(icon: "airplane.departure", color: Theme.softSky, accent: Theme.softSky)

            VStack(spacing: 14) {
                Text("Where do you dream\nof travelling?")
                    .font(Theme.titleFont)
                    .foregroundStyle(Theme.deep)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text("We'll pin it on your travel map so you can start planning.")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.deep.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)

            TextField("e.g. Tokyo, Japan", text: $dreamDestination)
                .font(Theme.font(18))
                .multilineTextAlignment(.center)
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: Theme.softSky.opacity(0.08), radius: 8, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.softSky.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 40)
                .focused($isTextFieldFocused)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        isTextFieldFocused = true
                    }
                }
        }
    }

    private var readyPage: some View {
        VStack(spacing: 32) {
            VStack(spacing: 14) {
                if !nameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Welcome, \(nameInput.trimmingCharacters(in: .whitespacesAndNewlines))")
                        .font(Theme.titleFont)
                        .foregroundStyle(Theme.deep)
                        .multilineTextAlignment(.center)
                } else {
                    Text("You're Ready")
                        .font(Theme.titleFont)
                        .foregroundStyle(Theme.deep)
                        .multilineTextAlignment(.center)
                }

                Text("Hold to begin your journey")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.deep.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 36)

            GeometryReader { geo in
                let center = CGPoint(
                    x: geo.frame(in: .global).midX,
                    y: geo.frame(in: .global).midY
                )
                ZStack {
                    Circle()
                        .fill(Theme.mint.opacity(0.06))
                        .frame(width: 180, height: 180)
                        .scaleEffect(pulseScale)
                        .opacity(isHolding ? 0 : 0.8)

                    Circle()
                        .fill(Theme.mint.opacity(0.04))
                        .frame(width: 220, height: 220)
                        .scaleEffect(pulseScale * 0.95)
                        .opacity(isHolding ? 0 : 0.5)

                    Circle()
                        .stroke(Theme.mint.opacity(0.15), lineWidth: 3)
                        .frame(width: 140, height: 140)

                    Circle()
                        .trim(from: 0, to: holdProgress)
                        .stroke(
                            Theme.mint,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))

                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Theme.mint.opacity(0.15), Theme.mint.opacity(0.05)],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 120, height: 120)

                        Image(systemName: "touchid")
                            .font(.system(size: 52, weight: .thin))
                            .foregroundStyle(isHolding ? Theme.mint : Theme.mint.opacity(0.7))
                            .scaleEffect(isHolding ? 1.1 : 1.0)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    fingerprintCenter = center
                }
                .onChange(of: geo.frame(in: .global)) { _, newFrame in
                    fingerprintCenter = CGPoint(x: newFrame.midX, y: newFrame.midY)
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isHolding && !launchTriggered {
                                startHold()
                            }
                        }
                        .onEnded { _ in
                            if !launchTriggered {
                                cancelHold()
                            }
                        }
                )
            }
            .frame(height: 240)

            VStack(spacing: 6) {
                if !biggestGoal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    seedPreviewChip(icon: "target", text: biggestGoal.trimmingCharacters(in: .whitespacesAndNewlines), color: Theme.rose)
                }
                if !focusArea.isEmpty {
                    let matched = focusAreas.first(where: { $0.0 == focusArea })
                    seedPreviewChip(icon: matched?.1 ?? "compass.drawing", text: focusArea, color: matched?.2 ?? Theme.lavender)
                }
                if !dreamDestination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    seedPreviewChip(icon: "airplane", text: dreamDestination.trimmingCharacters(in: .whitespacesAndNewlines), color: Theme.softSky)
                }
            }
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Reusable Components

    private func iconCircle(icon: String, color: Color, accent: Color) -> some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.10))
                .frame(width: 120, height: 120)
                .scaleEffect(appearAnimation ? 1.0 : 0.5)

            Circle()
                .fill(accent.opacity(0.05))
                .frame(width: 155, height: 155)
                .scaleEffect(appearAnimation ? 1.0 : 0.3)

            Image(systemName: icon)
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(color)
                .symbolEffect(.bounce, value: iconBounce)
        }
    }

    private func animatedFeatureGroupPage(title: String, subtitle: String, features: [FeatureRow], accent: Color) -> some View {
        VStack(spacing: 24) {
            VStack(spacing: 10) {
                Text(title)
                    .font(Theme.titleFont)
                    .foregroundStyle(Theme.deep)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.deep.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)

            VStack(spacing: 12) {
                ForEach(Array(features.enumerated()), id: \.element.id) { index, feature in
                    HStack(spacing: 16) {
                        Image(systemName: feature.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(feature.iconColor)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(feature.iconColor.opacity(0.12))
                            )

                        VStack(alignment: .leading, spacing: 3) {
                            Text(feature.title)
                                .font(Theme.fontBold(16))
                                .foregroundStyle(Theme.deep)

                            Text(feature.description)
                                .font(Theme.font(13))
                                .foregroundStyle(Theme.deep.opacity(0.55))
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: Theme.deep.opacity(0.04), radius: 6, y: 3)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Theme.deep.opacity(0.04), lineWidth: 1)
                    )
                    .opacity(index < visibleFeatureCount ? 1 : 0)
                    .offset(y: index < visibleFeatureCount ? 0 : 20)
                    .scaleEffect(index < visibleFeatureCount ? 1 : 0.95)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.05), value: visibleFeatureCount)
                }
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            visibleFeatureCount = 0
            for i in 1...features.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + Double(i - 1) * 0.4) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        visibleFeatureCount = i
                    }
                }
            }
        }
    }

    private func seedPreviewChip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(color)

            Text(text)
                .font(Theme.font(14))
                .foregroundStyle(Theme.deep)
                .lineLimit(1)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(color.opacity(0.6))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
        )
    }

    // MARK: - Background

    private var backgroundElements: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                let pageColor = currentPageColor

                Circle()
                    .fill(pageColor.opacity(0.08))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .position(x: w * 0.2, y: h * 0.15)
                    .animation(.easeInOut(duration: 0.8), value: currentPage)

                Circle()
                    .fill(pageColor.opacity(0.06))
                    .frame(width: 250, height: 250)
                    .blur(radius: 50)
                    .position(x: w * 0.8, y: h * 0.7)
                    .animation(.easeInOut(duration: 0.8), value: currentPage)

                FloatingFlower(size: 26, color: Theme.softPink, rotation: 20, opacity: 0.3)
                    .position(x: w * 0.9, y: h * 0.12)

                TinyDaisy(size: 20, color: Theme.lavenderMist, rotation: -15, opacity: 0.35)
                    .position(x: w * 0.08, y: h * 0.85)

                FloatingFlower(size: 18, color: Theme.gold, rotation: 40, opacity: 0.25)
                    .position(x: w * 0.85, y: h * 0.9)
            }
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }

    private var profilePhotoPage: some View {
        VStack(spacing: 28) {
            iconCircle(icon: "camera.fill", color: Theme.softPink, accent: Theme.softPink)

            VStack(spacing: 14) {
                Text("Add a Profile Photo")
                    .font(Theme.titleFont)
                    .foregroundStyle(Theme.deep)
                    .multilineTextAlignment(.center)

                Text("Give your journey a face. You can always change this later.")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.deep.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                ZStack {
                    if let profileImageData, let uiImage = UIImage(data: profileImageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 130, height: 130)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Theme.softPink.opacity(0.4), lineWidth: 3)
                            )
                            .shadow(color: Theme.softPink.opacity(0.2), radius: 12, y: 4)
                    } else {
                        Circle()
                            .fill(Theme.softPink.opacity(0.1))
                            .frame(width: 130, height: 130)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .font(.system(size: 36, weight: .light))
                                        .foregroundStyle(Theme.softPink)
                                    Text("Tap to choose")
                                        .font(Theme.font(13))
                                        .foregroundStyle(Theme.deep.opacity(0.4))
                                }
                            )
                            .overlay(
                                Circle()
                                    .stroke(Theme.softPink.opacity(0.2), lineWidth: 2)
                            )
                    }
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let newItem, let data = try? await newItem.loadTransferable(type: Data.self) {
                        if let img = UIImage(data: data), let compressed = img.jpegData(compressionQuality: 0.7) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                profileImageData = compressed
                            }
                        }
                    }
                }
            }
        }
    }

    private var currentPageColor: Color {
        switch currentPage {
        case 0: return Theme.softPink
        case 1: return Theme.softPink
        case 2: return Theme.rose
        case 3: return Theme.lavender
        case 4: return Theme.rose
        case 5: return Theme.lavender
        case 6: return Theme.softSky
        case 7: return Theme.mint
        default: return Theme.softPink
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 24) {
            pageIndicator

            if currentPage == totalPages - 1 {
                Color.clear.frame(height: 56)
            } else {
                Button {
                    advancePage()
                } label: {
                    HStack(spacing: 8) {
                        Text(continueButtonTitle)
                            .font(Theme.fontBold(17))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(canContinue ? currentPageColor : Theme.deep.opacity(0.15))
                    )
                    .shadow(color: canContinue ? currentPageColor.opacity(0.3) : .clear, radius: 12, y: 6)
                }
                .disabled(!canContinue)
                .animation(.easeInOut(duration: 0.2), value: canContinue)
                .padding(.horizontal, 36)
            }

            if currentPage > 0 {
                Button {
                    isTextFieldFocused = false
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        currentPage -= 1
                    }
                    triggerIconBounce()
                } label: {
                    Text("Back")
                        .font(Theme.font(15))
                        .foregroundStyle(Theme.deep.opacity(0.4))
                }
            } else {
                Color.clear.frame(height: 20)
            }
        }
    }

    private var continueButtonTitle: String {
        return "Continue"
    }

    private var canContinue: Bool {
        switch currentPage {
        case 0: return !nameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 1: return true
        case 2, 3: return true
        case 4: return !biggestGoal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 5: return !focusArea.isEmpty
        case 6: return !dreamDestination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default: return true
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? currentPageColor : Theme.deep.opacity(0.12))
                    .frame(width: index == currentPage ? 28 : 8, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentPage)
            }
        }
    }

    // MARK: - Actions

    private func advancePage() {
        isTextFieldFocused = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            currentPage += 1
        }
        triggerIconBounce()
    }

    private func triggerIconBounce() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            iconBounce.toggle()
        }
    }

    private func startHold() {
        isHolding = true
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        withAnimation(.linear(duration: holdDuration)) {
            holdProgress = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + holdDuration) {
            if isHolding {
                triggerLaunch()
            }
        }
    }

    private func cancelHold() {
        isHolding = false
        withAnimation(.easeOut(duration: 0.3)) {
            holdProgress = 0
        }
    }

    private func triggerLaunch() {
        launchTriggered = true

        let heavy = UIImpactFeedbackGenerator(style: .heavy)
        heavy.impactOccurred()

        spawnFlowerParticles()
        showParticles = true

        withAnimation(.easeOut(duration: 1.2)) {
            greenFillScale = 3.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let notif = UINotificationFeedbackGenerator()
            notif.notificationOccurred(.success)
        }

        animateParticles()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                welcomeTextOpacity = 1.0
                welcomeTextScale = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            finishOnboarding()
        }
    }

    private func spawnFlowerParticles() {
        let colors: [Color] = [Theme.softPink, Theme.lavender, Theme.gold, Theme.mint, Theme.rose, Theme.softSky, Theme.lavenderMist, Theme.softLemon]
        let flowerTypes: [FlowerParticle.FlowerType] = [.petal, .daisy, .blossom, .leaf]
        var particles: [FlowerParticle] = []

        for i in 0..<40 {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 180...500)
            let dx = cos(angle) * Double(speed)
            let dy = sin(angle) * Double(speed)
            let particle = FlowerParticle(
                id: i,
                position: fingerprintCenter,
                targetDx: dx,
                targetDy: dy,
                color: colors[i % colors.count],
                flowerType: flowerTypes[i % flowerTypes.count],
                size: CGFloat.random(in: 16...40),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -360...360),
                opacity: 1.0,
                scale: 0.0
            )
            particles.append(particle)
        }

        flowerParticles = particles
    }

    private func animateParticles() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            for i in flowerParticles.indices {
                flowerParticles[i].position.x += flowerParticles[i].targetDx
                flowerParticles[i].position.y += flowerParticles[i].targetDy
                flowerParticles[i].scale = CGFloat.random(in: 0.8...1.3)
                flowerParticles[i].rotation += flowerParticles[i].rotationSpeed
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 1.0)) {
                for i in self.flowerParticles.indices {
                    self.flowerParticles[i].position.y += CGFloat.random(in: 40...120)
                    self.flowerParticles[i].opacity = 0
                    self.flowerParticles[i].rotation += Double.random(in: -180...180)
                }
            }
        }
    }

    private func startPulse() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.08
        }
    }

    private func finishOnboarding() {
        let auth = AuthService.shared
        let trimmedName = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            userName = trimmedName
            auth.saveUserData("userName", value: trimmedName)
        }

        if !focusArea.isEmpty {
            userFocusArea = focusArea
            auth.saveUserData("userFocusArea", value: focusArea)
        }

        if let profileImageData {
            auth.saveUserData("profileImageData", data: profileImageData)
        }

        let trimmedGoal = biggestGoal.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedGoal.isEmpty {
            let item = BucketListItem(title: trimmedGoal, detail: "Added during onboarding", colorIndex: 0)
            modelContext.insert(item)
        }

        let trimmedDest = dreamDestination.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedDest.isEmpty {
            let destination = TravelDestination(name: trimmedDest)
            modelContext.insert(destination)
        }

        try? modelContext.save()

        withAnimation(.easeInOut(duration: 0.4)) {
            hasCompletedOnboarding = true
        }
    }
}

struct FlowerParticle: Identifiable {
    enum FlowerType {
        case petal, daisy, blossom, leaf
    }

    let id: Int
    var position: CGPoint
    let targetDx: Double
    let targetDy: Double
    let color: Color
    let flowerType: FlowerType
    let size: CGFloat
    var rotation: Double
    let rotationSpeed: Double
    var opacity: Double
    var scale: CGFloat

    @ViewBuilder
    var view: some View {
        switch flowerType {
        case .petal:
            Ellipse()
                .fill(color)
                .frame(width: size * 0.5, height: size)
        case .daisy:
            TinyDaisy(size: size, color: color, rotation: 0, opacity: 1.0)
        case .blossom:
            FloatingFlower(size: size, color: color, rotation: 0, opacity: 1.0)
        case .leaf:
            Image(systemName: "leaf.fill")
                .font(.system(size: size * 0.6))
                .foregroundStyle(color)
        }
    }
}
