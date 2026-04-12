//
//  AccountSettingsView.swift
//  fat
//
//  Created by Codex on 2026/4/12.
//

import SwiftUI

// MARK: - 密码强度规则
struct PasswordRule: Identifiable {
    let id = UUID()
    let label: String
    let isMet: Bool
}

struct PasswordStrength: Equatable {
    let lengthOK: Bool
    let hasLetter: Bool
    let hasDigit: Bool
    let score: Int

    static func evaluate(_ password: String) -> PasswordStrength {
        let lengthOK = password.count >= 6 && password.count <= 20
        let hasLetter = password.contains { $0.isLetter }
        let hasDigit = password.contains { $0.isNumber }
        let score = [lengthOK, hasLetter, hasDigit].filter { $0 }.count
        return PasswordStrength(lengthOK: lengthOK, hasLetter: hasLetter, hasDigit: hasDigit, score: score)
    }

    var rules: [PasswordRule] {
        [
            PasswordRule(label: "至少 6 位，最多 20 位", isMet: lengthOK),
            PasswordRule(label: "包含字母", isMet: hasLetter),
            PasswordRule(label: "包含数字", isMet: hasDigit),
        ]
    }

    var strengthLabel: String {
        if score == 0 { return "弱" }
        if score == 1 { return "中" }
        if score == 2 { return "强" }
        return "很强"
    }

    var strengthColor: Color {
        if score == 0 { return .red }
        if score == 1 { return .orange }
        if score == 2 { return .yellow }
        return .green
    }

    var isStrong: Bool { score == 3 }
}

// MARK: - 密码强度指示器组件
struct PasswordStrengthIndicator: View {
    let strength: PasswordStrength
    let confirmPasswordMatch: Bool  // nil = 未输入, true = 匹配, false = 不匹配
    let showConfirmMismatch: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 强度条
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i < strength.score ? strength.strengthColor : Color(.systemGray5))
                        .frame(height: 4)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: strength.score)

            HStack {
                Text("密码强度：\(strength.strengthLabel)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(strength.strengthColor)
                Spacer()
                if showConfirmMismatch {
                    Text("两次密码不一致")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                }
            }

            // 规则列表
            VStack(spacing: 6) {
                ForEach(strength.rules) { rule in
                    HStack(spacing: 8) {
                        Image(systemName: rule.isMet ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 14))
                            .foregroundColor(rule.isMet ? .green : Color(.systemGray3))
                        Text(rule.label)
                            .font(.system(size: 12))
                            .foregroundColor(rule.isMet ? .secondary : Color(.tertiaryLabel))
                        Spacer()
                    }
                    .animation(.easeInOut(duration: 0.2), value: rule.isMet)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.5))
        )
    }
}

// MARK: - 账号与安全设置
struct AccountSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    @State private var hasPassword: Bool?
    @State private var showingSetPassword = false
    @State private var showingChangePassword = false
    @State private var showingDeleteVerify = false
    @State private var showToast = false
    @State private var toastMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    Section("密码管理") {
                        if hasPassword == true {
                            Button("修改密码") {
                                showingChangePassword = true
                            }
                        } else if hasPassword == false {
                            Button("设置密码") {
                                showingSetPassword = true
                            }
                        } else {
                            ProgressView()
                        }
                    }

                    Section("危险操作") {
                        Button(role: .destructive) {
                            showingDeleteVerify = true
                        } label: {
                            Text("删除账号")
                        }
                    }
                }
                .navigationTitle("账号与安全")
                .navigationBarTitleDisplayMode(.inline)

                if showToast {
                    VStack {
                        Text(toastMessage)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.75))
                            .cornerRadius(12)
                            .padding(.top, 100)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        Spacer()
                    }
                    .animation(.easeInOut(duration: 0.3), value: showToast)
                }
            }
            .sheet(isPresented: $showingSetPassword) {
                SetPasswordView(onSuccess: {
                    hasPassword = true
                    showToastMessage("密码设置成功")
                })
            }
            .sheet(isPresented: $showingChangePassword) {
                ChangePasswordView(onSuccess: {
                    showToastMessage("密码修改成功")
                })
            }
            .sheet(isPresented: $showingDeleteVerify) {
                DeleteAccountView()
            }
            .task {
                if let profile = try? await NetworkService.shared.getUserProfile() {
                    hasPassword = profile.hasPassword
                }
            }
        }
    }

    private func showToastMessage(_ message: String) {
        toastMessage = message
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showToast = false
        }
    }
}

// MARK: - 设置密码
struct SetPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    var onSuccess: (() -> Void)?

    private var strength: PasswordStrength { PasswordStrength.evaluate(password) }
    private var confirmMismatch: Bool { !confirmPassword.isEmpty && confirmPassword != password }
    var canSubmit: Bool { strength.isStrong && !confirmMismatch }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("密码（6-20位字母或数字）", text: $password)
                    SecureField("确认密码", text: $confirmPassword)
                } header: {
                    Text("设置登录密码")
                } footer: {
                    Text("密码只能设置一次，设置后可用于密码登录")
                }

                // 强度指示器
                if !password.isEmpty {
                    Section {
                        PasswordStrengthIndicator(
                            strength: strength,
                            confirmPasswordMatch: !confirmMismatch,
                            showConfirmMismatch: confirmMismatch
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("设置密码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("确认") { setPassword() }
                        .disabled(!canSubmit || isLoading)
                }
            }
        }
    }

    private func setPassword() {
        guard canSubmit else { return }
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await NetworkService.shared.setPassword(password)
                await MainActor.run {
                    isLoading = false
                    dismiss()
                    onSuccess?()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .apiError(let message):
                            errorMessage = message
                        default:
                            errorMessage = "设置失败，请稍后重试"
                        }
                    } else {
                        errorMessage = "设置失败：\(error.localizedDescription)"
                    }
                }
            }
        }
    }
}

// MARK: - 修改密码
struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var oldPassword = ""
    @State private var newPassword = ""
    @State private var confirmNewPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    var onSuccess: (() -> Void)?

    private var strength: PasswordStrength { PasswordStrength.evaluate(newPassword) }
    private var confirmMismatch: Bool { !confirmNewPassword.isEmpty && confirmNewPassword != newPassword }
    var canSubmit: Bool { !oldPassword.isEmpty && strength.isStrong && !confirmMismatch }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("旧密码", text: $oldPassword)
                    SecureField("新密码（6-20位字母或数字）", text: $newPassword)
                    SecureField("确认新密码", text: $confirmNewPassword)
                } header: {
                    Text("修改登录密码")
                }

                // 强度指示器
                if !newPassword.isEmpty {
                    Section {
                        PasswordStrengthIndicator(
                            strength: strength,
                            confirmPasswordMatch: !confirmMismatch,
                            showConfirmMismatch: confirmMismatch
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("修改密码")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("确认") { changePassword() }
                        .disabled(!canSubmit || isLoading)
                }
            }
        }
    }

    private func changePassword() {
        guard canSubmit else { return }
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await NetworkService.shared.changePassword(oldPassword: oldPassword, newPassword: newPassword)
                await MainActor.run {
                    isLoading = false
                    dismiss()
                    onSuccess?()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .apiError(let message):
                            errorMessage = message
                        default:
                            errorMessage = "修改失败，请稍后重试"
                        }
                    } else {
                        errorMessage = "修改失败：\(error.localizedDescription)"
                    }
                }
            }
        }
    }
}

// MARK: - 删除账号
struct DeleteAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    @State private var verifyType: VerifyType = .sms
    @State private var code = ""
    @State private var countdown = 0
    @State private var isLoading = false
    @State private var isSendingCode = false
    @State private var errorMessage: String?
    @State private var showingConfirm = false

    enum VerifyType: String, CaseIterable {
        case sms = "短信验证码"
        case password = "密码"
    }

    var canSubmit: Bool {
        switch verifyType {
        case .sms: return code.count == 6
        case .password: return !code.isEmpty
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("验证方式", selection: $verifyType) {
                        ForEach(VerifyType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: verifyType) {
                        code = ""
                        errorMessage = nil
                    }

                    if verifyType == .sms {
                        HStack(spacing: 12) {
                            TextField("短信验证码", text: $code)
                                .keyboardType(.numberPad)

                            Button {
                                sendSmsCode()
                            } label: {
                                if isSendingCode {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                } else {
                                    Text(countdown > 0 ? "\(countdown)s" : "获取验证码")
                                        .font(.system(size: 14, weight: .medium))
                                }
                            }
                            .disabled(countdown > 0 || isSendingCode)
                            .foregroundColor(countdown > 0 ? .secondary : .blue)
                            .frame(width: 80)
                        }
                    } else {
                        SecureField("登录密码", text: $code)
                    }
                } header: {
                    Text("验证身份")
                } footer: {
                    Text("验证通过后，所有数据将被永久删除且无法恢复")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("删除账号")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("下一步") {
                        showingConfirm = true
                    }
                    .disabled(!canSubmit || isLoading)
                }
            }
            .alert("确认删除", isPresented: $showingConfirm) {
                Button("取消", role: .cancel) {}
                Button("确认删除", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("删除后所有数据将永久清除，无法恢复。确认删除？")
            }
        }
    }

    private func sendSmsCode() {
        guard countdown == 0 else { return }
        isSendingCode = true
        errorMessage = nil

        Task {
            do {
                _ = try await NetworkService.shared.sendCode(phone: userManager.phone ?? "")
                await MainActor.run {
                    isSendingCode = false
                    countdown = 60
                    startCountdown()
                }
            } catch {
                await MainActor.run {
                    isSendingCode = false
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .apiError(let message):
                            errorMessage = message
                            if let seconds = extractSeconds(from: message) {
                                countdown = seconds
                                startCountdown()
                            }
                        case .httpError(let statusCode):
                            if statusCode == 429 {
                                errorMessage = "请求过于频繁，请稍后再试"
                            } else {
                                errorMessage = "网络错误，请稍后重试"
                            }
                        default:
                            errorMessage = "发送失败，请稍后重试"
                        }
                    } else {
                        errorMessage = "发送失败：\(error.localizedDescription)"
                    }
                }
            }
        }
    }

    private func startCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdown > 0 {
                countdown -= 1
            } else {
                timer.invalidate()
            }
        }
    }

    private func extractSeconds(from message: String) -> Int? {
        let pattern = #"请(\d+)秒后再试"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: message, range: NSRange(message.startIndex..., in: message)),
           match.numberOfRanges > 1,
           let range = Range(match.range(at: 1), in: message),
           let seconds = Int(String(message[range])),
           seconds > 0 && seconds < 120 {
            return seconds
        }
        return nil
    }

    private func deleteAccount() {
        guard canSubmit else { return }
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let typeStr = verifyType == .sms ? "sms" : "password"
                try await NetworkService.shared.deleteAccount(verifyType: typeStr, code: code)
                await MainActor.run {
                    isLoading = false
                    userManager.logout()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .apiError(let message):
                            errorMessage = message
                        default:
                            errorMessage = "删除失败，请稍后重试"
                        }
                    } else {
                        errorMessage = "删除失败：\(error.localizedDescription)"
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        AccountSettingsView()
    }
    .environmentObject(UserManager.shared)
}
