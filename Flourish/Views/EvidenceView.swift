import SwiftUI
import SwiftData

struct EvidenceView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \EvidenceItem.date, order: .reverse) private var allEvidence: [EvidenceItem]
    @State private var selectedFilter: String = "all"
    @State private var showingAddEvidence: Bool = false
    @State private var celebratingItem: String?
    @State private var showingFreedomCalc: Bool = false
    @State private var showingRoadmap: Bool = false
    @State private var showCelebration: Bool = false
    @State private var celebrationMsg: String = ""
    @State private var celebrationSub: String = ""
    @State private var editingEvidence: EvidenceItem? = nil

    private var filteredEvidence: [EvidenceItem] {
        if selectedFilter == "all" { return allEvidence }
        return allEvidence.filter { $0.category == selectedFilter }
    }

    private var totalSaved: Double {
        allEvidence.filter { $0.category == "saving" }.reduce(0) { $0 + $1.amount }
    }

    private var totalWins: Int {
        allEvidence.filter { $0.category == "win" }.count
    }

    private var totalMilestones: Int {
        allEvidence.filter { $0.category == "milestone" }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    dailyQuoteCard
                    statsRow
                    toolsSection
                    filterRow
                    evidenceList
                }
                .padding(.horizontal, 20)
                .padding(.top, 0)
                .padding(.bottom, 100)
            }
            .flowerBackground(seed: 3)
            .navigationBarTitleDisplayMode(.inline)
            .celebration(
                isShowing: $showCelebration,
                message: celebrationMsg,
                subtitle: celebrationSub,
                style: .sparkle,
                duration: 2.8
            )
            .sheet(isPresented: $showingFreedomCalc) {
                FreedomCalculatorView()
            }
            .sheet(isPresented: $showingRoadmap) {
                RemoteWorkRoadmapView()
            }
            .sheet(item: $editingEvidence) { item in
                EditEvidenceSheet(item: item)
            }
            .sheet(isPresented: $showingAddEvidence) {
                AddEvidenceSheet { title, detail, category, amount in
                    let item = EvidenceItem(title: title, detail: detail, category: category, amount: amount)
                    modelContext.insert(item)
                    withAnimation(.spring(duration: 0.5)) {
                        celebratingItem = title
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { celebratingItem = nil }
                    }
                    let cat = EvidenceCategory(rawValue: category)
                    switch cat {
                    case .win:
                        celebrationMsg = "Power move logged!"
                        celebrationSub = "That's undeniable evidence."
                    case .saving:
                        celebrationMsg = "$\(Int(amount)) reclaimed!"
                        celebrationSub = "Your freedom fund is growing."
                    case .milestone:
                        celebrationMsg = "Landmark reached!"
                        celebrationSub = "You're rewriting your story."
                    case .none:
                        celebrationMsg = "Evidence logged!"
                        celebrationSub = "Keep building your case."
                    }
                    showCelebration = true
                }
            }
        }
    }

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Evidence Wall")
                    .font(Theme.largeTitleFont)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.deep)
                Text("Every win is proof you're building something real.")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.deep.opacity(0.6))
            }
            Spacer()
            Button {
                showingAddEvidence = true
            } label: {
                Image(systemName: "plus")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Theme.accent, in: Circle())
            }
        }
        .padding(.top, 0)
    }

    private var dailyQuotes: [String] {
        [
            "You didn't come this far to only come this far.",
            "The dream is free. The hustle is sold separately.",
            "Small steps still move you forward.",
            "Your future self is watching — make them proud.",
            "Discipline is choosing between what you want now and what you want most.",
            "You're not behind. You're building.",
            "The best investment you'll ever make is in yourself.",
            "Stop waiting for Friday, for summer, for someone. Happiness is achieved, not waited for.",
            "You are the evidence that something extraordinary is possible.",
            "Every expert was once a beginner.",
            "Don't count the days. Make the days count.",
            "You are one decision away from a completely different life.",
            "What feels impossible today will one day be your warm-up.",
            "Comfort zones are where dreams go to sleep.",
            "Build the life you don't need a vacation from.",
            "Success is rented, and the rent is due every day.",
            "The only limit is the one you accept.",
            "A year from now you'll wish you started today.",
            "Doubt kills more dreams than failure ever will.",
            "You are proof that resilience wins.",
            "Progress, not perfection.",
            "The grind includes days you don't feel like it.",
            "Your potential doesn't have an expiration date.",
            "Bet on yourself — it's the safest bet you'll ever make.",
            "Winners are just losers who tried one more time.",
            "The money you seek is seeking you too.",
            "Freedom isn't given. It's earned.",
            "Stay patient. Stay persistent. Stay unstoppable.",
            "Your story isn't over. The best chapters are being written now.",
            "Wake up with determination. Go to bed with satisfaction.",
            "Every day is another chance to change your life."
        ]
    }

    private var todayQuote: String {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return dailyQuotes[(day - 1) % dailyQuotes.count]
    }

    private var dailyQuoteCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.gold)
                Text("DAILY SPARK")
                    .font(Theme.caption2Font)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.gold)
                    .tracking(1.2)
                Spacer()
                Text(Date(), format: .dateTime.month(.abbreviated).day())
                    .font(Theme.caption2Font)
                    .foregroundStyle(.tertiary)
            }
            Text("\"\(todayQuote)\"")
                .font(Theme.fontBold(18))
                .foregroundStyle(Theme.deep)
                .italic()
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [Theme.cardBackground, Theme.creamCard.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Theme.gold.opacity(0.1), radius: 12, y: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Theme.gold.opacity(0.25), lineWidth: 1)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(value: "\(totalWins)", label: "Power Moves", color: Theme.softLavender, bgColor: Theme.lavenderCard)
            statCard(value: "$\(Int(totalSaved))", label: "Reclaimed", color: Theme.rose, bgColor: Theme.roseCard)
            statCard(value: "\(totalMilestones)", label: "Landmarks", color: Theme.sage, bgColor: Theme.sageCard)
        }
    }

    private func statCard(value: String, label: String, color: Color, bgColor: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(Theme.title2Font)
                .fontWeight(.heavy)
                .foregroundStyle(color)
            Text(label)
                .font(Theme.caption2Font)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Theme.cardBackground, bgColor.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.dustyRose.opacity(0.5), lineWidth: 1)
        }
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                filterChip("All", tag: "all")
                filterChip("Power Moves", tag: "win")
                filterChip("Savings", tag: "saving")
                filterChip("Landmarks", tag: "milestone")
            }
        }
    }

    private func filterChip(_ title: String, tag: String) -> some View {
        Button {
            withAnimation(.spring(duration: 0.3)) {
                selectedFilter = tag
            }
        } label: {
            Text(title)
                .font(Theme.subheadlineFont)
                .fontWeight(selectedFilter == tag ? .bold : .medium)
                .foregroundStyle(selectedFilter == tag ? .white : .secondary)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background {
                    if selectedFilter == tag {
                        Capsule().fill(Theme.deep)
                    } else {
                        Capsule().fill(Theme.lavenderCard.opacity(0.5))
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private var evidenceList: some View {
        VStack(spacing: 12) {
            if filteredEvidence.isEmpty {
                evidenceEmptyState
            } else {
                ForEach(filteredEvidence) { item in
                    evidenceCard(item)
                }
            }
        }
    }

    private func evidenceCard(_ item: EvidenceItem) -> some View {
        let cat = EvidenceCategory(rawValue: item.category) ?? .win
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: cat.icon)
                    .font(Theme.title3Font)
                    .foregroundStyle(cat.color)
                    .frame(width: 36, height: 36)
                    .background(cat.color.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(Theme.headlineFont)
                        .foregroundStyle(.primary)
                    Text(cat.celebrationLine)
                        .font(Theme.captionFont)
                        .fontWeight(.bold)
                        .foregroundStyle(cat.color)
                }
                Spacer()
                if item.amount > 0 && cat == .saving {
                    Text("$\(Int(item.amount))")
                        .font(Theme.title3Font)
                        .fontWeight(.heavy)
                        .foregroundStyle(Theme.gold)
                }
            }
            if !item.detail.isEmpty {
                Text(item.detail)
                    .font(Theme.subheadlineFont)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            HStack {
                Text(item.date, style: .date)
                    .font(Theme.caption2Font)
                    .foregroundStyle(.tertiary)
                Spacer()
            }
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.cardBackground)
                .shadow(color: Theme.lavender.opacity(0.12), radius: 10, y: 3)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.dustyRose.opacity(0.5), lineWidth: 1)
        }
        .overlay {
            if celebratingItem == item.title {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(cat.color, lineWidth: 2)
                    .transition(.opacity)
            }
        }
        .contextMenu {
            Button {
                editingEvidence = item
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                withAnimation {
                    modelContext.delete(item)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var toolsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("STRATEGIC TOOLS")
                    .font(Theme.captionFont)
                    .fontWeight(.bold)
                    .foregroundStyle(.tertiary)
                    .tracking(1.2)
            }

            Button {
                showingFreedomCalc = true
            } label: {
                toolRow(
                    title: "Freedom Number Calculator",
                    subtitle: "Know your number. Own your timeline.",
                    icon: "function",
                    color: Theme.gold
                )
            }
            .buttonStyle(.plain)

            Button {
                showingRoadmap = true
            } label: {
                toolRow(
                    title: "Remote Work Roadmap",
                    subtitle: "Step-by-step to location independence.",
                    icon: "map.fill",
                    color: Theme.sage
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func toolRow(title: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.lavenderCard.opacity(0.6))
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: icon)
                        .font(Theme.title3Font)
                        .foregroundStyle(color)
                }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Theme.bodyFont)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(Theme.captionFont)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(Theme.captionFont)
                .foregroundStyle(.quaternary)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.cardBackground)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.dustyRose.opacity(0.5), lineWidth: 1)
        }
    }

    private var evidenceEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy")
                .font(Theme.font(40))
                .foregroundStyle(Theme.softLavender)
            Text("Your evidence wall starts here.")
                .font(Theme.headlineFont)
                .foregroundStyle(.secondary)
            Text("Every win, every dollar saved, every milestone\nis proof you're building something real.")
                .font(Theme.subheadlineFont)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Button {
                showingAddEvidence = true
            } label: {
                Text("Log your first win")
                    .font(Theme.subheadlineFont)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Theme.accent, in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

struct AddEvidenceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var detail: String = ""
    @State private var category: EvidenceCategory = .win
    @State private var amount: String = ""
    let onAdd: (String, String, String, Double) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What happened?", text: $title)
                    TextField("Tell the story (optional)", text: $detail, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Evidence")
                        .foregroundStyle(Theme.accent)
                }
                Section {
                    Picker("Type", selection: $category) {
                        ForEach(EvidenceCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("Category")
                        .foregroundStyle(Theme.accent)
                }
                if category == .saving {
                    Section {
                        HStack {
                            Text("$")
                                .foregroundStyle(.secondary)
                            TextField("0", text: $amount)
                                .keyboardType(.decimalPad)
                        }
                    } header: {
                        Text("Amount Reclaimed")
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background { Theme.pageBg }
            .navigationTitle("Log Evidence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.beige, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") {
                        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let amt = Double(amount) ?? 0
                        onAdd(title, detail, category.rawValue, amt)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(title.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Theme.accent)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .tint(Theme.accent)
        }
        .presentationDetents([.large])
    }
}

struct EditEvidenceSheet: View {
    @Environment(\.dismiss) private var dismiss
    let item: EvidenceItem
    @State private var title: String = ""
    @State private var detail: String = ""
    @State private var category: EvidenceCategory = .win
    @State private var amount: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What happened?", text: $title)
                    TextField("Tell the story (optional)", text: $detail, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Evidence")
                        .foregroundStyle(Theme.accent)
                }
                Section {
                    Picker("Type", selection: $category) {
                        ForEach(EvidenceCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("Category")
                        .foregroundStyle(Theme.accent)
                }
                if category == .saving {
                    Section {
                        HStack {
                            Text("$")
                                .foregroundStyle(.secondary)
                            TextField("0", text: $amount)
                                .keyboardType(.decimalPad)
                        }
                    } header: {
                        Text("Amount Reclaimed")
                            .foregroundStyle(Theme.accent)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background { Theme.pageBg }
            .navigationTitle("Edit Evidence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.beige, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        item.title = title
                        item.detail = detail
                        item.category = category.rawValue
                        item.amount = Double(amount) ?? 0
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(title.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Theme.accent)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .tint(Theme.accent)
        }
        .presentationDetents([.large])
        .onAppear {
            title = item.title
            detail = item.detail
            category = EvidenceCategory(rawValue: item.category) ?? .win
            amount = item.amount > 0 ? String(Int(item.amount)) : ""
        }
    }
}
