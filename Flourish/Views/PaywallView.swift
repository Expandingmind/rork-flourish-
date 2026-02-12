import SwiftUI
import RevenueCat
import RevenueCatUI

struct PaywallGateView: View {
    @Binding var isSubscribed: Bool
    @State private var offering: Offering?
    @State private var availableIDs: [String] = []
    @State private var loadError: String?

    var body: some View {
        Group {
            if let offering {
                RevenueCatUI.PaywallView(offering: offering, displayCloseButton: false)
                    .onPurchaseCompleted { customerInfo in
                        handleCustomerInfo(customerInfo)
                    }
                    .onRestoreCompleted { customerInfo in
                        handleCustomerInfo(customerInfo)
                    }
            } else if !availableIDs.isEmpty {
                VStack(spacing: 16) {
                    Text("Available Offerings")
                        .font(.headline)
                    ForEach(availableIDs, id: \.self) { id in
                        Text(id)
                            .font(.system(.body, design: .monospaced))
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(.rect(cornerRadius: 8))
                    }
                    if let loadError {
                        Text(loadError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: "#fdf8f1"))
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(hex: "#fdf8f1"))
            }
        }
        .ignoresSafeArea()
        .task {
            await loadOffering()
        }
    }

    private func loadOffering() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            availableIDs = offerings.all.keys.sorted()
            
            let identifiersToTry = ["ofrng804b46c3f8", "default_2", "default2", "Flourish_2", "flourish_2", "Flourish 2", "flourish2"]
            for id in identifiersToTry {
                if let found = offerings.offering(identifier: id) {
                    offering = found
                    return
                }
            }
            
            offering = offerings.current
            loadError = "Could not find offering. Available: \(availableIDs.joined(separator: ", "))"
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func handleCustomerInfo(_ customerInfo: CustomerInfo) {
        if customerInfo.entitlements[SubscriptionService.entitlementID]?.isActive == true {
            SubscriptionService.shared.isProUser = true
            withAnimation(.easeInOut(duration: 0.4)) {
                isSubscribed = true
            }
        }
    }
}

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
