import SwiftUI
import SwiftData
import LocalAuthentication
import RevenueCat

@main
struct JourneyOfAmbitionApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("appLockEnabled") private var appLockEnabled: Bool = false
    @State private var isUnlocked: Bool = false
    @State private var isLoading: Bool = true
    @State private var isSubscribed: Bool = false
    @State private var hasCheckedSubscription: Bool = false
    @State private var authService = AuthService.shared
    @State private var subscriptionService = SubscriptionService.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        SubscriptionService.shared.configure(appUserID: "ofrng804b46c3f8")
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isLoading {
                    LoadingScreenView()
                        .transition(.opacity)
                } else if !authService.isAuthenticated {
                    AuthView(authService: authService)
                } else if appLockEnabled && !isUnlocked {
                    AppLockView(isUnlocked: $isUnlocked)
                } else if !hasCompletedOnboarding {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                } else if !hasCheckedSubscription {
                    LoadingScreenView()
                        .task {
                            await checkSubscription()
                        }
                } else if !isSubscribed {
                    PaywallGateView(isSubscribed: $isSubscribed)
                } else {
                    ContentView()
                }
            }
            .preferredColorScheme(.light)
            .task {
                try? await Task.sleep(for: .seconds(2.2))
                withAnimation(.easeOut(duration: 0.4)) {
                    isLoading = false
                }
            }
            .onChange(of: hasCompletedOnboarding) { _, completed in
                if completed {
                    hasCheckedSubscription = false
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background && appLockEnabled {
                    isUnlocked = false
                }
            }
        }
        .modelContainer(for: [
            DailyAction.self,
            EvidenceItem.self,
            TravelDestination.self,
            Goal.self,
            BucketListItem.self,
            TodoItem.self,
            MicroAction.self,
            GardenPlant.self,
            GardenResource.self,
        ])
    }

    private func checkSubscription() async {
        await subscriptionService.checkEntitlement()
        isSubscribed = subscriptionService.isProUser
        hasCheckedSubscription = true
    }
}
