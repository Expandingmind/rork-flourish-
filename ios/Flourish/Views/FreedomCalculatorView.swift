import SwiftUI

struct FreedomCalculatorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var monthlyExpenses: String = ""
    @State private var monthlySavings: String = ""
    @State private var currentSavings: String = ""
    @State private var hasCalculated: Bool = false

    private var expenses: Double { Double(monthlyExpenses) ?? 0 }
    private var savings: Double { Double(monthlySavings) ?? 0 }
    private var current: Double { Double(currentSavings) ?? 0 }

    private var freedomNumber: Double {
        expenses * 12
    }

    private var monthsToFreedom: Int {
        guard savings > 0 else { return 0 }
        let remaining = max(freedomNumber - current, 0)
        return Int(ceil(remaining / savings))
    }

    private var yearsMonths: (Int, Int) {
        (monthsToFreedom / 12, monthsToFreedom % 12)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Freedom Number")
                            .font(Theme.largeTitleFont)
                            .fontWeight(.bold)
                            .foregroundStyle(Theme.deep)
                        Text("Your freedom number is 12 months of expenses — the point where you have a full year of runway to build your life on your terms.")
                            .font(Theme.subheadlineFont)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 16) {
                        inputField(label: "Monthly expenses", placeholder: "3000", text: $monthlyExpenses)
                        inputField(label: "Monthly savings toward freedom", placeholder: "500", text: $monthlySavings)
                        inputField(label: "Current savings", placeholder: "2000", text: $currentSavings)
                    }
                    .padding(20)
                    .background {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Theme.cardBackground)
                            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                    }

                    Button {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        withAnimation(.spring(duration: 0.5)) {
                            hasCalculated = true
                        }
                    } label: {
                        Text("Calculate")
                            .font(Theme.bodyFont)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.gold, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(expenses <= 0)

                    if hasCalculated && expenses > 0 {
                        resultCard
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
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

    private func inputField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(Theme.captionFont)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            HStack {
                Text("$")
                    .foregroundStyle(.tertiary)
                    .font(Theme.bodyFont)
                TextField(placeholder, text: text)
                    .keyboardType(.numberPad)
                    .font(Theme.title3Font)
                    .fontWeight(.semibold)
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.lavenderLight.opacity(0.4))
            }
        }
    }

    private var resultCard: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("YOUR FREEDOM NUMBER")
                    .font(Theme.captionFont)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.gold)
                    .tracking(1.2)
                Text("$\(Int(freedomNumber))")
                    .font(Theme.fontBold(48))
                    .foregroundStyle(Theme.deep)
                Text("One year of total runway.")
                    .font(Theme.subheadlineFont)
                    .foregroundStyle(.secondary)
            }

            Divider()

            if savings > 0 {
                VStack(spacing: 8) {
                    let (years, months) = yearsMonths
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        if years > 0 {
                            Text("\(years)")
                                .font(Theme.fontBold(36))
                                .foregroundStyle(Theme.accent)
                            Text(years == 1 ? "year" : "years")
                                .font(Theme.bodyFont)
                                .foregroundStyle(.secondary)
                        }
                        if months > 0 {
                            Text("\(months)")
                                .font(Theme.fontBold(36))
                                .foregroundStyle(Theme.accent)
                            Text(months == 1 ? "month" : "months")
                                .font(Theme.bodyFont)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text("at your current pace.")
                        .font(Theme.subheadlineFont)
                        .foregroundStyle(.secondary)

                    if current > 0 {
                        let progress = min(current / freedomNumber, 1.0)
                        VStack(spacing: 6) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Theme.mint.opacity(0.4))
                                        .frame(height: 8)
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Theme.sage)
                                        .frame(width: geo.size.width * progress, height: 8)
                                }
                            }
                            .frame(height: 8)
                            Text("\(Int(progress * 100))% there")
                                .font(Theme.captionFont)
                                .fontWeight(.bold)
                                .foregroundStyle(Theme.sage)
                        }
                        .padding(.top, 8)
                    }
                }
            }

            Text("Every dollar saved is a step closer to building life on your terms. Not someday — on a timeline you control.")
                .font(Theme.captionFont)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.cardBackground)
                .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
        }
    }
}
