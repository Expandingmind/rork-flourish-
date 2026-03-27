import SwiftUI
import SwiftData

enum GardenMode: String, CaseIterable {
    case view
    case plant
    case water
    case remove

    var label: String {
        switch self {
        case .view: return "Garden"
        case .plant: return "Plant"
        case .water: return "Water"
        case .remove: return "Remove"
        }
    }

    var icon: String {
        switch self {
        case .view: return "leaf.fill"
        case .plant: return "arrow.down.to.line.compact"
        case .water: return "drop.fill"
        case .remove: return "scissors"
        }
    }
}

struct BloomGardenView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \GardenPlant.createdDate) private var plants: [GardenPlant]
    @Query private var resources: [GardenResource]

    @State private var selectedPlant: GardenPlant?
    @State private var showingPlantDetail: Bool = false
    @State private var newPlantIndex: Int?
    @State private var wateredPlantIndex: Int?
    @State private var removingPlantIndex: Int?
    @State private var gardenMode: GardenMode = .view
    @State private var seedBounce: Bool = false
    @State private var waterBounce: Bool = false
    @State private var sparklePhase: Bool = false
    @State private var showRemoveConfirm: Bool = false
    @State private var plantToRemove: GardenPlant?

    private let columns = 3
    private let totalSlots = 9

    private let outlineColor = Color(red: 0.62, green: 0.58, blue: 0.52)

    private var resource: GardenResource {
        resources.first ?? GardenResource()
    }

    var body: some View {
        ZStack {
            gardenScene

            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(Theme.fontBold(17))
                            .foregroundStyle(outlineColor)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(outlineColor.opacity(0.3), lineWidth: 1))
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                Spacer()
            }
        }
        .sheet(isPresented: $showingPlantDetail) {
            if let plant = selectedPlant {
                PlantDetailSheet(plant: plant, onRemove: {
                    showingPlantDetail = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            modelContext.delete(plant)
                        }
                        let gen = UINotificationFeedbackGenerator()
                        gen.notificationOccurred(.success)
                    }
                })
                    .presentationDetents([.fraction(0.42)])
                    .presentationDragIndicator(.visible)
            }
        }
        .alert("Remove Plant?", isPresented: $showRemoveConfirm) {
            Button("Remove", role: .destructive) {
                if let plant = plantToRemove {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        removingPlantIndex = plant.gridIndex
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        withAnimation {
                            modelContext.delete(plant)
                            removingPlantIndex = nil
                        }
                        let gen = UINotificationFeedbackGenerator()
                        gen.notificationOccurred(.success)
                    }
                }
                plantToRemove = nil
            }
            Button("Cancel", role: .cancel) {
                plantToRemove = nil
            }
        } message: {
            Text("This plant will be permanently removed. It cannot be stored or recovered.")
        }
        .onAppear {
            ensureResourceExists()
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                sparklePhase = true
            }
        }
    }

    private func ensureResourceExists() {
        if resources.isEmpty {
            let r = GardenResource()
            modelContext.insert(r)
        }
    }

    private var gardenScene: some View {
        GeometryReader { geo in
            ZStack {
                gardenBackground
                    .frame(width: geo.size.width, height: geo.size.height)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 50)

                        gardenTitle
                            .padding(.top, 20)

                        resourceBar
                            .padding(.top, 14)

                        modeSelector
                            .padding(.top, 14)

                        if gardenMode != .view {
                            modeHint
                                .padding(.top, 8)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        gardenPlots(width: geo.size.width)
                            .padding(.top, 24)

                        gardenLegend
                            .padding(.top, 32)
                            .padding(.horizontal, 24)

                        Spacer(minLength: 100)
                    }
                }
            }
        }
        .ignoresSafeArea()
    }

    private static let gardenBackgroundURL = URL(string: "https://pub-e001eb4506b145aa938b5d3badbff6a5.r2.dev/attachments/xicu08bf8gc7cgml2q1zt")

    private var gardenBackground: some View {
        AsyncImage(url: Self.gardenBackgroundURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            default:
                Color(red: 0.85, green: 0.92, blue: 0.80)
            }
        }
    }

    private var gardenTitle: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "sparkle")
                    .font(Theme.caption2Font)
                    .foregroundStyle(Theme.gold.opacity(0.7))
                Text("Your Garden")
                    .font(Theme.title2Font)
                    .fontWeight(.heavy)
                    .foregroundStyle(Theme.deep)
                Image(systemName: "sparkle")
                    .font(Theme.caption2Font)
                    .foregroundStyle(Theme.gold.opacity(0.7))
            }

            Text(gardenSubtitle)
                .font(Theme.captionFont)
                .foregroundStyle(Theme.deep.opacity(0.5))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.3), lineWidth: 1))
        )
    }

    private var gardenSubtitle: String {
        if plants.isEmpty && resource.seeds == 0 {
            return "Complete tasks to earn seeds & water"
        }
        if plants.isEmpty && resource.seeds > 0 {
            return "Tap Plant to sow your first seed!"
        }
        let bloomed = plants.filter { $0.stage == .bloom }.count
        if bloomed > 0 {
            return "\(bloomed) bloom\(bloomed == 1 ? "" : "s") flourishing"
        }
        return "\(plants.count) plant\(plants.count == 1 ? "" : "s") growing"
    }

    private var resourceBar: some View {
        HStack(spacing: 10) {
            resourcePill(
                icon: "leaf.arrow.circlepath",
                count: resource.seeds,
                label: "Seeds",
                color: Theme.softPeach,
                isActive: gardenMode == .plant,
                bounce: $seedBounce
            )
            resourcePill(
                icon: "drop.fill",
                count: resource.waterCans,
                label: "Water",
                color: Theme.softSky,
                isActive: gardenMode == .water,
                bounce: $waterBounce
            )
            gardenStatPill(count: plants.filter { $0.stage == .bloom }.count, label: "Blooms", emoji: "🌸")
        }
    }

    private func resourcePill(icon: String, count: Int, label: String, color: Color, isActive: Bool, bounce: Binding<Bool>) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(Theme.font(10))
                .foregroundStyle(color)
                .scaleEffect(bounce.wrappedValue ? 1.4 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.4), value: bounce.wrappedValue)
            Text("\(count)")
                .font(Theme.captionFont)
                .fontWeight(.heavy)
                .foregroundStyle(Theme.deep)
                .contentTransition(.numericText())
            Text(label)
                .font(Theme.font(9))
                .foregroundStyle(Theme.deep.opacity(0.4))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
        .overlay(
            Capsule()
                .stroke(isActive ? color.opacity(0.6) : .white.opacity(0.3), lineWidth: 1.2)
        )
    }

    private var modeSelector: some View {
        HStack(spacing: 4) {
            ForEach(GardenMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        gardenMode = gardenMode == mode ? .view : mode
                    }
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: mode.icon)
                            .font(Theme.fontBold(11))
                        Text(mode.label)
                            .font(Theme.fontBold(11))
                    }
                    .foregroundStyle(gardenMode == mode ? .white : Theme.deep.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background {
                        if gardenMode == mode {
                            Capsule().fill(modeColor(mode))
                        } else {
                            Capsule().fill(.ultraThinMaterial)
                        }
                    }
                    .overlay(
                        Capsule()
                            .stroke(gardenMode == mode ? modeColor(mode).opacity(0.8) : .white.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
    }

    private func modeColor(_ mode: GardenMode) -> Color {
        switch mode {
        case .view: return Theme.sage
        case .plant: return Theme.softPeach
        case .water: return Theme.softSky
        case .remove: return Theme.dustyRose
        }
    }

    private var modeHint: some View {
        HStack(spacing: 6) {
            Image(systemName: "hand.tap.fill")
                .font(Theme.caption2Font)
            Text(modeHintText)
                .font(Theme.captionFont)
                .fontWeight(.medium)
        }
        .foregroundStyle(modeColor(gardenMode))
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
        .overlay(
            Capsule()
                .stroke(modeColor(gardenMode).opacity(0.4), lineWidth: 1)
        )
    }

    private var modeHintText: String {
        switch gardenMode {
        case .view: return "Tap a plant to view details"
        case .plant: return "Tap an empty plot to plant a seed"
        case .water: return "Tap a plant to water it"
        case .remove: return "Tap a plant to remove it"
        }
    }

    private func gardenStatPill(count: Int, label: String, emoji: String) -> some View {
        HStack(spacing: 4) {
            Text(emoji)
                .font(Theme.font(10))
            Text("\(count)")
                .font(Theme.captionFont)
                .fontWeight(.heavy)
                .foregroundStyle(Theme.deep)
            Text(label)
                .font(Theme.font(9))
                .foregroundStyle(Theme.deep.opacity(0.4))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
        )
        .overlay(
            Capsule()
                .stroke(.white.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Garden Plots

    private func gardenPlots(width: CGFloat) -> some View {
        let plotWidth: CGFloat = (width - 72) / CGFloat(columns)
        let rows = (totalSlots + columns - 1) / columns

        return VStack(spacing: 10) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(0..<columns, id: \.self) { col in
                        let index = row * columns + col
                        if index < totalSlots {
                            gardenPlotCell(at: index, size: plotWidth)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func gardenPlotCell(at index: Int, size: CGFloat) -> some View {
        let plant = plants.first { $0.gridIndex == index }
        let isRemoving = removingPlantIndex == index

        return ZStack {
            plotBackground(size: size, hasPlant: plant != nil)

            if let plant = plant {
                ZStack {
                    PlantView(plant: plant, isNew: newPlantIndex == index)

                    if wateredPlantIndex == index {
                        waterDropAnimation
                    }

                    if gardenMode == .water && plant.stage != .bloom {
                        Circle()
                            .stroke(Theme.softSky.opacity(0.5), lineWidth: 1.5)
                            .frame(width: 36, height: 36)
                            .scaleEffect(sparklePhase ? 1.05 : 0.95)
                    }

                    if gardenMode == .remove {
                        VStack {
                            HStack {
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(Theme.dustyRose)
                                        .frame(width: 18, height: 18)
                                    Image(systemName: "xmark")
                                        .font(Theme.fontBold(8))
                                        .foregroundStyle(.white)
                                }
                                .offset(x: 2, y: -2)
                            }
                            Spacer()
                        }
                        .frame(width: size - 12, height: size * 0.62 - 12)
                    }
                }
                .scaleEffect(isRemoving ? 0.01 : 1.0)
                .opacity(isRemoving ? 0 : 1)
                .onTapGesture {
                    handlePlotTap(index: index, plant: plant)
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                emptyPlotContent(size: size)
                    .onTapGesture {
                        handlePlotTap(index: index, plant: nil)
                    }
            }
        }
        .frame(width: size, height: size * 0.62)
    }

    private func plotBackground(size: CGFloat, hasPlant: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(outlineColor.opacity(0.12), lineWidth: 0.8)
                )

            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.78, green: 0.70, blue: 0.58).opacity(0.3),
                                Color(red: 0.72, green: 0.64, blue: 0.52).opacity(0.4),
                                Color(red: 0.68, green: 0.60, blue: 0.48).opacity(0.35)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                soilDetails(size: size)

                VStack {
                    Spacer()
                    HStack(spacing: 0) {
                        ForEach(0..<Int(size / 6), id: \.self) { i in
                            let h = CGFloat.random(in: 3...7)
                            let hue = Double.random(in: 0.25...0.35)
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color(hue: hue, saturation: 0.3, brightness: 0.72).opacity(0.5))
                                .frame(width: 1.5, height: h)
                                .rotationEffect(.degrees(Double.random(in: -15...15)))
                                .offset(x: CGFloat.random(in: -1...1))
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 2)
                }

                if hasPlant {
                    VStack {
                        Spacer()
                        Ellipse()
                            .fill(Color(red: 0.65, green: 0.56, blue: 0.44).opacity(0.2))
                            .frame(width: size * 0.5, height: 6)
                            .offset(y: -4)
                    }
                }
            }
            .padding(4)
            .clipShape(RoundedRectangle(cornerRadius: 9))
        }
    }

    private func soilDetails(size: CGFloat) -> some View {
        ZStack {
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(Color(red: 0.70, green: 0.62, blue: 0.52).opacity(0.15))
                    .frame(width: CGFloat.random(in: 3...6), height: CGFloat.random(in: 3...6))
                    .offset(
                        x: CGFloat([-15, 12, -8, 18][i]),
                        y: CGFloat([8, -5, 14, 10][i])
                    )
            }

            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(Color(red: 0.65, green: 0.58, blue: 0.48).opacity(0.12))
                    .frame(width: CGFloat.random(in: 8...14), height: 1)
                    .offset(
                        x: CGFloat([-10, 6, -3][i]),
                        y: CGFloat([4, 12, -2][i])
                    )
            }
        }
    }

    private func emptyPlotContent(size: CGFloat) -> some View {
        VStack(spacing: 2) {
            if gardenMode == .plant && resource.seeds > 0 {
                ZStack {
                    Circle()
                        .fill(Theme.softPeach.opacity(0.2))
                        .frame(width: 28, height: 28)
                    Image(systemName: "leaf.arrow.circlepath")
                        .font(Theme.font(12))
                        .foregroundStyle(Theme.softPeach.opacity(0.8))
                        .symbolEffect(.pulse, options: .repeating)
                }
            } else {
                ZStack {
                    Circle()
                        .stroke(outlineColor.opacity(0.08), lineWidth: 0.8)
                        .frame(width: 20, height: 20)
                    Image(systemName: "plus")
                        .font(Theme.font(8))
                        .foregroundStyle(Theme.deep.opacity(0.15))
                }
            }
        }
    }

    private var waterDropAnimation: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .fill(Theme.softSky.opacity(0.7))
                    .frame(width: 3, height: 3)
                    .offset(x: CGFloat([-6, 5, -2, 7, 0][i]), y: -16)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
            Image(systemName: "drop.fill")
                .font(Theme.font(13))
                .foregroundStyle(Theme.softSky)
                .offset(y: -22)
                .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Tap Handling

    private func handlePlotTap(index: Int, plant: GardenPlant?) {
        switch gardenMode {
        case .view:
            if let plant {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                selectedPlant = plant
                showingPlantDetail = true
            }
        case .plant:
            if plant == nil {
                plantSeedAt(index: index)
            }
        case .water:
            if let plant, plant.stage != .bloom {
                waterPlantAt(index: index, plant: plant)
            }
        case .remove:
            if let plant {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                plantToRemove = plant
                showRemoveConfirm = true
            }
        }
    }

    private func plantSeedAt(index: Int) {
        guard resource.spendSeed() else {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            return
        }

        let plantType = randomPlantType()
        let newPlant = GardenPlant(
            plantType: plantType.rawValue,
            growthStage: 0,
            gridIndex: index,
            sourceDescription: "Planted with earned seed"
        )

        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            modelContext.insert(newPlant)
            newPlantIndex = index
            seedBounce = true
        }

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            seedBounce = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            newPlantIndex = nil
        }
    }

    private func waterPlantAt(index: Int, plant: GardenPlant) {
        guard resource.spendWater() else {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
            return
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            wateredPlantIndex = index
            waterBounce = true
        }

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            waterBounce = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                plant.growthStage = min(plant.growthStage + 1, 2)
                plant.lastWateredDate = .now
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation {
                wateredPlantIndex = nil
            }
        }
    }

    private func randomPlantType() -> PlantType {
        let types: [PlantType] = [.daisy, .tulip, .rose, .sunflower, .lavender, .succulent]
        return types.randomElement() ?? .daisy
    }

    // MARK: - Legend

    private var gardenLegend: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "book.closed.fill")
                    .font(Theme.caption2Font)
                    .foregroundStyle(Theme.deep.opacity(0.3))
                Text("HOW YOUR GARDEN GROWS")
                    .font(Theme.captionFont)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.deep.opacity(0.35))
                    .tracking(1.2)
            }

            VStack(spacing: 0) {
                legendRow(icon: "checkmark.circle.fill", color: Theme.gold, text: "Complete to-dos to earn seeds")
                Divider().padding(.leading, 44).opacity(0.3)
                legendRow(icon: "sparkle", color: Theme.dustyRose, text: "Complete micro actions to earn water")
                Divider().padding(.leading, 44).opacity(0.3)
                legendRow(icon: "leaf.arrow.circlepath", color: Theme.softPeach, text: "Use seeds to plant in empty plots")
                Divider().padding(.leading, 44).opacity(0.3)
                legendRow(icon: "drop.fill", color: Theme.softSky, text: "Use water to grow your plants")
                Divider().padding(.leading, 44).opacity(0.3)
                legendRow(icon: "scissors", color: Theme.dustyRose, text: "Remove plants to free up plots")
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.3), lineWidth: 1))
            )
        }
    }

    private func legendRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(Theme.captionFont)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(text)
                .font(Theme.captionFont)
                .foregroundStyle(Theme.deep.opacity(0.55))
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - Shapes

struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: 0, y: h / 2))
        path.addQuadCurve(to: CGPoint(x: w, y: h / 2), control: CGPoint(x: w * 0.5, y: 0))
        path.addQuadCurve(to: CGPoint(x: 0, y: h / 2), control: CGPoint(x: w * 0.5, y: h))
        return path
    }
}

// MARK: - Plant View

struct PlantView: View {
    let plant: GardenPlant
    var isNew: Bool = false

    @State private var appeared: Bool = false
    @State private var swaying: Bool = false

    private let outlineColor = Color(red: 0.62, green: 0.58, blue: 0.52)

    var body: some View {
        ZStack {
            switch plant.stage {
            case .seed:
                seedView
            case .sprout:
                sproutView
            case .bloom:
                bloomView
            }
        }
        .opacity(plant.isWilted ? 0.5 : 1.0)
        .rotationEffect(.degrees(plant.isWilted ? -8 : (swaying ? 1.5 : -1.5)))
        .scaleEffect(appeared ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.6), value: appeared)
        .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: swaying)
        .onAppear {
            withAnimation {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                swaying = true
            }
        }
    }

    private let pastelStem = Color(red: 0.72, green: 0.82, blue: 0.68)
    private let pastelLeaf = Color(red: 0.78, green: 0.88, blue: 0.74)
    private let pastelLeafDark = Color(red: 0.70, green: 0.80, blue: 0.66)

    private var seedView: some View {
        ZStack {
            Ellipse()
                .fill(Color(red: 0.82, green: 0.76, blue: 0.70).opacity(0.25))
                .frame(width: 18, height: 7)
                .offset(y: 10)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.85, green: 0.78, blue: 0.70), Color(red: 0.76, green: 0.68, blue: 0.60)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 6
                    )
                )
                .frame(width: 10, height: 10)
                .overlay(Circle().stroke(outlineColor.opacity(0.25), lineWidth: 0.8))
                .offset(y: 3)

            Path { path in
                path.move(to: CGPoint(x: 0, y: 3))
                path.addQuadCurve(to: CGPoint(x: 4, y: -4), control: CGPoint(x: 5, y: 0))
            }
            .stroke(pastelLeaf, lineWidth: 1.2)
            .frame(width: 10, height: 10)
        }
        .frame(width: 40, height: 40)
    }

    private var sproutView: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 20, y: 34))
                path.addQuadCurve(to: CGPoint(x: 20, y: 8), control: CGPoint(x: 18, y: 21))
            }
            .stroke(pastelStem, lineWidth: 2)
            .frame(width: 40, height: 40)

            LeafShape()
                .fill(pastelLeaf)
                .frame(width: 12, height: 7)
                .overlay(LeafShape().stroke(outlineColor.opacity(0.18), lineWidth: 0.6))
                .rotationEffect(.degrees(-30))
                .offset(x: -6, y: -3)

            LeafShape()
                .fill(pastelLeafDark)
                .frame(width: 12, height: 7)
                .overlay(LeafShape().stroke(outlineColor.opacity(0.18), lineWidth: 0.6))
                .rotationEffect(.degrees(30))
                .scaleEffect(x: -1)
                .offset(x: 6, y: 1)
        }
        .frame(width: 40, height: 40)
    }

    private var bloomView: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 22, y: 38))
                path.addQuadCurve(to: CGPoint(x: 22, y: 10), control: CGPoint(x: 19, y: 24))
            }
            .stroke(pastelStem, lineWidth: 2)
            .frame(width: 44, height: 44)

            LeafShape()
                .fill(pastelLeaf)
                .frame(width: 10, height: 6)
                .overlay(LeafShape().stroke(outlineColor.opacity(0.18), lineWidth: 0.5))
                .rotationEffect(.degrees(-35))
                .offset(x: -6, y: 6)

            LeafShape()
                .fill(pastelLeafDark)
                .frame(width: 10, height: 6)
                .overlay(LeafShape().stroke(outlineColor.opacity(0.18), lineWidth: 0.5))
                .rotationEffect(.degrees(35))
                .scaleEffect(x: -1)
                .offset(x: 6, y: 9)

            flowerHead
                .offset(y: -10)
        }
        .frame(width: 44, height: 44)
    }

    private var flowerHead: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                Ellipse()
                    .fill(plant.type.petalColor)
                    .frame(width: 8, height: 11)
                    .overlay(Ellipse().stroke(outlineColor.opacity(0.12), lineWidth: 0.5))
                    .offset(y: -6)
                    .rotationEffect(.degrees(Double(i) * 60))
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 1.0, green: 0.96, blue: 0.85), Color(red: 0.95, green: 0.88, blue: 0.72)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 5
                    )
                )
                .frame(width: 8, height: 8)
                .overlay(Circle().stroke(outlineColor.opacity(0.12), lineWidth: 0.4))
        }
    }
}

// MARK: - Plant Detail Sheet

struct PlantDetailSheet: View {
    let plant: GardenPlant
    var onRemove: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 16) {
                PlantView(plant: plant)
                    .frame(width: 60, height: 60)
                    .scaleEffect(1.1)

                VStack(alignment: .leading, spacing: 4) {
                    Text(plant.type.label)
                        .font(Theme.title3Font)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.deep)

                    Text(plant.stage.label)
                        .font(Theme.captionFont)
                        .fontWeight(.medium)
                        .foregroundStyle(plant.type.petalColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(plant.type.petalColor.opacity(0.15))
                        )
                }
                Spacer()
            }
            .padding(.horizontal, 24)

            VStack(alignment: .leading, spacing: 8) {
                detailRow(label: "Origin", value: plant.sourceDescription)
                detailRow(label: "Planted", value: plant.createdDate.formatted(date: .abbreviated, time: .omitted))
                if plant.stage == .bloom {
                    detailRow(label: "Status", value: "Fully bloomed! ✨")
                } else {
                    detailRow(label: "Next", value: "Water to grow to \(plant.stage == .seed ? "sprout" : "bloom")")
                }
            }
            .padding(.horizontal, 24)

            if plant.stage == .bloom {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Theme.gold)
                    Text("Fully bloomed!")
                        .font(Theme.subheadlineFont)
                        .fontWeight(.medium)
                        .foregroundStyle(Theme.deep.opacity(0.6))
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "drop.fill")
                        .foregroundStyle(Theme.softSky)
                    Text("Use water tab to grow this plant")
                        .font(Theme.subheadlineFont)
                        .foregroundStyle(Theme.deep.opacity(0.5))
                }
            }

            Button {
                onRemove?()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                        .font(Theme.captionFont)
                    Text("Remove Plant")
                        .font(Theme.subheadlineFont)
                        .fontWeight(.medium)
                }
                .foregroundStyle(Theme.dustyRose)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Theme.dustyRose.opacity(0.1))
                )
                .overlay(
                    Capsule()
                        .stroke(Theme.dustyRose.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding(.top, 20)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(Theme.captionFont)
                .foregroundStyle(Theme.deep.opacity(0.4))
                .frame(width: 60, alignment: .leading)
            Text(value)
                .font(Theme.subheadlineFont)
                .foregroundStyle(Theme.deep.opacity(0.7))
            Spacer()
        }
    }
}

// MARK: - Garden Preview

struct GardenPreviewView: View {
    let plants: [GardenPlant]
    let resources: [GardenResource]

    private var resource: GardenResource? {
        resources.first
    }

    private let outlineColor = Color(red: 0.62, green: 0.58, blue: 0.52)

    var body: some View {
        ZStack {
            gardenPreviewBackground
                .frame(height: 220)
                .clipped()

            if plants.isEmpty {
                emptyGardenPrompt
            } else {
                plantPreview
            }

            VStack {
                HStack {
                    Spacer()
                    HStack(spacing: 10) {
                        HStack(spacing: 3) {
                            Image(systemName: "leaf.arrow.circlepath")
                                .font(Theme.font(10))
                            Text("\(resource?.seeds ?? 0)")
                                .font(Theme.caption2Font)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(Theme.softPeach)

                        HStack(spacing: 3) {
                            Image(systemName: "drop.fill")
                                .font(Theme.font(10))
                            Text("\(resource?.waterCans ?? 0)")
                                .font(Theme.caption2Font)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(Theme.softSky)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(.ultraThinMaterial))
                    .overlay(Capsule().stroke(outlineColor.opacity(0.12), lineWidth: 0.8))
                }
                .padding(16)
                Spacer()
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    HStack(spacing: 5) {
                        Text("Enter Garden")
                            .font(Theme.caption2Font)
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                            .font(Theme.caption2Font)
                    }
                    .foregroundStyle(Theme.deep.opacity(0.6))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(.ultraThinMaterial)
                    )
                    .overlay(Capsule().stroke(outlineColor.opacity(0.12), lineWidth: 0.8))
                }
                .padding(16)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 0))
    }

    private static let gardenPreviewBgURL = URL(string: "https://pub-e001eb4506b145aa938b5d3badbff6a5.r2.dev/attachments/xicu08bf8gc7cgml2q1zt")

    private var gardenPreviewBackground: some View {
        AsyncImage(url: Self.gardenPreviewBgURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            default:
                Color(red: 0.85, green: 0.92, blue: 0.80)
            }
        }
    }

    private var emptyGardenPrompt: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 64, height: 64)

                Image(systemName: "leaf.fill")
                    .font(Theme.font(28))
                    .foregroundStyle(Theme.sage)
                    .symbolEffect(.pulse, options: .repeating)
            }

            Text("Start Your Garden")
                .font(Theme.subheadlineFont)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.deep)

            Text("Complete tasks to earn seeds & water")
                .font(Theme.caption2Font)
                .foregroundStyle(Theme.deep.opacity(0.45))
        }
        .offset(y: -15)
    }

    private var plantPreview: some View {
        HStack(spacing: 16) {
            ForEach(Array(plants.prefix(5)), id: \.gridIndex) { plant in
                PlantView(plant: plant)
                    .frame(width: 50, height: 50)
            }
        }
        .offset(y: 20)
    }
}
