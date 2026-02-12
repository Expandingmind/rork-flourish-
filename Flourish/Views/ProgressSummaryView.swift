import SwiftUI
import SwiftData

struct ProgressSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var allActions: [DailyAction]
    @Query private var allEvidence: [EvidenceItem]
    @Query private var allBucketItems: [BucketListItem]
    @Query private var allDestinations: [TravelDestination]
    @Query(sort: \GardenPlant.createdDate) private var gardenPlants: [GardenPlant]

    @State private var selectedPeriod: SummaryPeriod = .week
    @State private var appearAnimation: Bool = false

    enum SummaryPeriod: String, CaseIterable {
        case week = "This Week"
        case month = "This Month"
    }

    private var periodStart: Date {
        let calendar = Calendar.current
        switch selectedPeriod {
        case .week:
            return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: .now)) ?? .now
        case .month:
            return calendar.date(from: calendar.dateComponents([.year, .month], from: .now)) ?? .now
        }
    }

    private var actionsThisPeriod: [DailyAction] {
        allActions.filter { $0.createdDate >= periodStart }
    }

    private var completedActions: Int {
        actionsThisPeriod.filter(\.isCompleted).count
    }

    private var evidenceThisPeriod: [EvidenceItem] {
        allEvidence.filter { $0.date >= periodStart }
    }

    private var savedThisPeriod: Double {
        evidenceThisPeriod.filter { $0.category == "saving" }.reduce(0) { $0 + $1.amount }
    }

    private var winsThisPeriod: Int {
        evidenceThisPeriod.filter { $0.category == "win" }.count
    }

    private var milestonesThisPeriod: Int {
        evidenceThisPeriod.filter { $0.category == "milestone" }.count
    }

    private var bucketCompletedThisPeriod: Int {
        allBucketItems.filter { $0.isCompleted && ($0.completedDate ?? .distantPast) >= periodStart }.count
    }

    private var plantsGrownThisPeriod: Int {
        gardenPlants.filter { $0.createdDate >= periodStart }.count
    }

    private var activeDays: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(actionsThisPeriod.map { calendar.startOfDay(for: $0.createdDate) })
        return uniqueDays.count
    }

    private var totalDaysInPeriod: Int {
        let calendar = Calendar.current
        let now = Date.now
        let components = calendar.dateComponents([.day], from: periodStart, to: now)
        return max((components.day ?? 0) + 1, 1)
    }

    private var consistencyPercent: Int {
        let total = totalDaysInPeriod
        guard total > 0 else { return 0 }
        return min(Int((Double(activeDays) / Double(total)) * 100), 100)
    }

    private var topCategory: String {
        let categories = actionsThisPeriod.map(\.category)
        let counts = Dictionary(grouping: categories, by: { $0 }).mapValues(\.count)
        let top = counts.max(by: { $0.value < $1.value })
        return top?.key.capitalized ?? "None yet"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    periodPicker
                        .padding(.top, 8)

                    overviewCard

                    evidenceBreakdown

                    consistencyCard

                    insightsCard

                    if !evidenceThisPeriod.isEmpty {
                        recentHighlights
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background {
                ZStack {
                    Theme.beige.ignoresSafeArea()
                    BackgroundFlowerScatter(seed: 9)
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Theme.deep.opacity(0.3))
                    }
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    appearAnimation = true
                }
            }
        }
    }

    private var periodPicker: some View {
        HStack(spacing: 0) {
            ForEach(SummaryPeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedPeriod = period
                    }
                } label: {
                    Text(period.rawValue)
                        .font(Theme.fontBold(15))
                        .foregroundStyle(selectedPeriod == period ? .white : Theme.deep.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedPeriod == period ? Theme.accent : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.cardBackground)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.dustyRose.opacity(0.3), lineWidth: 1)
        )
    }

    private var overviewCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Overview")
                    .font(Theme.fontBold(18))
                    .foregroundStyle(Theme.deep)
                Spacer()
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(Theme.accent)
            }

            HStack(spacing: 0) {
                summaryStatItem(value: "\(completedActions)", label: "Actions", icon: "checkmark.circle.fill", color: Theme.mint)
                summaryStatItem(value: "\(evidenceThisPeriod.count)", label: "Evidence", icon: "bolt.fill", color: Theme.lavender)
                summaryStatItem(value: "$\(Int(savedThisPeriod))", label: "Saved", icon: "banknote.fill", color: Theme.gold)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.cardBackground)
                .shadow(color: .black.opacity(0.04), radius: 12, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Theme.dustyRose.opacity(0.4), lineWidth: 1)
        )
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
    }

    private func summaryStatItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
            Text(value)
                .font(Theme.fontBold(22))
                .foregroundStyle(Theme.deep)
            Text(label)
                .font(Theme.font(12))
                .foregroundStyle(Theme.deep.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }

    private var evidenceBreakdown: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Evidence Breakdown")
                    .font(Theme.fontBold(18))
                    .foregroundStyle(Theme.deep)
                Spacer()
            }

            HStack(spacing: 12) {
                breakdownChip(value: "\(winsThisPeriod)", label: "Wins", icon: "bolt.fill", color: Theme.accent)
                breakdownChip(value: "\(milestonesThisPeriod)", label: "Milestones", icon: "flag.fill", color: Theme.sage)
                breakdownChip(value: "\(bucketCompletedThisPeriod)", label: "Dreams", icon: "sparkles", color: Theme.gold)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.cardBackground)
                .shadow(color: .black.opacity(0.04), radius: 12, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Theme.dustyRose.opacity(0.4), lineWidth: 1)
        )
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(0.1), value: appearAnimation)
    }

    private func breakdownChip(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(color)
            }
            Text(value)
                .font(Theme.fontBold(20))
                .foregroundStyle(Theme.deep)
            Text(label)
                .font(Theme.font(11))
                .foregroundStyle(Theme.deep.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }

    private var consistencyCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Consistency")
                    .font(Theme.fontBold(18))
                    .foregroundStyle(Theme.deep)
                Spacer()
                Text("\(consistencyPercent)%")
                    .font(Theme.fontBold(22))
                    .foregroundStyle(Theme.mint)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Theme.mint.opacity(0.12))
                        .frame(height: 14)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(colors: [Theme.mint, Theme.sage], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: geo.size.width * CGFloat(consistencyPercent) / 100, height: 14)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: consistencyPercent)
                }
            }
            .frame(height: 14)

            HStack {
                Label("\(activeDays) active day\(activeDays == 1 ? "" : "s")", systemImage: "flame.fill")
                    .font(Theme.font(13))
                    .foregroundStyle(Theme.deep.opacity(0.6))
                Spacer()
                Label("\(plantsGrownThisPeriod) plant\(plantsGrownThisPeriod == 1 ? "" : "s") grown", systemImage: "leaf.fill")
                    .font(Theme.font(13))
                    .foregroundStyle(Theme.deep.opacity(0.6))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.cardBackground)
                .shadow(color: .black.opacity(0.04), radius: 12, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Theme.dustyRose.opacity(0.4), lineWidth: 1)
        )
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(0.2), value: appearAnimation)
    }

    private var insightsCard: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Insights")
                    .font(Theme.fontBold(18))
                    .foregroundStyle(Theme.deep)
                Spacer()
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(Theme.gold)
            }

            VStack(spacing: 0) {
                insightRow(icon: "star.fill", color: Theme.gold, label: "Top Focus Area", value: topCategory)
                Divider().padding(.leading, 44)
                insightRow(icon: "leaf.fill", color: Theme.mint, label: "Garden Growth", value: "\(plantsGrownThisPeriod) new plant\(plantsGrownThisPeriod == 1 ? "" : "s")")
                Divider().padding(.leading, 44)
                insightRow(icon: "dollarsign.circle.fill", color: Theme.cream, label: "Money Reclaimed", value: "$\(Int(savedThisPeriod))")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.cardBackground)
                .shadow(color: .black.opacity(0.04), radius: 12, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Theme.dustyRose.opacity(0.4), lineWidth: 1)
        )
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(0.3), value: appearAnimation)
    }

    private func insightRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 28)
            Text(label)
                .font(Theme.font(15))
                .foregroundStyle(Theme.deep)
            Spacer()
            Text(value)
                .font(Theme.fontBold(15))
                .foregroundStyle(Theme.deep.opacity(0.7))
        }
        .padding(.vertical, 12)
    }

    private var recentHighlights: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent Highlights")
                .font(Theme.fontBold(18))
                .foregroundStyle(Theme.deep)

            ForEach(evidenceThisPeriod.prefix(5)) { item in
                HStack(spacing: 14) {
                    let cat = EvidenceCategory(rawValue: item.category) ?? .win
                    ZStack {
                        Circle()
                            .fill(cat.color.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: cat.icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(cat.color)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title)
                            .font(Theme.fontBold(15))
                            .foregroundStyle(Theme.deep)
                            .lineLimit(1)
                        Text(item.date, style: .relative)
                            .font(Theme.font(12))
                            .foregroundStyle(Theme.deep.opacity(0.4))
                    }

                    Spacer()

                    if item.amount > 0 {
                        Text("$\(Int(item.amount))")
                            .font(Theme.fontBold(15))
                            .foregroundStyle(Theme.gold)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Theme.cardBackground)
                        .shadow(color: .black.opacity(0.03), radius: 6, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Theme.dustyRose.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(0.4), value: appearAnimation)
    }
}
