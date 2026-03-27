import SwiftUI
import SwiftData

struct BucketListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BucketListItem.createdDate) private var items: [BucketListItem]
    @State private var showingAddItem: Bool = false
    @State private var showingCompleted: Bool = false
    @State private var recentlyCompletedIDs: Set<PersistentIdentifier> = []
    @Namespace private var bucketAnimation
    @State private var showCelebration: Bool = false
    @State private var editingItem: BucketListItem? = nil

    private let accentColors: [Color] = [
        Theme.softLavender,
        Theme.mint,
        Theme.dustyRose,
        Theme.cream,
        Theme.sage,
        Theme.softMint,
    ]

    private var activeItems: [BucketListItem] {
        items.filter { !$0.isCompleted || recentlyCompletedIDs.contains($0.persistentModelID) }
    }

    private var completedItems: [BucketListItem] {
        items.filter(\.isCompleted)
    }

    private var completedCount: Int {
        completedItems.count
    }

    private var currentYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: .now)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    mainCard
                    progressCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .flowerBackground(seed: 2)
            .navigationBarTitleDisplayMode(.inline)
            .celebration(
                isShowing: $showCelebration,
                message: "Dream achieved!",
                subtitle: "You just proved anything is possible.",
                style: .gold,
                duration: 3.0
            )
            .sheet(isPresented: $showingAddItem) {
                AddBucketListItemSheet { title, detail, colorIdx, targetDate in
                    let item = BucketListItem(title: title, detail: detail, colorIndex: colorIdx, targetDate: targetDate)
                    modelContext.insert(item)
                }
            }
            .sheet(item: $editingItem) { item in
                EditBucketListItemSheet(item: item)
            }
            .sheet(isPresented: $showingCompleted) {
                CompletedBucketListSheet(completedItems: completedItems, accentColors: accentColors)
            }
        }
    }

    private var mainCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 8)

            if activeItems.isEmpty {
                emptyState
                    .padding(.horizontal, 24)
                    .padding(.vertical, 40)
            } else {
                VStack(spacing: 0) {
                    ForEach(activeItems) { item in
                        bucketRow(item)
                            .transition(.asymmetric(
                                insertion: .opacity,
                                removal: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.5))
                            ))
                        if item.id != activeItems.last?.id {
                            Divider()
                                .padding(.leading, 64)
                                .padding(.trailing, 24)
                        }
                    }
                }
                .padding(.vertical, 12)

                pageIndicator
                    .padding(.bottom, 24)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Theme.lavenderLight.opacity(0.35), Theme.roseMist.opacity(0.2), Theme.mint.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Theme.cardBackground)
                )
                .shadow(color: Theme.lavender.opacity(0.12), radius: 16, y: 4)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Theme.dustyRose.opacity(0.5), lineWidth: 1)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(currentYear)
                    .font(Theme.captionFont)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .tracking(3)
                Text("Bucket List")
                    .font(Theme.fontBold(32))
                    .foregroundStyle(.primary)
                Text("For You, By You")
                    .font(Theme.subheadlineFont)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                showingAddItem = true
            } label: {
                Image(systemName: "plus")
                    .font(Theme.title3Font)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(Theme.accent)
                    )
            }
        }
    }

    private func bucketRow(_ item: BucketListItem) -> some View {
        let color = accentColors[item.colorIndex % accentColors.count]
        return Button {
            if !item.isCompleted {
                let itemID = item.persistentModelID
                recentlyCompletedIDs.insert(itemID)
                withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
                    item.isCompleted = true
                    item.completedDate = .now
                }
                showCelebration = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        _ = recentlyCompletedIDs.remove(itemID)
                    }
                }
            } else {
                withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
                    item.isCompleted = false
                    item.completedDate = nil
                }
            }
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(color.opacity(0.6), lineWidth: 2)
                        .frame(width: 28, height: 28)
                    if item.isCompleted {
                        Circle()
                            .fill(color)
                            .frame(width: 18, height: 18)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(Theme.bodyFont)
                        .fontWeight(.semibold)
                        .foregroundStyle(item.isCompleted ? .secondary : .primary)
                        .strikethrough(item.isCompleted, color: .secondary)
                        .lineLimit(1)
                    if !item.detail.isEmpty {
                        Text(item.detail)
                            .font(Theme.subheadlineFont)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    if let targetDate = item.targetDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(Theme.font(10))
                            Text(targetDate, format: .dateTime.month(.abbreviated).day().year())
                                .font(Theme.caption2Font)
                        }
                        .foregroundStyle(item.isCompleted ? Color(.tertiaryLabel) : color.opacity(0.8))
                    }
                }

                Spacer()

                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                editingItem = item
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

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            Text("\(activeItems.count) dream\(activeItems.count == 1 ? "" : "s")")
                .font(Theme.captionFont)
                .foregroundStyle(Theme.softLavender.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }

    private var progressCard: some View {
        Button {
            showingCompleted = true
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Theme.lavenderLight.opacity(0.35))
                        .frame(width: 80, height: 80)
                    Image(systemName: "sparkles")
                        .font(Theme.font(28))
                        .foregroundStyle(Theme.softLavender)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Evidence of Progress")
                        .font(Theme.title3Font)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    Text("\(completedCount) completed")
                        .font(Theme.subheadlineFont)
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Theme.bodyFont)
                    .foregroundStyle(.tertiary)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: [Theme.roseMist.opacity(0.2), Theme.lavenderLight.opacity(0.18), Theme.mint.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Theme.cardBackground)
                    )
                    .shadow(color: Theme.lavender.opacity(0.1), radius: 16, y: 4)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Theme.dustyRose.opacity(0.5), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle")
                .font(Theme.font(44))
                .foregroundStyle(Theme.lavender)
            Text("Dream bigger than ever.")
                .font(Theme.headlineFont)
                .foregroundStyle(.secondary)
            Text("Add what you're building toward.\nEvery item is a declaration.")
                .font(Theme.subheadlineFont)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Button {
                showingAddItem = true
            } label: {
                Text("Add your first dream")
                    .font(Theme.subheadlineFont)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Theme.accent, in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct CompletedBucketListSheet: View {
    @Environment(\.dismiss) private var dismiss
    let completedItems: [BucketListItem]
    let accentColors: [Color]

    var body: some View {
        NavigationStack {
            ScrollView {
                if completedItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "star.circle")
                            .font(Theme.font(48))
                            .foregroundStyle(Theme.mint)
                        Text("No completed dreams yet")
                            .font(Theme.headlineFont)
                            .foregroundStyle(.secondary)
                        Text("Start checking off your bucket list\nand watch your progress grow.")
                            .font(Theme.subheadlineFont)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                } else {
                    VStack(spacing: 12) {
                        ForEach(completedItems) { item in
                            completedRow(item)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .background { Theme.pageBg }
            .navigationTitle("Completed Dreams")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.beige, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func completedRow(_ item: BucketListItem) -> some View {
        let color = accentColors[item.colorIndex % accentColors.count]
        return HStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(Theme.title3Font)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(Theme.bodyFont)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                if !item.detail.isEmpty {
                    Text(item.detail)
                        .font(Theme.captionFont)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                if let completedDate = item.completedDate {
                    Text(completedDate, style: .date)
                        .font(Theme.caption2Font)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.cardBackground)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.dustyRose.opacity(0.5), lineWidth: 1)
        }
    }
}

struct AddBucketListItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var detail: String = ""
    @State private var selectedColor: Int = 0
    @State private var hasTargetDate: Bool = false
    @State private var targetDate: Date = Date()

    let onAdd: (String, String, Int, Date?) -> Void

    private let colorOptions: [(String, Color)] = [
        ("Lavender", Theme.softLavender),
        ("Peach", Theme.softPeach),
        ("Rose", Theme.dustyRose),
        ("Pink", Theme.softPink),
        ("Mint", Theme.softMint),
        ("Sky", Theme.softSky),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What's the dream?", text: $title)
                    TextField("Why does it matter? (optional)", text: $detail, axis: .vertical)
                        .lineLimit(2...5)
                } header: {
                    Text("Your Vision")
                        .foregroundStyle(Theme.accent)
                }
                Section {
                    Toggle(isOn: $hasTargetDate.animation(.spring(duration: 0.3))) {
                        Label("Target Date", systemImage: "calendar")
                            .foregroundStyle(Theme.deep)
                    }
                    .tint(Theme.accent)
                    if hasTargetDate {
                        DatePicker("Date", selection: $targetDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .tint(Theme.accent)
                    }
                } header: {
                    Text("When")
                        .foregroundStyle(Theme.accent)
                }
                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                        ForEach(0..<colorOptions.count, id: \.self) { idx in
                            Button {
                                selectedColor = idx
                            } label: {
                                Circle()
                                    .fill(colorOptions[idx].1)
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        if selectedColor == idx {
                                            Circle()
                                                .stroke(Theme.warmCream, lineWidth: 3)
                                                .frame(width: 28, height: 28)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Color")
                        .foregroundStyle(Theme.accent)
                }
            }
            .scrollContentBackground(.hidden)
            .background { Theme.pageBg }
            .navigationTitle("New Dream")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.beige, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        onAdd(title, detail, selectedColor, hasTargetDate ? targetDate : nil)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(title.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Theme.accent)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .tint(Theme.accent)
        }
        .presentationDetents([.medium, .large])
    }
}

struct EditBucketListItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    let item: BucketListItem
    @State private var title: String = ""
    @State private var detail: String = ""
    @State private var hasTargetDate: Bool = false
    @State private var targetDate: Date = Date()

    private let colorOptions: [(String, Color)] = [
        ("Lavender", Theme.softLavender),
        ("Peach", Theme.softPeach),
        ("Rose", Theme.dustyRose),
        ("Pink", Theme.softPink),
        ("Mint", Theme.softMint),
        ("Sky", Theme.softSky),
    ]
    @State private var selectedColor: Int = 0

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What's the dream?", text: $title)
                    TextField("Why does it matter? (optional)", text: $detail, axis: .vertical)
                        .lineLimit(2...5)
                } header: {
                    Text("Your Vision")
                        .foregroundStyle(Theme.accent)
                }
                Section {
                    Toggle(isOn: $hasTargetDate.animation(.spring(duration: 0.3))) {
                        Label("Target Date", systemImage: "calendar")
                            .foregroundStyle(Theme.deep)
                    }
                    .tint(Theme.accent)
                    if hasTargetDate {
                        DatePicker("Date", selection: $targetDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .tint(Theme.accent)
                    }
                } header: {
                    Text("When")
                        .foregroundStyle(Theme.accent)
                }
                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                        ForEach(0..<colorOptions.count, id: \.self) { idx in
                            Button {
                                selectedColor = idx
                            } label: {
                                Circle()
                                    .fill(colorOptions[idx].1)
                                    .frame(width: 36, height: 36)
                                    .overlay {
                                        if selectedColor == idx {
                                            Circle()
                                                .stroke(Theme.warmCream, lineWidth: 3)
                                                .frame(width: 28, height: 28)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Color")
                        .foregroundStyle(Theme.accent)
                }
            }
            .scrollContentBackground(.hidden)
            .background { Theme.pageBg }
            .navigationTitle("Edit Dream")
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
                        item.colorIndex = selectedColor
                        item.targetDate = hasTargetDate ? targetDate : nil
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(title.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Theme.accent)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .tint(Theme.accent)
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            title = item.title
            detail = item.detail
            selectedColor = item.colorIndex
            hasTargetDate = item.targetDate != nil
            targetDate = item.targetDate ?? Date()
        }
    }
}
