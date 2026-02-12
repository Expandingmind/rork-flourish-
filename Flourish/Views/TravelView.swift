import SwiftUI
import SwiftData

struct TravelView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TravelDestination.name) private var destinations: [TravelDestination]
    @State private var showingAddDestination: Bool = false
    @State private var expandedCardId: PersistentIdentifier? = nil
    @State private var appearAnimated: Bool = false
    @State private var showCelebration: Bool = false
    @State private var newlyStampedId: PersistentIdentifier? = nil
    @State private var stampAnimationPhase: StampAnimationPhase = .idle
    @State private var currentPage: Int = 0
    @State private var pageFlipDirection: Int = 0
    @Namespace private var stampNamespace

    private let stampsPerPage: Int = 9

    private var visitedDestinations: [TravelDestination] {
        destinations.filter { $0.isVisited }
    }

    private var unvisitedDestinations: [TravelDestination] {
        destinations.filter { !$0.isVisited }
    }

    private let passColors: [Color] = [
        Theme.dustyRose,
        Theme.softLavender,
        Theme.softPeach,
        Theme.softPink,
        Theme.softSky,
        Theme.softMint,
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    clipboardSection

                    if !unvisitedDestinations.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Text("UPCOMING ADVENTURES")
                                    .font(Theme.fontBold(11))
                                    .foregroundStyle(Theme.accent.opacity(0.7))
                                    .tracking(1.5)
                                    .padding(.leading, 4)
                                Spacer()
                            }

                            walletStack
                        }
                    }

                    if destinations.isEmpty {
                        emptyState
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 140)
            }
            .flowerBackground(seed: 4)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Your journey starts here")
                        .font(Theme.headlineFont)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.deep)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddDestination = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(Theme.title3Font)
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
            .celebration(
                isShowing: $showCelebration,
                message: "Destination unlocked!",
                subtitle: "The world is yours to explore.",
                style: .confetti,
                duration: 3.0
            )
            .sheet(isPresented: $showingAddDestination) {
                AddDestinationSheet { name, country, budget, date in
                    let colorIdx = Int.random(in: 0..<passColors.count)
                    let dest = TravelDestination(name: name, country: country, estimatedBudget: budget, targetDate: date, colorIndex: colorIdx)
                    modelContext.insert(dest)
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                    appearAnimated = true
                }
            }
        }
    }

    // MARK: - Clipboard

    private var totalPages: Int {
        guard !visitedDestinations.isEmpty else { return 1 }
        return max(1, Int(ceil(Double(visitedDestinations.count) / Double(stampsPerPage))))
    }

    private func stampsForPage(_ page: Int) -> [TravelDestination] {
        let start = page * stampsPerPage
        let end = min(start + stampsPerPage, visitedDestinations.count)
        guard start < visitedDestinations.count else { return [] }
        return Array(visitedDestinations[start..<end])
    }

    private var clipboardSection: some View {
        VStack(spacing: 0) {
            clipboardClip
                .zIndex(2)

            ZStack {
                clipboardBody

                VStack(spacing: 0) {
                    clipboardHeader

                    if visitedDestinations.isEmpty {
                        emptyClipboardContent
                            .padding(.top, 16)
                    } else {
                        VStack(spacing: 8) {
                            stampPage(for: currentPage)
                                .id(currentPage)
                                .transition(.asymmetric(
                                    insertion: .move(edge: pageFlipDirection >= 0 ? .trailing : .leading).combined(with: .opacity),
                                    removal: .move(edge: pageFlipDirection >= 0 ? .leading : .trailing).combined(with: .opacity)
                                ))
                                .animation(.spring(response: 0.5, dampingFraction: 0.75), value: currentPage)

                            if totalPages > 1 {
                                pageControls
                            }
                        }
                        .padding(.top, 8)
                    }

                    Spacer(minLength: 14)
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
            }
            .offset(y: -10)
        }
        .opacity(appearAnimated ? 1 : 0)
        .offset(y: appearAnimated ? 0 : -20)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.05), value: appearAnimated)
        .onChange(of: visitedDestinations.count) { oldCount, newCount in
            if newCount > oldCount {
                let newLastPage = max(0, Int(ceil(Double(newCount) / Double(stampsPerPage))) - 1)
                if newLastPage != currentPage {
                    pageFlipDirection = 1
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                        currentPage = newLastPage
                    }
                }
            }
        }
    }

    private func stampPage(for page: Int) -> some View {
        let pageStamps = stampsForPage(page)
        let columns = [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10),
        ]

        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Array(pageStamps.enumerated()), id: \.element.id) { index, destination in
                let stampColor = passColors[destination.colorIndex % passColors.count]
                let overallIndex = page * stampsPerPage + index
                let useRect = overallIndex % 3 == 1

                TravelStampView(
                    destination: destination,
                    color: stampColor,
                    isNewlyStamped: newlyStampedId == destination.persistentModelID,
                    isRectangle: useRect,
                    onUnmark: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            destination.isVisited = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            if currentPage >= totalPages {
                                pageFlipDirection = -1
                                withAnimation { currentPage = max(0, totalPages - 1) }
                            }
                        }
                    }
                )
                .transition(
                    .asymmetric(
                        insertion: .stampInsertion,
                        removal: .scale(scale: 0.5).combined(with: .opacity)
                    )
                )
            }
        }
    }

    private var pageControls: some View {
        HStack(spacing: 14) {
            Button {
                pageFlipDirection = -1
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                    currentPage = max(0, currentPage - 1)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(Theme.fontBold(11))
                    .foregroundStyle(currentPage > 0 ? Theme.accent : Theme.deep.opacity(0.2))
            }
            .disabled(currentPage == 0)

            HStack(spacing: 5) {
                ForEach(0..<totalPages, id: \.self) { page in
                    Circle()
                        .fill(page == currentPage ? Theme.accent : Theme.deep.opacity(0.15))
                        .frame(width: 6, height: 6)
                        .scaleEffect(page == currentPage ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3), value: currentPage)
                }
            }

            Button {
                pageFlipDirection = 1
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                    currentPage = min(totalPages - 1, currentPage + 1)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(Theme.fontBold(11))
                    .foregroundStyle(currentPage < totalPages - 1 ? Theme.accent : Theme.deep.opacity(0.2))
            }
            .disabled(currentPage >= totalPages - 1)
        }
        .padding(.top, 4)
    }

    private var clipboardClip: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.72, green: 0.62, blue: 0.55),
                            Color(red: 0.58, green: 0.48, blue: 0.42),
                            Color(red: 0.72, green: 0.62, blue: 0.55),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 80, height: 28)
                .shadow(color: .black.opacity(0.15), radius: 2, y: 2)

            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.78, green: 0.68, blue: 0.60),
                            Color(red: 0.65, green: 0.55, blue: 0.48),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 72, height: 22)

            RoundedRectangle(cornerRadius: 3)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                .frame(width: 72, height: 22)
        }
    }

    private var clipboardHeader: some View {
        VStack(spacing: 6) {
            HStack {
                washiTapeDecoration(color: Theme.softPink.opacity(0.6), width: 50)
                Spacer()
                washiTapeDecoration(color: Theme.softLavender.opacity(0.5), width: 40)
            }
            .padding(.horizontal, -6)
            .offset(y: -4)

            Text("TRAVEL LOG")
                .font(Theme.fontBold(13))
                .foregroundStyle(Theme.dustyRose.opacity(0.5))
                .tracking(3)

            HStack(spacing: 6) {
                dottedLine
                Image(systemName: "globe.europe.africa.fill")
                    .font(Theme.font(8))
                    .foregroundStyle(Theme.dustyRose.opacity(0.25))
                dottedLine
            }
            .padding(.horizontal, 20)

            if !visitedDestinations.isEmpty {
                Text("\(visitedDestinations.count) place\(visitedDestinations.count == 1 ? "" : "s") explored")
                    .font(Theme.font(10))
                    .foregroundStyle(Theme.deep.opacity(0.25))
            }
        }
    }

    private var dottedLine: some View {
        GeometryReader { geo in
            Path { path in
                var x: CGFloat = 0
                while x < geo.size.width {
                    path.move(to: CGPoint(x: x, y: geo.size.height / 2))
                    path.addLine(to: CGPoint(x: min(x + 3, geo.size.width), y: geo.size.height / 2))
                    x += 6
                }
            }
            .stroke(Theme.dustyRose.opacity(0.15), lineWidth: 0.8)
        }
        .frame(height: 2)
    }

    private func washiTapeDecoration(color: Color, width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: width, height: 12)
            .rotationEffect(.degrees(-3))
            .overlay {
                HStack(spacing: 3) {
                    ForEach(0..<Int(width / 8), id: \.self) { _ in
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 2, height: 2)
                    }
                }
            }
    }

    private var emptyClipboardContent: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.softPink.opacity(0.15))
                    .frame(width: 64, height: 64)

                Image(systemName: "airplane.departure")
                    .font(Theme.font(26))
                    .foregroundStyle(Theme.dustyRose.opacity(0.45))
            }

            VStack(spacing: 6) {
                Text("Start Your Collection")
                    .font(Theme.fontBold(15))
                    .foregroundStyle(Theme.deep.opacity(0.5))

                Text("Add a destination and mark it visited\nto earn your first travel stamp!")
                    .font(Theme.font(11))
                    .foregroundStyle(Theme.deep.opacity(0.3))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            Button {
                showingAddDestination = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(Theme.fontBold(11))
                    Text("Add First Destination")
                        .font(Theme.fontBold(12))
                }
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background {
                    Capsule()
                        .strokeBorder(Theme.accent.opacity(0.4), style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                        .background(Capsule().fill(Theme.accent.opacity(0.06)))
                }
            }

            HStack(spacing: 16) {
                stampPlaceholder
                stampPlaceholder
                stampPlaceholder
            }
            .padding(.top, 4)
        }
    }

    private var stampPlaceholder: some View {
        Circle()
            .strokeBorder(Theme.dustyRose.opacity(0.1), style: StrokeStyle(lineWidth: 1.2, dash: [3, 2]))
            .frame(width: 40, height: 40)
            .overlay {
                Image(systemName: "questionmark")
                    .font(Theme.font(12))
                    .foregroundStyle(Theme.dustyRose.opacity(0.15))
            }
    }

    private var clipboardBody: some View {
        VStack {
            Spacer().frame(height: 0)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: visitedDestinations.isEmpty ? 300 : 340)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.98, green: 0.96, blue: 0.93))

                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.clear,
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )

                VStack(spacing: 18) {
                    ForEach(0..<18, id: \.self) { _ in
                        Rectangle()
                            .fill(Theme.dustyRose.opacity(0.05))
                            .frame(height: 0.5)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        cornerDoodle
                            .padding(16)
                    }
                }

                VStack {
                    HStack {
                        cornerDoodleTopLeft
                            .padding(16)
                        Spacer()
                    }
                    Spacer()
                }

                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Theme.dustyRose.opacity(0.15), lineWidth: 1)
            }
        }
        .shadow(color: Theme.deep.opacity(0.06), radius: 8, y: 4)
    }

    private var cornerDoodle: some View {
        ZStack {
            Image(systemName: "sparkle")
                .font(Theme.font(8))
                .foregroundStyle(Theme.dustyRose.opacity(0.12))
                .offset(x: -6, y: -4)
            Image(systemName: "sparkle")
                .font(Theme.font(5))
                .foregroundStyle(Theme.gold.opacity(0.12))
                .offset(x: 4, y: 2)
            Image(systemName: "heart.fill")
                .font(Theme.font(6))
                .foregroundStyle(Theme.blush.opacity(0.1))
                .offset(x: -2, y: 6)
        }
    }

    private var cornerDoodleTopLeft: some View {
        ZStack {
            Image(systemName: "star.fill")
                .font(Theme.font(6))
                .foregroundStyle(Theme.gold.opacity(0.1))
                .offset(x: 2, y: 4)
            Image(systemName: "airplane")
                .font(Theme.font(7))
                .foregroundStyle(Theme.dustyRose.opacity(0.1))
                .rotationEffect(.degrees(30))
                .offset(x: 10, y: -2)
        }
    }



    // MARK: - Empty State

    private var emptyState: some View {
        EmptyView()
    }

    // MARK: - Wallet Stack

    private var walletStack: some View {
        let hasExpanded = expandedCardId != nil
        let expandedIndex = unvisitedDestinations.firstIndex(where: { $0.persistentModelID == expandedCardId })

        return ZStack(alignment: .top) {
            ForEach(Array(unvisitedDestinations.enumerated()), id: \.element.id) { index, destination in
                let isExpanded = expandedCardId == destination.persistentModelID
                let cardColor = passColors[destination.colorIndex % passColors.count]

                BoardingPassCard(
                    destination: destination,
                    color: cardColor,
                    isExpanded: isExpanded,
                    onDelete: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                            if expandedCardId == destination.persistentModelID {
                                expandedCardId = nil
                            }
                            modelContext.delete(destination)
                        }
                    },
                    onToggleVisited: {
                        let destId = destination.persistentModelID
                        if expandedCardId == destId {
                            expandedCardId = nil
                        }
                        newlyStampedId = destId
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                            destination.isVisited = true
                        }
                        let generator = UIImpactFeedbackGenerator(style: .heavy)
                        generator.impactOccurred()

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            let stampGenerator = UIImpactFeedbackGenerator(style: .rigid)
                            stampGenerator.impactOccurred()
                        }

                        showCelebration = true

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                newlyStampedId = nil
                            }
                        }
                    }
                )
                .zIndex(cardZIndex(index: index, expandedIndex: expandedIndex, total: unvisitedDestinations.count))
                .offset(y: rolodexOffset(index: index, expandedIndex: expandedIndex, hasExpanded: hasExpanded))
                .rotation3DEffect(
                    .degrees(rolodexRotation(index: index, expandedIndex: expandedIndex, hasExpanded: hasExpanded)),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .top,
                    perspective: 0.4
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                        if expandedCardId == destination.persistentModelID {
                            expandedCardId = nil
                        } else {
                            expandedCardId = destination.persistentModelID
                        }
                    }
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 0.3).combined(with: .opacity).combined(with: .move(edge: .top))
                ))
                .opacity(appearAnimated ? 1 : 0)
                .offset(y: appearAnimated ? 0 : 30)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.08), value: appearAnimated)
            }
        }
        .frame(height: walletStackHeight)
        .padding(.top, 8)
    }

    private var walletStackHeight: CGFloat {
        guard !unvisitedDestinations.isEmpty else { return 0 }
        if expandedCardId != nil {
            let ei = unvisitedDestinations.firstIndex(where: { $0.persistentModelID == expandedCardId }) ?? 0
            let cardsAbove = CGFloat(ei) * 28
            let cardsBelowCount = max(0, unvisitedDestinations.count - 1 - ei)
            let cardsBelow = CGFloat(cardsBelowCount) * 44
            return cardsAbove + 380 + cardsBelow + 20
        }
        let cardHeight: CGFloat = 180
        let peekAmount: CGFloat = 30
        return cardHeight + CGFloat(unvisitedDestinations.count - 1) * peekAmount + 20
    }

    private func rolodexOffset(index: Int, expandedIndex: Int?, hasExpanded: Bool) -> CGFloat {
        if !hasExpanded {
            return CGFloat(index) * 30
        }
        guard let ei = expandedIndex else { return CGFloat(index) * 30 }
        if index == ei {
            return CGFloat(ei) * 28
        } else if index < ei {
            return CGFloat(index) * 28
        } else {
            return CGFloat(ei) * 28 + 340 + CGFloat(index - ei) * 44
        }
    }

    private func rolodexRotation(index: Int, expandedIndex: Int?, hasExpanded: Bool) -> Double {
        if !hasExpanded {
            return Double(index) * -1.5
        }
        guard let ei = expandedIndex else { return 0 }
        if index == ei { return 0 }
        else if index < ei { return -8 }
        else { return 3 }
    }

    private func cardZIndex(index: Int, expandedIndex: Int?, total: Int) -> Double {
        guard let ei = expandedIndex else {
            return Double(total - index)
        }
        if index == ei { return 1000 }
        else if index < ei { return Double(index) }
        else { return Double(total - index) }
    }
}

// MARK: - Travel Stamp

struct TravelStampView: View {
    let destination: TravelDestination
    let color: Color
    let isNewlyStamped: Bool
    let isRectangle: Bool
    let onUnmark: () -> Void

    @State private var stampPressed: Bool = false
    @State private var showStampContent: Bool = false
    @State private var inkSpread: Bool = false

    private var stampRotation: Double {
        let hash = abs(destination.name.hashValue &+ 42)
        let rotations: [Double] = [-8, -4, -2, 3, 5, 7, -6, 2]
        return rotations[hash % rotations.count]
    }

    var body: some View {
        ZStack {
            stampBackground
            stampContent
        }
        .frame(height: isRectangle ? 68 : 68)
        .rotationEffect(.degrees(stampRotation))
        .scaleEffect(stampPressed ? 1.15 : 1.0)
        .opacity(showStampContent ? 1 : 0)
        .scaleEffect(showStampContent ? 1 : 0.3)
        .onAppear {
            if isNewlyStamped {
                performStampAnimation()
            } else {
                showStampContent = true
            }
        }
        .onChange(of: isNewlyStamped) { _, newValue in
            if newValue {
                performStampAnimation()
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                onUnmark()
            } label: {
                Label("Unmark Visit", systemImage: "arrow.uturn.backward")
            }
        }
    }

    private func performStampAnimation() {
        showStampContent = false
        stampPressed = false
        inkSpread = false

        withAnimation(.spring(response: 0.15, dampingFraction: 0.3)) {
            showStampContent = true
            stampPressed = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                stampPressed = false
                inkSpread = true
            }
        }
    }

    @ViewBuilder
    private var stampBackground: some View {
        let visible = inkSpread || !isNewlyStamped
        if isRectangle {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(color.opacity(visible ? 0.7 : 0), style: StrokeStyle(lineWidth: 2, dash: [4, 2]))
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(visible ? 0.08 : 0))
                )
                .overlay {
                    if visible {
                        VStack {
                            HStack {
                                Spacer()
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(color.opacity(0.15))
                                    .frame(width: 14, height: 3)
                                    .rotationEffect(.degrees(-20))
                                    .offset(x: -6, y: 6)
                            }
                            Spacer()
                            HStack {
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(color.opacity(0.12))
                                    .frame(width: 12, height: 3)
                                    .rotationEffect(.degrees(15))
                                    .offset(x: 6, y: -6)
                                Spacer()
                            }
                        }
                    }
                }
        } else {
            Circle()
                .strokeBorder(color.opacity(visible ? 0.7 : 0), style: StrokeStyle(lineWidth: 2, dash: [3, 1.5]))
                .background(
                    Circle()
                        .fill(color.opacity(visible ? 0.08 : 0))
                )
        }
    }

    private var stampContent: some View {
        VStack(spacing: isRectangle ? 2 : 1) {
            if isRectangle {
                HStack(spacing: 3) {
                    Image(systemName: "mappin.circle.fill")
                        .font(Theme.fontBold(8))
                        .foregroundStyle(color.opacity(0.7))
                    Text(destination.name.uppercased())
                        .font(Theme.fontBold(7))
                        .foregroundStyle(color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }

                if !destination.country.isEmpty {
                    Text(destination.country.uppercased())
                        .font(Theme.fontBold(6))
                        .foregroundStyle(color.opacity(0.6))
                        .tracking(1)
                        .lineLimit(1)
                }

                Rectangle()
                    .fill(color.opacity(0.2))
                    .frame(width: 30, height: 0.5)

                Text(visitedDateString)
                    .font(Theme.font(5.5))
                    .foregroundStyle(color.opacity(0.5))
            } else {
                Image(systemName: "airplane")
                    .font(Theme.fontBold(8))
                    .foregroundStyle(color.opacity(0.8))
                    .rotationEffect(.degrees(45))

                Text(destination.name.uppercased())
                    .font(Theme.fontBold(7))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                if !destination.country.isEmpty {
                    Text(destination.country.uppercased())
                        .font(Theme.fontBold(5.5))
                        .foregroundStyle(color.opacity(0.6))
                        .tracking(0.5)
                        .lineLimit(1)
                }

                Text(visitedDateString)
                    .font(Theme.font(5))
                    .foregroundStyle(color.opacity(0.5))

                HStack(spacing: 1.5) {
                    ForEach(0..<3, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(Theme.font(3))
                            .foregroundStyle(color.opacity(0.4))
                    }
                }
            }
        }
        .padding(.horizontal, 5)
    }

    private var visitedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd·MM·yy"
        return formatter.string(from: .now)
    }
}

// MARK: - Stamp Insertion Transition

extension AnyTransition {
    static var stampInsertion: AnyTransition {
        .modifier(
            active: StampInsertionModifier(progress: 0),
            identity: StampInsertionModifier(progress: 1)
        )
    }
}

struct StampInsertionModifier: ViewModifier, Animatable {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(scaleValue)
            .opacity(opacityValue)
            .offset(y: offsetValue)
            .rotationEffect(.degrees(rotationValue))
    }

    private var scaleValue: CGFloat {
        if progress < 0.5 {
            return 0.1 + progress * 3.0
        } else {
            let overshoot = 1.3
            let t = (progress - 0.5) * 2
            return overshoot - (overshoot - 1.0) * t
        }
    }

    private var opacityValue: Double {
        min(progress * 2.5, 1.0)
    }

    private var offsetValue: CGFloat {
        -40 * (1 - progress)
    }

    private var rotationValue: Double {
        -15 * (1 - progress)
    }
}

enum StampAnimationPhase {
    case idle
    case flying
    case stamping
    case done
}

// MARK: - Boarding Pass Card

struct BoardingPassCard: View {
    let destination: TravelDestination
    let color: Color
    let isExpanded: Bool
    let onDelete: () -> Void
    let onToggleVisited: () -> Void

    private var darkerColor: Color {
        color.opacity(0.85)
    }

    private var lighterColor: Color {
        Color(
            red: min(color.components.red + 0.08, 1),
            green: min(color.components.green + 0.08, 1),
            blue: min(color.components.blue + 0.08, 1)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("BOARDING PASS")
                        .font(Theme.fontBold(9))
                        .foregroundStyle(.white.opacity(0.6))
                        .tracking(2)
                    Text(destination.name.uppercased())
                        .font(Theme.fontBold(22))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "airplane")
                    .font(Theme.font(24))
                    .foregroundStyle(.white.opacity(0.8))
                    .rotationEffect(.degrees(45))
            }
            .padding(.horizontal, 22)
            .padding(.top, 20)
            .padding(.bottom, 14)

            tearLine

            HStack(spacing: 0) {
                passField(label: "DESTINATION", value: destination.country.isEmpty ? "TBD" : destination.country.uppercased())
                Spacer()
                passField(label: "DATE", value: dateString)
                Spacer()
                passField(label: "BUDGET", value: destination.estimatedBudget > 0 ? "$\(Int(destination.estimatedBudget))" : "—")
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 14)

            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }

            barcodeView
                .padding(.horizontal, 22)
                .padding(.bottom, 16)
                .padding(.top, isExpanded ? 4 : 8)
        }
        .background {
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [lighterColor, color, darkerColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 22)
                        .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: color.opacity(0.35), radius: isExpanded ? 20 : 10, y: isExpanded ? 10 : 5)
    }

    private var tearLine: some View {
        HStack(spacing: 0) {
            Circle()
                .fill(Color(red: 0.98, green: 0.96, blue: 0.93))
                .frame(width: 16, height: 16)
                .offset(x: -8)

            GeometryReader { geo in
                Path { path in
                    let dashWidth: CGFloat = 6
                    let dashGap: CGFloat = 4
                    var x: CGFloat = 0
                    while x < geo.size.width {
                        path.move(to: CGPoint(x: x, y: geo.size.height / 2))
                        path.addLine(to: CGPoint(x: min(x + dashWidth, geo.size.width), y: geo.size.height / 2))
                        x += dashWidth + dashGap
                    }
                }
                .stroke(.white.opacity(0.25), lineWidth: 1.5)
            }
            .frame(height: 2)

            Circle()
                .fill(Color(red: 0.98, green: 0.96, blue: 0.93))
                .frame(width: 16, height: 16)
                .offset(x: 8)
        }
    }

    private func passField(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(Theme.fontBold(9))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(1)
            Text(value)
                .font(Theme.fontBold(14))
                .foregroundStyle(.white)
                .lineLimit(1)
        }
    }

    private var dateString: String {
        if let date = destination.targetDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yy"
            return formatter.string(from: date).uppercased()
        }
        return "OPEN"
    }

    private var expandedContent: some View {
        VStack(spacing: 12) {
            Rectangle()
                .fill(.white.opacity(0.1))
                .frame(height: 1)
                .padding(.horizontal, 22)

            if destination.estimatedBudget > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Savings Progress")
                            .font(Theme.captionFont)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        Text("$\(Int(destination.savedAmount)) / $\(Int(destination.estimatedBudget))")
                            .font(Theme.captionFont)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(.white.opacity(0.2))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(.white.opacity(0.8))
                                .frame(width: geo.size.width * destination.progress)
                        }
                    }
                    .frame(height: 5)
                }
                .padding(.horizontal, 22)
            }

            HStack(spacing: 12) {
                Button {
                    onToggleVisited()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "stamp.fill")
                            .font(Theme.subheadlineFont)
                        Text("Stamp It!")
                            .font(Theme.captionFont)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.2), in: Capsule())
                }

                Spacer()

                Button {
                    onDelete()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(Theme.subheadlineFont)
                        Text("Remove")
                            .font(Theme.captionFont)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.1), in: Capsule())
                }
            }
            .padding(.horizontal, 22)

            if !destination.notes.isEmpty {
                Text(destination.notes)
                    .font(Theme.captionFont)
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 22)
            }
        }
        .padding(.vertical, 8)
    }

    private var barcodeView: some View {
        HStack(spacing: 1.5) {
            ForEach(0..<32, id: \.self) { i in
                let height: CGFloat = barcodeHeight(for: i)
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(.white.opacity(0.35))
                    .frame(width: i % 3 == 0 ? 3 : 2, height: height)
            }
        }
        .frame(height: 28)
        .frame(maxWidth: .infinity)
    }

    private func barcodeHeight(for index: Int) -> CGFloat {
        let nameHash = destination.name.hashValue
        let seed = abs(nameHash &+ index)
        let heights: [CGFloat] = [18, 24, 14, 28, 20, 12, 26, 16, 22, 30]
        return heights[seed % heights.count]
    }
}

private extension Color {
    var components: (red: Double, green: Double, blue: Double, opacity: Double) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var o: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &o)
        return (Double(r), Double(g), Double(b), Double(o))
    }
}

struct AddDestinationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var country: String = ""
    @State private var budget: String = ""
    @State private var hasDate: Bool = false
    @State private var targetDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: .now) ?? .now
    let onAdd: (String, String, Double, Date?) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Destination", text: $name)
                    TextField("Country", text: $country)
                } header: {
                    Text("Where")
                        .foregroundStyle(Theme.accent)
                }
                Section {
                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0", text: $budget)
                            .keyboardType(.numberPad)
                    }
                } header: {
                    Text("Estimated Budget")
                        .foregroundStyle(Theme.accent)
                }
                Section {
                    Toggle("Set target date", isOn: $hasDate)
                    if hasDate {
                        DatePicker("When", selection: $targetDate, displayedComponents: .date)
                    }
                } header: {
                    Text("Timeline")
                        .foregroundStyle(Theme.accent)
                }
            }
            .scrollContentBackground(.hidden)
            .background { Theme.pageBg }
            .navigationTitle("New Destination")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.beige, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let budgetVal = Double(budget) ?? 0
                        onAdd(name, country, budgetVal, hasDate ? targetDate : nil)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(name.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Theme.accent)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .tint(Theme.accent)
        }
        .presentationDetents([.medium, .large])
    }
}
