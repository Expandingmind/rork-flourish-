import SwiftUI
import RevenueCat

@Observable
class SubscriptionService {
    static let shared = SubscriptionService()

    static let entitlementID = "Flourish Pro"
    static let apiKey = "test_iSbNvojedsawhCuMMuLnEyTmgyt"

    var isProUser: Bool = false
    var customerInfo: CustomerInfo?

    private init() {}

    func configure(appUserID: String? = nil) {
        #if DEBUG
        Purchases.logLevel = .debug
        #endif
        Purchases.configure(withAPIKey: Self.apiKey, appUserID: appUserID)
    }

    func checkEntitlement() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            customerInfo = info
            isProUser = info.entitlements[Self.entitlementID]?.isActive == true
        } catch {
            isProUser = false
        }
    }

    func restorePurchases() async throws -> Bool {
        let info = try await Purchases.shared.restorePurchases()
        customerInfo = info
        isProUser = info.entitlements[Self.entitlementID]?.isActive == true
        return isProUser
    }

    func login(userID: String) async {
        do {
            let (info, _) = try await Purchases.shared.logIn(userID)
            customerInfo = info
            isProUser = info.entitlements[Self.entitlementID]?.isActive == true
        } catch {
            // silently fail
        }
    }

    func logout() async {
        do {
            let info = try await Purchases.shared.logOut()
            customerInfo = info
            isProUser = false
        } catch {
            // silently fail
        }
    }
}
