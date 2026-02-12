import Foundation
import Observation

@Observable
@MainActor
final class AuthService {
    static let shared = AuthService()

    var isAuthenticated: Bool
    var currentUserEmail: String

    private init() {
        let loggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        let email = UserDefaults.standard.string(forKey: "authUserEmail") ?? ""
        self.isAuthenticated = loggedIn && !email.isEmpty
        self.currentUserEmail = email
    }

    enum AuthError: LocalizedError {
        case accountExists
        case noAccount
        case wrongPassword
        case weakPassword
        case emptyEmail
        case invalidEmail

        var errorDescription: String? {
            switch self {
            case .accountExists: return "An account with this email already exists"
            case .noAccount: return "No account found with this email"
            case .wrongPassword: return "Incorrect password"
            case .weakPassword: return "Password must be at least 6 characters"
            case .emptyEmail: return "Please enter your email"
            case .invalidEmail: return "Please enter a valid email address"
            }
        }
    }

    func signUp(email: String, password: String) throws {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { throw AuthError.emptyEmail }
        guard trimmed.contains("@") && trimmed.contains(".") else { throw AuthError.invalidEmail }
        guard password.count >= 6 else { throw AuthError.weakPassword }

        if KeychainService.load(forKey: "auth_email_\(trimmed)") != nil {
            throw AuthError.accountExists
        }

        KeychainService.save(password, forKey: "auth_email_\(trimmed)")
        KeychainService.save(trimmed, forKey: "auth_current_user")

        UserDefaults.standard.set(trimmed, forKey: "authUserEmail")
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "user_\(trimmed)_joinDate")

        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        setSession(email: trimmed)
    }

    func login(email: String, password: String) throws {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { throw AuthError.emptyEmail }

        guard let storedPassword = KeychainService.load(forKey: "auth_email_\(trimmed)") else {
            throw AuthError.noAccount
        }

        guard storedPassword == password else {
            throw AuthError.wrongPassword
        }

        KeychainService.save(trimmed, forKey: "auth_current_user")
        loadUserProfile(email: trimmed)
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        setSession(email: trimmed)
    }

    func logout() {
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.removeObject(forKey: "authUserEmail")
        KeychainService.delete(forKey: "auth_current_user")
        currentUserEmail = ""
        isAuthenticated = false
    }

    func resetPassword(email: String) throws -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { throw AuthError.emptyEmail }
        guard KeychainService.load(forKey: "auth_email_\(trimmed)") != nil else {
            throw AuthError.noAccount
        }
        return true
    }

    func updatePassword(newPassword: String) {
        guard !currentUserEmail.isEmpty else { return }
        KeychainService.save(newPassword, forKey: "auth_email_\(currentUserEmail)")
        saveUserData("userPassword", value: newPassword)
    }

    func deleteAccount() {
        guard !currentUserEmail.isEmpty else { return }
        let email = currentUserEmail
        KeychainService.delete(forKey: "auth_email_\(email)")
        let profileKeys = ["userName", "userUsername", "userFocusArea", "profileImageData", "userPassword"]
        for key in profileKeys {
            UserDefaults.standard.removeObject(forKey: "user_\(email)_\(key)")
        }
        UserDefaults.standard.removeObject(forKey: "user_\(email)_joinDate")
        logout()
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
    }

    func saveUserData(_ key: String, value: String) {
        guard !currentUserEmail.isEmpty else { return }
        UserDefaults.standard.set(value, forKey: "user_\(currentUserEmail)_\(key)")
        UserDefaults.standard.set(value, forKey: key)
    }

    func saveUserData(_ key: String, data: Data?) {
        guard !currentUserEmail.isEmpty else { return }
        UserDefaults.standard.set(data, forKey: "user_\(currentUserEmail)_\(key)")
        UserDefaults.standard.set(data, forKey: key)
    }

    func saveUserBool(_ key: String, value: Bool) {
        guard !currentUserEmail.isEmpty else { return }
        UserDefaults.standard.set(value, forKey: "user_\(currentUserEmail)_\(key)")
        UserDefaults.standard.set(value, forKey: key)
    }

    func loadUserData(_ key: String) -> String? {
        guard !currentUserEmail.isEmpty else { return nil }
        return UserDefaults.standard.string(forKey: "user_\(currentUserEmail)_\(key)")
    }

    func loadUserImageData(_ key: String) -> Data? {
        guard !currentUserEmail.isEmpty else { return nil }
        return UserDefaults.standard.data(forKey: "user_\(currentUserEmail)_\(key)")
    }

    var memberSinceDate: Date {
        guard !currentUserEmail.isEmpty else { return .now }
        let timestamp = UserDefaults.standard.double(forKey: "user_\(currentUserEmail)_joinDate")
        return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : .now
    }

    private func setSession(email: String) {
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        UserDefaults.standard.set(email, forKey: "authUserEmail")
        currentUserEmail = email
        isAuthenticated = true
    }

    private func loadUserProfile(email: String) {
        let keys = ["userName", "userUsername", "userFocusArea"]
        for key in keys {
            if let val = UserDefaults.standard.string(forKey: "user_\(email)_\(key)") {
                UserDefaults.standard.set(val, forKey: key)
            }
        }
        if let imgData = UserDefaults.standard.data(forKey: "user_\(email)_profileImageData") {
            UserDefaults.standard.set(imgData, forKey: "profileImageData")
        }
    }
}
