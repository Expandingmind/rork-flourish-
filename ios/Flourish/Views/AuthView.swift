import SwiftUI

struct AuthView: View {
    var authService: AuthService
    @State private var isSignUp: Bool = true
    @State private var selectedMode: AuthMode? = nil
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @State private var formOffset: CGFloat = 40
    @State private var formOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var isLoading: Bool = false
    @State private var successScale: CGFloat = 0.8
    @State private var showSuccess: Bool = false
    @State private var shimmerOffset: CGFloat = -200
    @State private var featureCardsOpacity: Double = 0
    @State private var featureCardsOffset: CGFloat = 30
    @State private var showForgotPassword: Bool = false
    @State private var forgotEmail: String = ""
    @State private var newPassword: String = ""
    @State private var confirmNewPassword: String = ""
    @State private var forgotStep: Int = 0
    @State private var forgotError: String = ""
    @State private var showForgotError: Bool = false
    @State private var showResetSuccess: Bool = false
    @FocusState private var focusedField: AuthField?

    private enum AuthMode {
        case signUp, logIn
    }

    private enum AuthField {
        case email, password, confirmPassword, forgotEmail, newPassword, confirmNewPassword
    }

    private var isFormValid: Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if isSignUp {
            return !trimmedEmail.isEmpty && password.count >= 6 && password == confirmPassword
        } else {
            return !trimmedEmail.isEmpty && !password.isEmpty
        }
    }

    var body: some View {
        ZStack {
            backgroundLayer

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)

                    heroSection
                        .padding(.bottom, 32)

                    if selectedMode == nil {
                        featureHighlights
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)
                            .opacity(featureCardsOpacity)
                            .offset(y: featureCardsOffset)
                    }

                    formCard
                        .padding(.horizontal, 24)
                        .offset(y: formOffset)
                        .opacity(formOpacity)

                    Spacer().frame(height: 50)
                }
            }
            .scrollDismissesKeyboard(.interactively)

            if showSuccess {
                successOverlay
            }
        }
        .sheet(isPresented: $showForgotPassword) {
            forgotPasswordSheet
        }
        .onAppear {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.65)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.35)) {
                formOffset = 0
                formOpacity = 1.0
            }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(0.5)) {
                shimmerOffset = 200
            }
            withAnimation(.easeOut(duration: 0.7).delay(0.55)) {
                featureCardsOpacity = 1.0
                featureCardsOffset = 0
            }
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.94, blue: 0.92),
                    Theme.beige,
                    Color(red: 0.96, green: 0.93, blue: 0.95),
                    Color(red: 0.97, green: 0.95, blue: 0.90)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            floatingOrbs
            BackgroundFlowerScatter()
        }
    }

    private var floatingOrbs: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.softPink.opacity(0.18), Theme.softPink.opacity(0.0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 90
                    )
                )
                .frame(width: 180, height: 180)
                .position(x: w * 0.15, y: h * 0.12)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.lavenderMist.opacity(0.2), Theme.lavenderMist.opacity(0.0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 110
                    )
                )
                .frame(width: 220, height: 220)
                .position(x: w * 0.88, y: h * 0.28)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.gold.opacity(0.14), Theme.gold.opacity(0.0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .position(x: w * 0.25, y: h * 0.52)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.mint.opacity(0.12), Theme.mint.opacity(0.0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 70
                    )
                )
                .frame(width: 140, height: 140)
                .position(x: w * 0.82, y: h * 0.68)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.softPink.opacity(0.15), Theme.softPink.opacity(0.0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .position(x: w * 0.1, y: h * 0.85)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Theme.lavender.opacity(0.13), Theme.lavender.opacity(0.0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 85
                    )
                )
                .frame(width: 170, height: 170)
                .position(x: w * 0.75, y: h * 0.92)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var heroSection: some View {
        VStack(spacing: 18) {
            Image(uiImage: UIImage(named: "AppIcon") ?? UIImage())
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 110, height: 110)
                .clipShape(Circle())
                .shadow(color: Theme.softPink.opacity(0.25), radius: 16, y: 6)
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

            VStack(spacing: 8) {
                Text("Flourish")
                    .font(Theme.fontBold(52))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.deep, Theme.softPink.opacity(0.8), Theme.deep.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("Grow into the life you deserve")
                    .font(Theme.font(16))
                    .foregroundStyle(Theme.deep.opacity(0.45))
                    .italic()
            }
            .opacity(logoOpacity)
        }
    }

    private var formCard: some View {
        VStack(spacing: 22) {
            if selectedMode == nil {
                collapsedAuthButtons
            } else {
                expandedFormContent
            }
        }
        .padding(26)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.92),
                                Color(red: 1.0, green: 0.98, blue: 0.96).opacity(0.88)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [Theme.softPink.opacity(0.05), Theme.lavenderMist.opacity(0.04), Theme.gold.opacity(0.03)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    LinearGradient(
                        colors: [
                            Theme.softPink.opacity(0.2),
                            Theme.lavenderMist.opacity(0.15),
                            Theme.gold.opacity(0.12),
                            Theme.mint.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Theme.softPink.opacity(0.1), radius: 24, y: 12)
        .shadow(color: Theme.lavenderMist.opacity(0.06), radius: 12, y: 6)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: selectedMode == nil)
    }

    private var featureHighlights: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                featureChip(icon: "leaf.fill", text: "Daily Growth", color: Theme.mint)
                featureChip(icon: "heart.fill", text: "Self-Care", color: Theme.softPink)
            }
            HStack(spacing: 10) {
                featureChip(icon: "sparkles", text: "Micro-Actions", color: Theme.gold)
                featureChip(icon: "chart.line.uptrend.xyaxis", text: "Track Progress", color: Theme.lavender)
            }
            HStack(spacing: 10) {
                featureChip(icon: "globe.americas.fill", text: "Travel Dreams", color: Theme.softSky)
                featureChip(icon: "camera.macro", text: "Bloom Garden", color: Theme.sage)
            }
        }
    }

    private func featureChip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
            Text(text)
                .font(Theme.font(13))
                .foregroundStyle(Theme.deep.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.12), lineWidth: 1)
        )
    }

    private var collapsedAuthButtons: some View {
        VStack(spacing: 14) {
            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    isSignUp = true
                    selectedMode = .signUp
                    showError = false
                    errorMessage = ""
                    email = ""
                    password = ""
                    confirmPassword = ""
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Sign Up")
                        .font(Theme.fontBold(17))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Theme.softPink, Theme.roseGold, Theme.softPink.opacity(0.9)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: Theme.softPink.opacity(0.35), radius: 14, y: 6)
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: selectedMode != nil)

            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    isSignUp = false
                    selectedMode = .logIn
                    showError = false
                    errorMessage = ""
                    email = ""
                    password = ""
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Log In")
                        .font(Theme.fontBold(17))
                }
                .foregroundStyle(Theme.deep)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.99, green: 0.97, blue: 0.95))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Theme.roseGold.opacity(0.2), lineWidth: 1.5)
                )
            }
        }
    }

    private var expandedFormContent: some View {
        VStack(spacing: 22) {
            HStack {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                        selectedMode = nil
                        focusedField = nil
                        showError = false
                        errorMessage = ""
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.deep.opacity(0.4))
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Theme.beige.opacity(0.8)))
                }

                Spacer()

                Text(isSignUp ? "Create Account" : "Welcome Back")
                    .font(Theme.fontBold(18))
                    .foregroundStyle(Theme.deep)

                Spacer()

                Color.clear.frame(width: 32, height: 32)
            }

            modePicker

            VStack(spacing: 16) {
                emailField
                passwordField

                if isSignUp {
                    confirmPasswordField
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }

            if showError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 14))
                    Text(errorMessage)
                        .font(Theme.font(13))
                }
                .foregroundStyle(Theme.rose)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.rose.opacity(0.08))
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            actionButton

            if !isSignUp {
                Button {
                    forgotEmail = email
                    forgotStep = 0
                    forgotError = ""
                    showForgotError = false
                    newPassword = ""
                    confirmNewPassword = ""
                    showForgotPassword = true
                } label: {
                    Text("Forgot password?")
                        .font(Theme.font(14))
                        .foregroundStyle(Theme.roseGold)
                }
            }
        }
    }

    private var modePicker: some View {
        HStack(spacing: 0) {
            modeTab(title: "Sign Up", isActive: isSignUp) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    isSignUp = true
                    showError = false
                    errorMessage = ""
                }
            }
            modeTab(title: "Log In", isActive: !isSignUp) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    isSignUp = false
                    showError = false
                    errorMessage = ""
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [Theme.beige.opacity(0.8), Color(red: 0.97, green: 0.94, blue: 0.90)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
    }

    private func modeTab(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Theme.fontBold(15))
                .foregroundStyle(isActive ? Theme.deep : Theme.deep.opacity(0.35))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    Group {
                        if isActive {
                            RoundedRectangle(cornerRadius: 11)
                                .fill(Color.white)
                                .shadow(color: Theme.softPink.opacity(0.12), radius: 6, y: 3)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isActive)
    }

    private var emailField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Email")
                .font(Theme.font(13))
                .foregroundStyle(Theme.deep.opacity(0.5))

            HStack(spacing: 12) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(focusedField == .email ? Theme.softPink : Theme.roseGold.opacity(0.4))
                    .frame(width: 24)

                TextField("your@email.com", text: $email)
                    .font(Theme.font(16))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .focused($focusedField, equals: .email)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        focusedField == .email
                            ? Color(red: 1.0, green: 0.97, blue: 0.95)
                            : Color(red: 0.99, green: 0.97, blue: 0.95).opacity(0.7)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        focusedField == .email ? Theme.softPink.opacity(0.45) : Theme.roseGold.opacity(0.1),
                        lineWidth: focusedField == .email ? 1.5 : 1
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: focusedField)
        }
    }

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Password")
                .font(Theme.font(13))
                .foregroundStyle(Theme.deep.opacity(0.5))

            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(focusedField == .password ? Theme.softPink : Theme.roseGold.opacity(0.4))
                    .frame(width: 24)

                Group {
                    if showPassword {
                        TextField("Min 6 characters", text: $password)
                    } else {
                        SecureField("Min 6 characters", text: $password)
                    }
                }
                .font(Theme.font(16))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textContentType(isSignUp ? .newPassword : .password)
                .focused($focusedField, equals: .password)

                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.deep.opacity(0.25))
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        focusedField == .password
                            ? Color(red: 1.0, green: 0.97, blue: 0.95)
                            : Color(red: 0.99, green: 0.97, blue: 0.95).opacity(0.7)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        focusedField == .password ? Theme.softPink.opacity(0.45) : Theme.roseGold.opacity(0.1),
                        lineWidth: focusedField == .password ? 1.5 : 1
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: focusedField)

            if isSignUp && !password.isEmpty && password.count < 6 {
                Text("Password must be at least 6 characters")
                    .font(Theme.font(12))
                    .foregroundStyle(Theme.rose.opacity(0.8))
                    .padding(.leading, 4)
            }
        }
    }

    private var confirmPasswordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Confirm Password")
                .font(Theme.font(13))
                .foregroundStyle(Theme.deep.opacity(0.5))

            HStack(spacing: 12) {
                Image(systemName: "lock.rotation")
                    .font(.system(size: 15))
                    .foregroundStyle(focusedField == .confirmPassword ? Theme.softPink : Theme.roseGold.opacity(0.4))
                    .frame(width: 24)

                Group {
                    if showConfirmPassword {
                        TextField("Re-enter password", text: $confirmPassword)
                    } else {
                        SecureField("Re-enter password", text: $confirmPassword)
                    }
                }
                .font(Theme.font(16))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textContentType(.newPassword)
                .focused($focusedField, equals: .confirmPassword)

                Button {
                    showConfirmPassword.toggle()
                } label: {
                    Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.deep.opacity(0.25))
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        focusedField == .confirmPassword
                            ? Color(red: 1.0, green: 0.97, blue: 0.95)
                            : Color(red: 0.99, green: 0.97, blue: 0.95).opacity(0.7)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        focusedField == .confirmPassword ? Theme.softPink.opacity(0.45) : Theme.roseGold.opacity(0.1),
                        lineWidth: focusedField == .confirmPassword ? 1.5 : 1
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: focusedField)

            if !confirmPassword.isEmpty && confirmPassword != password {
                Text("Passwords do not match")
                    .font(Theme.font(12))
                    .foregroundStyle(Theme.rose.opacity(0.8))
                    .padding(.leading, 4)
            }
        }
    }

    private var actionButton: some View {
        Button {
            performAuth()
        } label: {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.9)
                } else {
                    Text(isSignUp ? "Create Account" : "Welcome Back")
                        .font(Theme.fontBold(17))
                    Image(systemName: isSignUp ? "sparkles" : "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            isFormValid
                                ? LinearGradient(
                                    colors: [Theme.softPink, Theme.roseGold, Theme.softPink.opacity(0.9)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(
                                    colors: [Theme.deep.opacity(0.12), Theme.deep.opacity(0.08)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                        )

                    if isFormValid {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.15))
                            .mask(
                                LinearGradient(
                                    colors: [.clear, .white, .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(width: 120)
                                .offset(x: shimmerOffset)
                            )
                    }
                }
            )
            .shadow(color: isFormValid ? Theme.softPink.opacity(0.4) : .clear, radius: 18, y: 8)
        }
        .disabled(!isFormValid || isLoading)
        .animation(.easeInOut(duration: 0.25), value: isFormValid)
        .sensoryFeedback(.impact(weight: .medium), trigger: isLoading)
    }

    private var successOverlay: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Theme.beige,
                    Color(red: 0.97, green: 0.94, blue: 0.91)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Theme.mint.opacity(0.15), Theme.mint.opacity(0.0)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 140, height: 140)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.mint, Theme.sage],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Theme.mint.opacity(0.3), radius: 12, y: 4)
                }
                .scaleEffect(successScale)

                VStack(spacing: 6) {
                    Text(isSignUp ? "Account Created" : "Welcome Back")
                        .font(Theme.fontBold(26))
                        .foregroundStyle(Theme.deep)

                    Text("Let's make today beautiful")
                        .font(Theme.font(15))
                        .foregroundStyle(Theme.deep.opacity(0.4))
                }
            }
        }
        .transition(.opacity)
    }

    private var forgotPasswordSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if showResetSuccess {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 56, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Theme.mint, Theme.sage],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        Text("Password Reset!")
                            .font(Theme.fontBold(22))
                            .foregroundStyle(Theme.deep)

                        Text("Your password has been updated. You can now log in with your new password.")
                            .font(Theme.font(15))
                            .foregroundStyle(Theme.deep.opacity(0.5))
                            .multilineTextAlignment(.center)

                        Button {
                            showForgotPassword = false
                            showResetSuccess = false
                        } label: {
                            Text("Back to Login")
                                .font(Theme.fontBold(16))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(
                                            LinearGradient(
                                                colors: [Theme.softPink, Theme.roseGold],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                        }
                    }
                    .padding(.horizontal, 24)
                } else if forgotStep == 0 {
                    VStack(spacing: 20) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(Theme.roseGold)
                            .padding(.bottom, 8)

                        Text("Reset Password")
                            .font(Theme.fontBold(22))
                            .foregroundStyle(Theme.deep)

                        Text("Enter the email address associated with your account.")
                            .font(Theme.font(15))
                            .foregroundStyle(Theme.deep.opacity(0.5))
                            .multilineTextAlignment(.center)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(Theme.font(13))
                                .foregroundStyle(Theme.deep.opacity(0.5))

                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 15))
                                    .foregroundStyle(Theme.roseGold.opacity(0.4))
                                    .frame(width: 24)

                                TextField("your@email.com", text: $forgotEmail)
                                    .font(Theme.font(16))
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .keyboardType(.emailAddress)
                                    .focused($focusedField, equals: .forgotEmail)
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(red: 0.99, green: 0.97, blue: 0.95).opacity(0.7))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Theme.roseGold.opacity(0.1), lineWidth: 1)
                            )
                        }

                        if showForgotError {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 14))
                                Text(forgotError)
                                    .font(Theme.font(13))
                            }
                            .foregroundStyle(Theme.rose)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Theme.rose.opacity(0.08))
                            )
                        }

                        Button {
                            verifyForgotEmail()
                        } label: {
                            Text("Continue")
                                .font(Theme.fontBold(16))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(
                                            !forgotEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                                ? LinearGradient(colors: [Theme.softPink, Theme.roseGold], startPoint: .leading, endPoint: .trailing)
                                                : LinearGradient(colors: [Theme.deep.opacity(0.12), Theme.deep.opacity(0.08)], startPoint: .leading, endPoint: .trailing)
                                        )
                                )
                        }
                        .disabled(forgotEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.horizontal, 24)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(Theme.mint)
                            .padding(.bottom, 8)

                        Text("Set New Password")
                            .font(Theme.fontBold(22))
                            .foregroundStyle(Theme.deep)

                        Text("Enter a new password for \(forgotEmail)")
                            .font(Theme.font(15))
                            .foregroundStyle(Theme.deep.opacity(0.5))
                            .multilineTextAlignment(.center)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Password")
                                .font(Theme.font(13))
                                .foregroundStyle(Theme.deep.opacity(0.5))

                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 15))
                                    .foregroundStyle(Theme.roseGold.opacity(0.4))
                                    .frame(width: 24)

                                SecureField("Min 6 characters", text: $newPassword)
                                    .font(Theme.font(16))
                                    .textInputAutocapitalization(.never)
                                    .focused($focusedField, equals: .newPassword)
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(red: 0.99, green: 0.97, blue: 0.95).opacity(0.7))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Theme.roseGold.opacity(0.1), lineWidth: 1)
                            )
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm New Password")
                                .font(Theme.font(13))
                                .foregroundStyle(Theme.deep.opacity(0.5))

                            HStack(spacing: 12) {
                                Image(systemName: "lock.rotation")
                                    .font(.system(size: 15))
                                    .foregroundStyle(Theme.roseGold.opacity(0.4))
                                    .frame(width: 24)

                                SecureField("Re-enter password", text: $confirmNewPassword)
                                    .font(Theme.font(16))
                                    .textInputAutocapitalization(.never)
                                    .focused($focusedField, equals: .confirmNewPassword)
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(red: 0.99, green: 0.97, blue: 0.95).opacity(0.7))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Theme.roseGold.opacity(0.1), lineWidth: 1)
                            )

                            if !confirmNewPassword.isEmpty && confirmNewPassword != newPassword {
                                Text("Passwords do not match")
                                    .font(Theme.font(12))
                                    .foregroundStyle(Theme.rose.opacity(0.8))
                                    .padding(.leading, 4)
                            }
                        }

                        if showForgotError {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 14))
                                Text(forgotError)
                                    .font(Theme.font(13))
                            }
                            .foregroundStyle(Theme.rose)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Theme.rose.opacity(0.08))
                            )
                        }

                        Button {
                            performPasswordReset()
                        } label: {
                            Text("Reset Password")
                                .font(Theme.fontBold(16))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(
                                            (newPassword.count >= 6 && newPassword == confirmNewPassword)
                                                ? LinearGradient(colors: [Theme.mint, Theme.sage], startPoint: .leading, endPoint: .trailing)
                                                : LinearGradient(colors: [Theme.deep.opacity(0.12), Theme.deep.opacity(0.08)], startPoint: .leading, endPoint: .trailing)
                                        )
                                )
                        }
                        .disabled(newPassword.count < 6 || newPassword != confirmNewPassword)
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()
            }
            .padding(.top, 32)
            .background(Theme.beige.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showForgotPassword = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(Theme.deep.opacity(0.2))
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func verifyForgotEmail() {
        let trimmed = forgotEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        do {
            let _ = try authService.resetPassword(email: trimmed)
            withAnimation(.spring(response: 0.4)) {
                forgotStep = 1
                showForgotError = false
            }
        } catch {
            withAnimation(.spring(response: 0.3)) {
                forgotError = error.localizedDescription
                showForgotError = true
            }
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }

    private func performPasswordReset() {
        let trimmed = forgotEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        KeychainService.save(newPassword, forKey: "auth_email_\(trimmed)")
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        withAnimation(.spring(response: 0.5)) {
            showResetSuccess = true
        }
    }

    private func performAuth() {
        focusedField = nil

        withAnimation(.spring(response: 0.3)) {
            showError = false
        }

        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            if isSignUp {
                handleSignUp()
            } else {
                handleLogin()
            }
        }
    }

    private func handleSignUp() {
        do {
            try authService.signUp(email: email, password: password)
            isLoading = false
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showSuccess = true
                successScale = 1.0
            }
        } catch {
            isLoading = false
            withAnimation(.spring(response: 0.3)) {
                errorMessage = error.localizedDescription
                showError = true
            }
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }

    private func handleLogin() {
        do {
            try authService.login(email: email, password: password)
            isLoading = false
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showSuccess = true
                successScale = 1.0
            }
        } catch {
            isLoading = false
            withAnimation(.spring(response: 0.3)) {
                errorMessage = error.localizedDescription
                showError = true
            }
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
}
