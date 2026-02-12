import SwiftUI
import SwiftData
import PhotosUI
import RevenueCat
import RevenueCatUI

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allEvidence: [EvidenceItem]
    @Query private var allActions: [DailyAction]
    @Query private var allDestinations: [TravelDestination]
    @Query private var allBucketItems: [BucketListItem]
    @Query(sort: \GardenPlant.createdDate) private var gardenPlants: [GardenPlant]
    @Query private var gardenResources: [GardenResource]
    @Query private var allMicroActions: [MicroAction]
    @Query private var allTodos: [TodoItem]

    private let authService = AuthService.shared

    @State private var showGarden: Bool = false
    @State private var showResetAlert: Bool = false
    @State private var showResetSuccess: Bool = false
    @State private var showProgressSummary: Bool = false
    @State private var showBackupShare: Bool = false
    @State private var showImportPicker: Bool = false
    @State private var showImportSuccess: Bool = false
    @State private var showImportError: Bool = false
    @State private var backupFileURL: URL? = nil
    @State private var notificationsEnabled: Bool = UserDefaults.standard.bool(forKey: "notificationsEnabled")
    @State private var dailyReminders: Bool = UserDefaults.standard.bool(forKey: "dailyReminders")
    @State private var hapticFeedback: Bool = UserDefaults.standard.object(forKey: "hapticFeedback") == nil ? true : UserDefaults.standard.bool(forKey: "hapticFeedback")
    @AppStorage("userName") private var userName: String = ""
    @State private var isEditingName: Bool = false
    @AppStorage("userUsername") private var userUsername: String = ""
    @State private var isEditingUsername: Bool = false
    @State private var userPassword: String = {
        let email = UserDefaults.standard.string(forKey: "authUserEmail") ?? ""
        if !email.isEmpty, let stored = KeychainService.load(forKey: "auth_email_\(email)") {
            return stored
        }
        return KeychainService.load(forKey: "userPassword") ?? ""
    }()
    @State private var isEditingPassword: Bool = false
    @State private var showPassword: Bool = false
    @AppStorage("appLockEnabled") private var appLockEnabled: Bool = false
    @State private var showLogoutAlert: Bool = false
    @State private var showDeleteAccountAlert: Bool = false
    @State private var showPaywall: Bool = false
    @State private var showCustomerCenter: Bool = false

    @AppStorage("userFocusArea") private var userFocusArea: String = ""
    @State private var profileImageData: Data? = UserDefaults.standard.data(forKey: "profileImageData")
    @State private var selectedPhotoItem: PhotosPickerItem? = nil

    private var totalWins: Int {
        allEvidence.count
    }

    private var totalSaved: Double {
        allEvidence.filter { $0.category == "saving" }.reduce(0) { $0 + $1.amount }
    }

    private var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var date = Date.now
        let sorted = allActions.sorted { $0.createdDate > $1.createdDate }
        for action in sorted {
            if calendar.isDate(action.createdDate, inSameDayAs: date) {
                streak += 1
                date = calendar.date(byAdding: .day, value: -1, to: date) ?? date
            } else {
                break
            }
        }
        return max(streak, allActions.isEmpty ? 0 : 1)
    }

    private var placesVisited: Int {
        allDestinations.filter(\.isVisited).count
    }

    private var bucketCompleted: Int {
        allBucketItems.filter(\.isCompleted).count
    }

    private var memberSince: String {
        let joinDate = authService.memberSinceDate
        let earliest = allActions.map(\.createdDate).min() ?? joinDate
        let date = earliest < joinDate ? earliest : joinDate
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    heroSection
                    contentSection
                }
            }
            .background {
                ZStack {
                    VStack(spacing: 0) {
                        Color(red: 0.98, green: 0.96, blue: 0.93)
                        Color(red: 0.98, green: 0.96, blue: 0.93)
                    }
                    .ignoresSafeArea()
                    BackgroundFlowerScatter(seed: 5)
                }
            }
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showGarden) {
                BloomGardenView()
            }
            .sheet(isPresented: $showPaywall) {
                RevenueCatUI.PaywallView(displayCloseButton: true)
                    .onPurchaseCompleted { customerInfo in
                        if customerInfo.entitlements[SubscriptionService.entitlementID]?.isActive == true {
                            SubscriptionService.shared.isProUser = true
                        }
                    }
                    .onRestoreCompleted { customerInfo in
                        if customerInfo.entitlements[SubscriptionService.entitlementID]?.isActive == true {
                            SubscriptionService.shared.isProUser = true
                        }
                    }
            }
            .presentCustomerCenter(isPresented: $showCustomerCenter)
            .sheet(isPresented: $showProgressSummary) {
                ProgressSummaryView()
            }
            .sheet(isPresented: $showBackupShare) {
                if let backupFileURL {
                    ShareSheet(activityItems: [backupFileURL])
                }
            }
            .fileImporter(isPresented: $showImportPicker, allowedContentTypes: [.json]) { result in
                handleImport(result)
            }
            .alert("Data Restored", isPresented: $showImportSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your backup has been restored successfully.")
            }
            .alert("Restore Failed", isPresented: $showImportError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Could not read the backup file. Please make sure it is a valid Flourish backup.")
            }
        }
    }

    private var heroSection: some View {
        Button {
            showGarden = true
        } label: {
            GardenPreviewView(plants: gardenPlants, resources: gardenResources)
        }
        .buttonStyle(.plain)
    }

    private var contentSection: some View {
        VStack(spacing: 24) {
            profileIdentity
                .padding(.top, 24)

            proUpgradeButton

            progressSummaryButton

            statsRow

            activitySection

            aboutSection

            settingsSection
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 100)
    }

    private var profileIdentity: some View {
        VStack(spacing: 14) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                if let profileImageData, let uiImage = UIImage(data: profileImageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 90, height: 90)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Theme.softPink.opacity(0.4), lineWidth: 2.5)
                        )
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(Theme.accent)
                                .background(Circle().fill(.white).padding(2))
                        }
                        .shadow(color: Theme.softPink.opacity(0.15), radius: 8, y: 3)
                } else {
                    Circle()
                        .fill(Theme.softPink.opacity(0.1))
                        .frame(width: 90, height: 90)
                        .overlay(
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 32, weight: .light))
                                .foregroundStyle(Theme.softPink)
                        )
                        .overlay(
                            Circle()
                                .stroke(Theme.softPink.opacity(0.2), lineWidth: 2)
                        )
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let newItem, let data = try? await newItem.loadTransferable(type: Data.self) {
                        if let img = UIImage(data: data), let compressed = img.jpegData(compressionQuality: 0.7) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                profileImageData = compressed
                            }
                            authService.saveUserData("profileImageData", data: compressed)
                        }
                    }
                }
            }

            Text(userName.isEmpty ? "Building an unconventional life." : userName)
                .font(Theme.title2Font)
                .fontWeight(.heavy)
                .foregroundStyle(Theme.deep)
                .multilineTextAlignment(.center)

            if !authService.currentUserEmail.isEmpty {
                Text(authService.currentUserEmail)
                    .font(Theme.font(13))
                    .foregroundStyle(Theme.deep.opacity(0.4))
            }

            if !userFocusArea.isEmpty {
                Text(userFocusArea)
                    .font(Theme.subheadlineFont)
                    .foregroundStyle(Theme.accent.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var proUpgradeButton: some View {
        Group {
            if SubscriptionService.shared.isProUser {
                Button {
                    showCustomerCenter = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.mint.opacity(0.15), Theme.softSky.opacity(0.15)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 48, height: 48)
                            Image(systemName: "crown.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Theme.gold, Theme.roseGold],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Flourish Pro")
                                .font(Theme.fontBold(16))
                                .foregroundStyle(Theme.deep)
                            Text("Manage your subscription")
                                .font(Theme.font(13))
                                .foregroundStyle(Theme.deep.opacity(0.5))
                        }

                        Spacer()

                        Text("Active")
                            .font(Theme.fontBold(13))
                            .foregroundStyle(Theme.mint)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Theme.mint.opacity(0.12))
                            .clipShape(.capsule)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Theme.cardBackground)
                            .shadow(color: .black.opacity(0.04), radius: 10, y: 3)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Theme.mint.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.softPink.opacity(0.15), Theme.lavender.opacity(0.15)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 48, height: 48)
                            Image(systemName: "sparkles")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Theme.accent, Theme.lavender],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Flourish Pro")
                                .font(Theme.fontBold(16))
                                .foregroundStyle(Theme.deep)
                            Text("Unlock all premium features")
                                .font(Theme.font(13))
                                .foregroundStyle(Theme.deep.opacity(0.5))
                        }

                        Spacer()

                        Text("Upgrade")
                            .font(Theme.fontBold(13))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                LinearGradient(
                                    colors: [Theme.accent, Theme.roseGold],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(.capsule)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Theme.cardBackground)
                            .shadow(color: .black.opacity(0.04), radius: 10, y: 3)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                LinearGradient(
                                    colors: [Theme.softPink.opacity(0.4), Theme.lavender.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var progressSummaryButton: some View {
        Button {
            showProgressSummary = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Theme.lavender.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Theme.lavender)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Progress Summary")
                        .font(Theme.fontBold(16))
                        .foregroundStyle(Theme.deep)
                    Text("View your weekly and monthly stats")
                        .font(Theme.font(13))
                        .foregroundStyle(Theme.deep.opacity(0.5))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.deep.opacity(0.3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Theme.cardBackground)
                    .shadow(color: .black.opacity(0.04), radius: 10, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Theme.lavender.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell(value: "\(totalWins)", label: "Evidence", icon: "bolt.fill", color: Theme.mint)
            divider
            statCell(value: "$\(Int(totalSaved))", label: "Reclaimed", icon: "banknote.fill", color: Theme.cream)
            divider
            statCell(value: "\(placesVisited)", label: "Visited", icon: "airplane", color: Theme.sage)
        }
        .padding(.vertical, 20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.cardBackground)
                .shadow(color: .black.opacity(0.04), radius: 12, y: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Theme.dustyRose.opacity(0.5), lineWidth: 1)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color(.separator))
            .frame(width: 1, height: 40)
    }

    private func statCell(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(Theme.captionFont)
                .foregroundStyle(color)
            Text(value)
                .font(Theme.title3Font)
                .fontWeight(.heavy)
                .foregroundStyle(.primary)
            Text(label)
                .font(Theme.caption2Font)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ACTIVITY")
                .font(Theme.captionFont)
                .fontWeight(.bold)
                .foregroundStyle(.tertiary)
                .tracking(1.2)

            VStack(spacing: 0) {
                activityRow(icon: "flame.fill", color: Theme.cream, label: "Current Streak", value: "\(currentStreak) day\(currentStreak == 1 ? "" : "s")")
                Divider().padding(.leading, 52)
                activityRow(icon: "checkmark.diamond.fill", color: Theme.mint, label: "Bucket List Done", value: "\(bucketCompleted)")
                Divider().padding(.leading, 52)
                activityRow(icon: "list.clipboard.fill", color: Theme.sage, label: "Total Actions Logged", value: "\(allActions.count)")
                Divider().padding(.leading, 52)
                activityRow(icon: "calendar", color: Theme.cream, label: "Member Since", value: memberSince)
            }
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

    private func activityRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(Theme.bodyFont)
                .foregroundStyle(color)
                .frame(width: 28)
            Text(label)
                .font(Theme.subheadlineFont)
                .foregroundStyle(.primary)
            Spacer()
            Text(value)
                .font(Theme.subheadlineFont)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("HIGHLIGHTS")
                .font(Theme.captionFont)
                .fontWeight(.bold)
                .foregroundStyle(.tertiary)
                .tracking(1.2)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                highlightCard(icon: "sparkles", title: "\(totalWins)", subtitle: "Wins Logged", color: Theme.mint)
                highlightCard(icon: "dollarsign.circle.fill", title: "$\(Int(totalSaved))", subtitle: "Money Reclaimed", color: Theme.cream)
                highlightCard(icon: "globe.americas.fill", title: "\(allDestinations.count)", subtitle: "Dream Destinations", color: Theme.sage)
                highlightCard(icon: "heart.text.clipboard.fill", title: "\(allBucketItems.count)", subtitle: "Bucket List Items", color: Theme.mint)
            }
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SETTINGS")
                .font(Theme.captionFont)
                .fontWeight(.bold)
                .foregroundStyle(.tertiary)
                .tracking(1.2)

            VStack(spacing: 0) {
                settingsNameRow
                Divider().padding(.leading, 52)
                settingsUsernameRow
                Divider().padding(.leading, 52)
                settingsPasswordRow
                Divider().padding(.leading, 52)
                settingsToggleRow(icon: "lock.shield.fill", color: Theme.lavender, label: "App Lock", isOn: $appLockEnabled) { _ in }
                Divider().padding(.leading, 52)
                settingsToggleRow(icon: "bell.fill", color: Theme.cream, label: "Notifications", isOn: $notificationsEnabled) { enabled in
                    UserDefaults.standard.set(enabled, forKey: "notificationsEnabled")
                    if enabled {
                        Task {
                            let granted = await NotificationService.requestPermission()
                            if !granted {
                                notificationsEnabled = false
                                UserDefaults.standard.set(false, forKey: "notificationsEnabled")
                                dailyReminders = false
                                UserDefaults.standard.set(false, forKey: "dailyReminders")
                            }
                        }
                    } else {
                        NotificationService.cancelAllNotifications()
                        dailyReminders = false
                        UserDefaults.standard.set(false, forKey: "dailyReminders")
                    }
                }
                Divider().padding(.leading, 52)
                settingsToggleRow(icon: "calendar.badge.clock", color: Theme.mint, label: "Daily Reminders", isOn: $dailyReminders) { enabled in
                    UserDefaults.standard.set(enabled, forKey: "dailyReminders")
                    if enabled {
                        if !notificationsEnabled {
                            Task {
                                let granted = await NotificationService.requestPermission()
                                if granted {
                                    notificationsEnabled = true
                                    UserDefaults.standard.set(true, forKey: "notificationsEnabled")
                                    NotificationService.scheduleDailyReminder()
                                } else {
                                    dailyReminders = false
                                    UserDefaults.standard.set(false, forKey: "dailyReminders")
                                }
                            }
                        } else {
                            NotificationService.scheduleDailyReminder()
                        }
                    } else {
                        NotificationService.cancelDailyReminder()
                    }
                }
                Divider().padding(.leading, 52)
                settingsToggleRow(icon: "hand.tap.fill", color: Theme.sage, label: "Haptic Feedback", isOn: $hapticFeedback) {
                    UserDefaults.standard.set($0, forKey: "hapticFeedback")
                }
                Divider().padding(.leading, 52)
                settingsButtonRow(icon: "square.and.arrow.up.fill", color: Theme.softSky, label: "Export Backup") {
                    exportBackup()
                }
                Divider().padding(.leading, 52)
                settingsButtonRow(icon: "square.and.arrow.down.fill", color: Theme.softSky, label: "Restore Backup") {
                    showImportPicker = true
                }
                Divider().padding(.leading, 52)
                settingsButtonRow(icon: "arrow.counterclockwise", color: Theme.dustyRose, label: "Reset All Data") {
                    showResetAlert = true
                }
                Divider().padding(.leading, 52)
                logoutRow
                Divider().padding(.leading, 52)
                deleteAccountRow
                Divider().padding(.leading, 52)
                settingsLinkRow(icon: "doc.text.fill", color: Theme.sage, label: "Terms & Conditions", urlString: "https://flourish-app-three.vercel.app/terms.html")
                Divider().padding(.leading, 52)
                settingsLinkRow(icon: "hand.raised.fill", color: Theme.lavender, label: "Privacy Policy", urlString: "https://flourish-app-three.vercel.app/privacy.html")
                Divider().padding(.leading, 52)
                settingsInfoRow(icon: "info.circle.fill", color: Theme.accent, label: "Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
            }
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
        .alert("Reset All Data", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This will permanently delete all your evidence, actions, destinations, bucket list items, and garden. This cannot be undone.")
        }
        .alert("Data Reset", isPresented: $showResetSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("All data has been cleared successfully.")
        }
        .alert("Log Out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                authService.logout()
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                resetAllData()
                authService.deleteAccount()
            }
        } message: {
            Text("This will permanently delete your account and all data. This cannot be undone.")
        }
    }

    private var logoutRow: some View {
        Button {
            showLogoutAlert = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.roseGold)
                    .frame(width: 28)
                Text("Log Out")
                    .font(Theme.subheadlineFont)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(Theme.caption2Font)
                    .fontWeight(.semibold)
                    .foregroundStyle(.quaternary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    private var deleteAccountRow: some View {
        Button {
            showDeleteAccountAlert = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "person.crop.circle.badge.minus")
                    .font(Theme.bodyFont)
                    .foregroundStyle(.red)
                    .frame(width: 28)
                Text("Delete Account")
                    .font(Theme.subheadlineFont)
                    .foregroundStyle(.red)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(Theme.caption2Font)
                    .fontWeight(.semibold)
                    .foregroundStyle(.quaternary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    private var settingsUsernameRow: some View {
        HStack(spacing: 14) {
            Image(systemName: "at")
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.mint)
                .frame(width: 28)
            if isEditingUsername {
                TextField("Username", text: $userUsername)
                    .font(Theme.subheadlineFont)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onSubmit {
                        isEditingUsername = false
                        authService.saveUserData("userUsername", value: userUsername)
                    }
            } else {
                Text(userUsername.isEmpty ? "Set Username" : userUsername)
                    .font(Theme.subheadlineFont)
                    .foregroundStyle(userUsername.isEmpty ? .tertiary : .primary)
            }
            Spacer()
            Button {
                if isEditingUsername {
                    authService.saveUserData("userUsername", value: userUsername)
                }
                isEditingUsername.toggle()
            } label: {
                Image(systemName: isEditingUsername ? "checkmark.circle.fill" : "pencil.circle.fill")
                    .foregroundStyle(Theme.accent)
                    .font(Theme.bodyFont)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var settingsPasswordRow: some View {
        HStack(spacing: 14) {
            Image(systemName: "lock.fill")
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.sage)
                .frame(width: 28)
            if isEditingPassword {
                Group {
                    if showPassword {
                        TextField("Password", text: $userPassword)
                    } else {
                        SecureField("Password", text: $userPassword)
                    }
                }
                .font(Theme.subheadlineFont)
                .textFieldStyle(.plain)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit { isEditingPassword = false }
            } else {
                Text(userPassword.isEmpty ? "Set Password" : String(repeating: "\u{2022}", count: userPassword.count))
                    .font(Theme.subheadlineFont)
                    .foregroundStyle(userPassword.isEmpty ? .tertiary : .primary)
            }
            Spacer()
            if isEditingPassword {
                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundStyle(.secondary)
                        .font(Theme.captionFont)
                }
            }
            Button {
                if isEditingPassword {
                    isEditingPassword = false
                    showPassword = false
                    KeychainService.save(userPassword, forKey: "userPassword")
                    authService.updatePassword(newPassword: userPassword)
                } else {
                    isEditingPassword = true
                }
            } label: {
                Image(systemName: isEditingPassword ? "checkmark.circle.fill" : "pencil.circle.fill")
                    .foregroundStyle(Theme.accent)
                    .font(Theme.bodyFont)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var settingsNameRow: some View {
        HStack(spacing: 14) {
            Image(systemName: "person.fill")
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.blush)
                .frame(width: 28)
            if isEditingName {
                TextField("Your Name", text: $userName)
                    .font(Theme.subheadlineFont)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        isEditingName = false
                        authService.saveUserData("userName", value: userName)
                    }
            } else {
                Text(userName.isEmpty ? "Set Your Name" : userName)
                    .font(Theme.subheadlineFont)
                    .foregroundStyle(userName.isEmpty ? .tertiary : .primary)
            }
            Spacer()
            Button {
                if isEditingName {
                    isEditingName = false
                    authService.saveUserData("userName", value: userName)
                } else {
                    isEditingName = true
                }
            } label: {
                Image(systemName: isEditingName ? "checkmark.circle.fill" : "pencil.circle.fill")
                    .foregroundStyle(Theme.accent)
                    .font(Theme.bodyFont)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func settingsToggleRow(icon: String, color: Color, label: String, isOn: Binding<Bool>, onChange: @escaping (Bool) -> Void) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(Theme.bodyFont)
                .foregroundStyle(color)
                .frame(width: 28)
            Text(label)
                .font(Theme.subheadlineFont)
                .foregroundStyle(.primary)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Theme.accent)
                .onChange(of: isOn.wrappedValue) { _, newValue in
                    onChange(newValue)
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func settingsButtonRow(icon: String, color: Color, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(Theme.bodyFont)
                    .foregroundStyle(color)
                    .frame(width: 28)
                Text(label)
                    .font(Theme.subheadlineFont)
                    .foregroundStyle(color == Theme.dustyRose ? .red : .primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(Theme.caption2Font)
                    .fontWeight(.semibold)
                    .foregroundStyle(.quaternary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    private func settingsLinkRow(icon: String, color: Color, label: String, urlString: String) -> some View {
        Button {
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(Theme.bodyFont)
                    .foregroundStyle(color)
                    .frame(width: 28)
                Text(label)
                    .font(Theme.subheadlineFont)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(Theme.caption2Font)
                    .fontWeight(.semibold)
                    .foregroundStyle(.quaternary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    private func settingsInfoRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(Theme.bodyFont)
                .foregroundStyle(color)
                .frame(width: 28)
            Text(label)
                .font(Theme.subheadlineFont)
                .foregroundStyle(.primary)
            Spacer()
            Text(value)
                .font(Theme.subheadlineFont)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }


    private func resetAllData() {
        for item in allEvidence { modelContext.delete(item) }
        for item in allActions { modelContext.delete(item) }
        for item in allDestinations { modelContext.delete(item) }
        for item in allBucketItems { modelContext.delete(item) }
        for plant in gardenPlants { modelContext.delete(plant) }
        for resource in gardenResources { modelContext.delete(resource) }
        for item in allMicroActions { modelContext.delete(item) }
        for item in allTodos { modelContext.delete(item) }
        try? modelContext.save()
        showResetSuccess = true
    }

    private func exportBackup() {
        do {
            let url = try BackupService.exportToFile(context: modelContext)
            backupFileURL = url
            showBackupShare = true
        } catch {
            // silently fail
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                showImportError = true
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            do {
                let data = try Data(contentsOf: url)
                try BackupService.importData(data, context: modelContext)
                showImportSuccess = true
            } catch {
                showImportError = true
            }
        case .failure:
            showImportError = true
        }
    }

    private func highlightCard(icon: String, title: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(Theme.title3Font)
                .foregroundStyle(color)
            Text(title)
                .font(Theme.title3Font)
                .fontWeight(.heavy)
                .foregroundStyle(.primary)
            Text(subtitle)
                .font(Theme.caption2Font)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
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

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
