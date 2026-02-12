import SwiftUI

struct RoadmapStep: Identifiable {
    let id: Int
    let title: String
    let description: String
    let icon: String
    let actions: [String]
    var isCompleted: Bool
}

struct RemoteWorkRoadmapView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var steps: [RoadmapStep] = {
        let saved = UserDefaults.standard.array(forKey: "roadmapCompletedSteps") as? [Int] ?? []
        return [
            RoadmapStep(id: 0, title: "Skills Audit", description: "Identify what you already have that's valuable remotely.", icon: "magnifyingglass", actions: [
                "List your top 5 professional skills",
                "Research which are in-demand for remote roles",
                "Identify skill gaps to fill",
            ], isCompleted: saved.contains(0)),
            RoadmapStep(id: 1, title: "Portfolio Build", description: "Create tangible proof of your capabilities.", icon: "doc.richtext", actions: [
                "Choose 3 best work samples",
                "Create a simple portfolio site",
                "Write case studies for key projects",
            ], isCompleted: saved.contains(1)),
            RoadmapStep(id: 2, title: "Network Strategically", description: "Connect with women already living this life.", icon: "person.2.fill", actions: [
                "Join 2 remote work communities",
                "Reach out to 5 women in your target field",
                "Attend one virtual networking event",
            ], isCompleted: saved.contains(2)),
            RoadmapStep(id: 3, title: "Apply with Strategy", description: "Quality over quantity. Target roles that align.", icon: "paperplane.fill", actions: [
                "Create a target company list (20+)",
                "Customize resume for remote-first roles",
                "Apply to 5 aligned positions per week",
            ], isCompleted: saved.contains(3)),
            RoadmapStep(id: 4, title: "Negotiate Your Terms", description: "You set the terms. Not the other way around.", icon: "hand.raised.fill", actions: [
                "Research market rates for your role",
                "Practice negotiation conversations",
                "Know your non-negotiables before any call",
            ], isCompleted: saved.contains(4)),
            RoadmapStep(id: 5, title: "Launch Your Life", description: "You've done the work. Now live it.", icon: "airplane.departure", actions: [
                "Set your first remote work start date",
                "Plan your first work-from-anywhere trip",
                "Celebrate — you built this.",
            ], isCompleted: saved.contains(5)),
        ]
    }()

    private var completedCount: Int {
        steps.filter(\.isCompleted).count
    }

    private var progress: Double {
        Double(completedCount) / Double(steps.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Remote Work Roadmap")
                            .font(Theme.largeTitleFont)
                            .fontWeight(.bold)
                            .foregroundStyle(Theme.deep)
                        Text("Your step-by-step path to location independence. No shortcuts, no fluff — just strategy.")
                            .font(Theme.subheadlineFont)
                            .foregroundStyle(.secondary)
                    }

                    progressBar

                    ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                        stepCard(step, index: index)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background { Theme.pageBg }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var progressBar: some View {
        VStack(spacing: 10) {
            HStack {
                Text("\(completedCount) of \(steps.count) phases complete")
                    .font(Theme.subheadlineFont)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(Theme.subheadlineFont)
                    .fontWeight(.heavy)
                    .foregroundStyle(Theme.sage)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.mint.opacity(0.4))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.sage)
                        .frame(width: geo.size.width * progress, height: 8)
                        .animation(.spring(duration: 0.5), value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        }
    }

    private func saveProgress() {
        let completedIds = steps.filter(\.isCompleted).map(\.id)
        UserDefaults.standard.set(completedIds, forKey: "roadmapCompletedSteps")
    }

    private func stepCard(_ step: RoadmapStep, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(step.isCompleted ? Theme.sage : Theme.sage.opacity(0.12))
                        .frame(width: 40, height: 40)
                    if step.isCompleted {
                        Image(systemName: "checkmark")
                            .font(Theme.bodyFont)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    } else {
                        Text("\(index + 1)")
                            .font(Theme.headlineFont)
                            .fontWeight(.bold)
                            .foregroundStyle(Theme.sage)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(step.title)
                        .font(Theme.headlineFont)
                        .foregroundStyle(step.isCompleted ? .secondary : .primary)
                    Text(step.description)
                        .font(Theme.captionFont)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    withAnimation(.spring(duration: 0.4)) {
                        steps[index].isCompleted.toggle()
                    }
                    saveProgress()
                } label: {
                    Text(step.isCompleted ? "Done" : "Mark Done")
                        .font(Theme.captionFont)
                        .fontWeight(.bold)
                        .foregroundStyle(step.isCompleted ? Theme.sage : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background {
                            Capsule()
                                .fill(step.isCompleted ? Theme.sage.opacity(0.12) : Theme.cream.opacity(0.4))
                        }
                }
                .buttonStyle(.plain)
            }

            if !step.isCompleted {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(step.actions, id: \.self) { action in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(Theme.cream.opacity(0.7))
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)
                            Text(action)
                                .font(Theme.subheadlineFont)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.leading, 54)
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.cardBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        }
    }
}
