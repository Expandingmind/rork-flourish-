import SwiftUI
import SwiftData

struct DailyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.createdDate, order: .reverse)
    private var allTodos: [TodoItem]
    @Query(sort: \MicroAction.dateSelected, order: .reverse)
    private var allMicroActions: [MicroAction]
    @Query(sort: \DailyAction.createdDate, order: .reverse)
    private var allActions: [DailyAction]
    @Query private var gardenResources: [GardenResource]

    @State private var newTodoText: String = ""
    @State private var newTodoTime: Date? = nil
    @State private var showTimePicker: Bool = false
    @State private var showingMicroPicker: Bool = false
    @State private var isTodoExpanded: Bool = true
    @State private var isMicroExpanded: Bool = true
    @FocusState private var isTodoFieldFocused: Bool
    @State private var showCelebration: Bool = false
    @State private var celebrationMessage: String = ""
    @State private var celebrationSubtitle: String = ""
    @State private var seedEarnedFlash: Bool = false
    @State private var waterEarnedFlash: Bool = false

    nonisolated init() {}

    private var todayTodos: [TodoItem] {
        allTodos.filter { Calendar.current.isDateInToday($0.createdDate) }
    }

    private var todayMicroActions: [MicroAction] {
        allMicroActions.filter { Calendar.current.isDateInToday($0.dateSelected) }
    }

    private var completedMicroCount: Int {
        todayMicroActions.filter(\.isCompleted).count
    }

    private var currentStreak: Int {
        var streak = 0
        var date = Date.now
        let calendar = Calendar.current
        while true {
            let dayActions = allActions.filter { calendar.isDate($0.createdDate, inSameDayAs: date) }
            let dayTodos = allTodos.filter { calendar.isDate($0.createdDate, inSameDayAs: date) }
            let dayMicro = allMicroActions.filter { calendar.isDate($0.dateSelected, inSameDayAs: date) }
            let hasActivity = dayActions.contains(where: \.isCompleted) || dayTodos.contains(where: \.isCompleted) || dayMicro.contains(where: \.isCompleted)
            if hasActivity {
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: date) else { break }
                date = prev
            } else if calendar.isDateInToday(date) {
                guard let prev = calendar.date(byAdding: .day, value: -1, to: date) else { break }
                date = prev
            } else {
                break
            }
        }
        return streak
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        if hour < 12 { return "Good morning" }
        if hour < 17 { return "Good afternoon" }
        return "Good evening"
    }

    private var totalTasks: Int {
        todayTodos.count + todayMicroActions.count
    }

    private var completedTasks: Int {
        todayTodos.filter(\.isCompleted).count + completedMicroCount
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    streakCard
                    gardenResourceBanner
                    todoCard
                    microActionsCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .flowerBackground(seed: 1)
            .navigationBarTitleDisplayMode(.inline)
            .celebration(
                isShowing: $showCelebration,
                message: celebrationMessage,
                subtitle: celebrationSubtitle,
                style: .confetti
            )
            .sheet(isPresented: $showingMicroPicker) {
                MicroActionPickerSheet(
                    alreadySelected: Set(todayMicroActions.map(\.actionKey)),
                    onSelect: { keys in
                        for key in keys {
                            let action = MicroAction(actionKey: key)
                            modelContext.insert(action)
                        }
                    }
                )
            }
        }
    }

    private var gardenResourceBanner: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "leaf.arrow.circlepath")
                    .font(Theme.font(14))
                    .foregroundStyle(Theme.softPeach)
                    .scaleEffect(seedEarnedFlash ? 1.4 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.4), value: seedEarnedFlash)
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(resource.seeds)")
                        .font(Theme.subheadlineFont)
                        .fontWeight(.heavy)
                        .foregroundStyle(Theme.deep)
                        .contentTransition(.numericText())
                    Text("Seeds")
                        .font(Theme.caption2Font)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            Rectangle()
                .fill(Color(.separator))
                .frame(width: 1, height: 28)
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "drop.fill")
                    .font(Theme.font(14))
                    .foregroundStyle(Theme.softSky)
                    .scaleEffect(waterEarnedFlash ? 1.4 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.4), value: waterEarnedFlash)
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(resource.waterCans)")
                        .font(Theme.subheadlineFont)
                        .fontWeight(.heavy)
                        .foregroundStyle(Theme.deep)
                        .contentTransition(.numericText())
                    Text("Water")
                        .font(Theme.caption2Font)
                        .foregroundStyle(.tertiary)
                }
            }

        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.softPeach.opacity(0.12),
                            Theme.softSky.opacity(0.12)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Theme.softPeach.opacity(0.2),
                                    Theme.softSky.opacity(0.2)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                )
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(greeting)
                    .font(Theme.largeTitleFont)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.deep)
                Text("Your evidence is building.")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.deep.opacity(0.6))
            }
            Spacer()
        }
        .padding(.top, 12)
    }

    private var streakCard: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(currentStreak)")
                    .font(Theme.fontBold(48))
                    .foregroundStyle(Theme.rose)
                Text(currentStreak == 1 ? "day of momentum" : "days of momentum")
                    .font(Theme.subheadlineFont)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(Theme.lavenderLight.opacity(0.5), lineWidth: 6)
                        .frame(width: 70, height: 70)
                    Circle()
                        .trim(from: 0, to: totalTasks == 0 ? 0 : Double(completedTasks) / Double(totalTasks))
                        .stroke(Theme.softLavender, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(duration: 0.6), value: completedTasks)
                    Text("\(completedTasks)/\(totalTasks)")
                        .font(Theme.calloutFont)
                        .fontWeight(.bold)
                        .foregroundStyle(Theme.deep)
                }
                Text("today")
                    .font(Theme.caption2Font)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.cardBackground)
                .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Theme.dustyRose.opacity(0.5), lineWidth: 1)
        }
    }

    // MARK: - Daily To-Do Card

    private var todoCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(duration: 0.35)) {
                    isTodoExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Theme.roseMist.opacity(0.4))
                            .frame(width: 36, height: 36)
                        Image(systemName: "checklist")
                            .font(Theme.fontBold(16))
                            .foregroundStyle(Theme.rose)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily To-Do List")
                            .font(Theme.headlineFont)
                            .foregroundStyle(Theme.deep)
                        let count = todayTodos.filter(\.isCompleted).count
                        Text("\(count) of \(todayTodos.count) done")
                            .font(Theme.captionFont)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(Theme.captionFont)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isTodoExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)
            .padding(18)

            if isTodoExpanded {
                Divider()
                    .padding(.horizontal, 18)

                VStack(spacing: 0) {
                    ForEach(todayTodos) { todo in
                        todoRow(todo)
                        if todo.id != todayTodos.last?.id {
                            Divider()
                                .padding(.leading, 54)
                        }
                    }
                }
                .padding(.vertical, 4)

                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(Theme.font(22))
                            .foregroundStyle(Theme.accent.opacity(0.5))
                        TextField("Add a to-do...", text: $newTodoText)
                            .font(Theme.bodyFont)
                            .foregroundStyle(Theme.deep)
                            .focused($isTodoFieldFocused)
                            .submitLabel(.done)
                            .onSubmit { addTodo() }
                        Button {
                            withAnimation(.spring(duration: 0.3)) {
                                if showTimePicker {
                                    showTimePicker = false
                                    newTodoTime = nil
                                } else {
                                    showTimePicker = true
                                    if newTodoTime == nil {
                                        newTodoTime = Date()
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: showTimePicker ? "clock.fill" : "clock")
                                .font(Theme.font(16))
                                .foregroundStyle(showTimePicker ? Theme.gold : Color(.tertiaryLabel))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)

                    if showTimePicker {
                        DatePicker("Time", selection: Binding(
                            get: { newTodoTime ?? Date() },
                            set: { newTodoTime = $0 }
                        ), displayedComponents: .hourAndMinute)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .padding(.horizontal, 54)
                            .padding(.bottom, 12)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                if todayTodos.isEmpty {
                    VStack(spacing: 10) {
                        Text("Plan your day — what matters most?")
                            .font(Theme.subheadlineFont)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 18)
                }
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 3)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Theme.dustyRose.opacity(0.5), lineWidth: 1)
        }
    }

    private func todoRow(_ todo: TodoItem) -> some View {
        HStack(spacing: 14) {
            Button {
                withAnimation(.spring(duration: 0.35)) {
                    todo.isCompleted.toggle()
                }
                if todo.isCompleted {
                    earnSeed()
                    celebrationMessage = ["Crushed it!", "One down!", "That's momentum!", "Power move!", "Evidence logged!", "Unstoppable!", "On fire!", "Let's GOOOO!"].randomElement() ?? "Done!"
                    celebrationSubtitle = ["Every check builds your future.", "Small wins compound.", "You're proving yourself right.", "Keep stacking evidence.", "Winners do winner things.", "That's how champions move."].randomElement() ?? ""
                    showCelebration = true
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(todo.isCompleted ? Theme.cream : Color.clear)
                        .frame(width: 24, height: 24)
                    Circle()
                        .stroke(todo.isCompleted ? Theme.cream : Color(.tertiaryLabel), lineWidth: 1.8)
                        .frame(width: 24, height: 24)
                    if todo.isCompleted {
                        Image(systemName: "checkmark")
                            .font(Theme.fontBold(11))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(todo.title)
                    .font(Theme.bodyFont)
                    .strikethrough(todo.isCompleted, color: .secondary)
                    .foregroundStyle(todo.isCompleted ? .secondary : Theme.deep)
                if let time = todo.scheduledTime {
                    Text(time, format: .dateTime.hour().minute())
                        .font(Theme.captionFont)
                        .foregroundStyle(todo.isCompleted ? Color(.tertiaryLabel) : Theme.sage)
                }
            }
            Spacer()
            if !todo.isCompleted {
                HStack(spacing: 2) {
                    Image(systemName: "leaf.arrow.circlepath")
                        .font(Theme.font(9))
                    Text("+1")
                        .font(Theme.fontBold(9))
                }
                .foregroundStyle(Theme.softPeach.opacity(0.7))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Capsule().fill(Theme.softPeach.opacity(0.15)))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                withAnimation { modelContext.delete(todo) }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var resource: GardenResource {
        gardenResources.first ?? GardenResource()
    }

    private func ensureResourceExists() {
        if gardenResources.isEmpty {
            let r = GardenResource()
            modelContext.insert(r)
        }
    }

    private func earnSeed() {
        ensureResourceExists()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            gardenResources.first?.earnSeed()
            seedEarnedFlash = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            seedEarnedFlash = false
        }
    }

    private func earnWater() {
        ensureResourceExists()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            gardenResources.first?.earnWater()
            waterEarnedFlash = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            waterEarnedFlash = false
        }
    }

    private func addTodo() {
        let trimmed = newTodoText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let item = TodoItem(title: trimmed, scheduledTime: newTodoTime)
        modelContext.insert(item)
        newTodoText = ""
        newTodoTime = nil
        showTimePicker = false
    }

    // MARK: - Micro Actions Card

    private var microActionsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(duration: 0.35)) {
                    isMicroExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Theme.lavenderLight.opacity(0.4))
                            .frame(width: 36, height: 36)
                        Image(systemName: "sparkle")
                            .font(Theme.fontBold(16))
                            .foregroundStyle(Theme.softLavender)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Today's Micro Actions")
                            .font(Theme.headlineFont)
                            .foregroundStyle(Theme.deep)
                        if todayMicroActions.isEmpty {
                            Text("Choose at least 3")
                                .font(Theme.captionFont)
                                .foregroundStyle(.tertiary)
                        } else {
                            Text("\(completedMicroCount) of \(todayMicroActions.count) done")
                                .font(Theme.captionFont)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(Theme.captionFont)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isMicroExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)
            .padding(18)

            if isMicroExpanded {
                Divider()
                    .padding(.horizontal, 18)

                if todayMicroActions.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "wand.and.stars")
                            .font(Theme.font(32))
                            .foregroundStyle(Theme.lavender)
                        Text("Pick your micro actions for today")
                            .font(Theme.subheadlineFont)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Text("Small intentional moves that compound.")
                            .font(Theme.captionFont)
                            .foregroundStyle(Theme.lavender.opacity(0.6))
                        Button {
                            showingMicroPicker = true
                        } label: {
                            Text("Choose actions")
                                .font(Theme.subheadlineFont)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(Theme.accent, in: Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                } else {
                    VStack(spacing: 0) {
                        ForEach(todayMicroActions) { micro in
                            microRow(micro)
                            if micro.id != todayMicroActions.last?.id {
                                Divider()
                                    .padding(.leading, 54)
                            }
                        }
                    }
                    .padding(.vertical, 4)

                    Button {
                        showingMicroPicker = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(Theme.font(16))
                            Text("Add more actions")
                                .font(Theme.subheadlineFont)
                        }
                        .foregroundStyle(Theme.accent.opacity(0.7))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 3)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Theme.dustyRose.opacity(0.5), lineWidth: 1)
        }
    }

    private func microRow(_ micro: MicroAction) -> some View {
        let template = MicroActionTemplate.all.first(where: { $0.id == micro.actionKey })
        return HStack(spacing: 14) {
            Button {
                withAnimation(.spring(duration: 0.35)) {
                    micro.isCompleted.toggle()
                }
                if micro.isCompleted {
                    earnWater()
                    celebrationMessage = ["Micro win!", "Intentional!", "That's growth!", "Building habits!", "Atomic power!", "Legend behavior!"].randomElement() ?? "Done!"
                    celebrationSubtitle = ["Small moves, big life.", "Consistency is your superpower.", "This is what discipline looks like.", "1% better every single day."].randomElement() ?? ""
                    showCelebration = true
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(micro.isCompleted ? (template?.color ?? Theme.accent) : Color.clear)
                        .frame(width: 24, height: 24)
                    Circle()
                        .stroke(micro.isCompleted ? (template?.color ?? Theme.accent) : Color(.tertiaryLabel), lineWidth: 1.8)
                        .frame(width: 24, height: 24)
                    if micro.isCompleted {
                        Image(systemName: "checkmark")
                            .font(Theme.fontBold(11))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(template?.title ?? micro.actionKey)
                    .font(Theme.bodyFont)
                    .strikethrough(micro.isCompleted, color: .secondary)
                    .foregroundStyle(micro.isCompleted ? .secondary : Theme.deep)
                Text(template?.subtitle ?? "")
                    .font(Theme.captionFont)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            if !micro.isCompleted {
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                        .font(Theme.font(9))
                    Text("+1")
                        .font(Theme.fontBold(9))
                }
                .foregroundStyle(Theme.softSky.opacity(0.7))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Capsule().fill(Theme.softSky.opacity(0.15)))
            } else if let template {
                Image(systemName: template.icon)
                    .font(Theme.font(14))
                    .foregroundStyle(template.color.opacity(0.6))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
    }
}

// MARK: - Micro Action Picker Sheet

struct MicroActionPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let alreadySelected: Set<String>
    let onSelect: (Set<String>) -> Void

    @State private var selected: Set<String> = []

    private var availableTemplates: [MicroActionTemplate] {
        MicroActionTemplate.all.filter { !alreadySelected.contains($0.id) }
    }

    private var totalSelected: Int {
        selected.count
    }

    private var minimumMet: Bool {
        totalSelected + alreadySelected.count >= 3
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Choose your micro actions")
                            .font(Theme.title3Font)
                            .fontWeight(.bold)
                            .foregroundStyle(Theme.deep)
                        Text("Pick at least 3 small moves to build momentum today. You can always choose more.")
                            .font(Theme.subheadlineFont)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 4)

                    if !minimumMet && alreadySelected.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle.fill")
                                .font(Theme.captionFont)
                            Text("Select at least 3 actions")
                                .font(Theme.captionFont)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(Theme.softLavender)
                        .padding(.horizontal, 4)
                    }

                    VStack(spacing: 10) {
                        ForEach(availableTemplates) { template in
                            microTemplateRow(template)
                        }
                    }

                    if availableTemplates.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(Theme.font(36))
                                .foregroundStyle(Theme.sage)
                            Text("You've selected all actions!")
                                .font(Theme.headlineFont)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
                .padding(20)
            }
            .background { Theme.pageBg }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSelect(selected)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(minimumMet ? Theme.accent : Color.gray)
                    .disabled(!minimumMet)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func microTemplateRow(_ template: MicroActionTemplate) -> some View {
        let isSelected = selected.contains(template.id)
        return Button {
            withAnimation(.spring(duration: 0.3)) {
                if isSelected {
                    selected.remove(template.id)
                } else {
                    selected.insert(template.id)
                }
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(template.color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: template.icon)
                        .font(Theme.font(16))
                        .foregroundStyle(template.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(template.title)
                        .font(Theme.subheadlineFont)
                        .fontWeight(.medium)
                        .foregroundStyle(Theme.deep)
                    Text(template.subtitle)
                        .font(Theme.captionFont)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(isSelected ? template.color : Color.clear)
                        .frame(width: 26, height: 26)
                    Circle()
                        .stroke(isSelected ? template.color : Color(.tertiaryLabel), lineWidth: 1.8)
                        .frame(width: 26, height: 26)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(Theme.fontBold(12))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? template.color.opacity(0.08) : Theme.cardBackground)
                    .shadow(color: .black.opacity(isSelected ? 0.04 : 0.03), radius: 6, y: 2)
            }
        }
        .buttonStyle(.plain)
    }
}
