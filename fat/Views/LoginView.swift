//
//  LoginView.swift
//  fat
//
//  Created by Hello World on 2026/1/12.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var userManager: UserManager
    @Environment(\.colorScheme) var colorScheme
    @State private var phone: String = ""
    @State private var code: String = ""
    @State private var password: String = ""
    @State private var isCodeSent = false
    @State private var loginMode: LoginMode = .sms  // sms=验证码, password=密码
    @State private var countdown = 0
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var activeLegalDocument: LegalDocument?
    @FocusState private var focusedField: Field?

    enum LoginMode { case sms, password }

    enum Field {
        case phone, code, password
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 根据系统模式调整的背景
                Group {
                    if colorScheme == .dark {
                        // 深色模式：使用深色渐变
                        LinearGradient(
                            colors: [
                                Color(.systemBackground),
                                Color(.secondarySystemBackground)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        // 浅色模式：使用浅色渐变
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.95, blue: 0.9),
                                Color(red: 0.95, green: 0.98, blue: 1.0),
                                Color(red: 0.98, green: 0.95, blue: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // 极简标题区域
                    VStack(spacing: 20) {
                        // 主标题 - Apple风格大标题
                        Text("今天你胖了吗？")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(Color(.label))
                            .multilineTextAlignment(.center)
                            .tracking(-0.5)  // 字间距微调
                        
                        // 副标题 - Apple风格副标题
                        Text("记录每一天的变化")
                            .font(.system(size: 17, weight: .regular, design: .default))
                            .foregroundColor(Color(.secondaryLabel))
                            .tracking(0.2)
                    }
                    .padding(.bottom, 60)
                    
                    // 极简输入区域
                    VStack(spacing: 16) {
                        // 登录模式切换
                        HStack(spacing: 0) {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    loginMode = .sms
                                    isCodeSent = false
                                    code = ""
                                    password = ""
                                    focusedField = .phone
                                }
                            } label: {
                                Text("验证码登录")
                                    .font(.system(size: 15, weight: loginMode == .sms ? .semibold : .regular))
                                    .foregroundColor(loginMode == .sms ? .primary : .secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(loginMode == .sms ? Color(.systemGray5).opacity(0.5) : Color.clear)
                            }
                            .buttonStyle(.plain)

                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    loginMode = .password
                                    isCodeSent = false
                                    code = ""
                                    password = ""
                                    focusedField = .phone
                                }
                            } label: {
                                Text("密码登录")
                                    .font(.system(size: 15, weight: loginMode == .password ? .semibold : .regular))
                                    .foregroundColor(loginMode == .password ? .primary : .secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(loginMode == .password ? Color(.systemGray5).opacity(0.5) : Color.clear)
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: 200)
                        .background(
                            Capsule()
                                .fill(Color(.systemGray6).opacity(0.5))
                        )
                        .padding(.bottom, 4)

                        // 手机号输入
                        HStack(spacing: 12) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(.blue)
                                .frame(width: 24)

                            TextField("手机号", text: $phone)
                                .font(.system(size: 17, weight: .regular, design: .default))
                                .foregroundColor(Color(.label))
                                .keyboardType(.phonePad)
                                .focused($focusedField, equals: .phone)
                                .accentColor(.blue)
                                .onChange(of: phone) {
                                    phone = String(phone.prefix(11)).filter { $0.isNumber }
                                }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.secondarySystemBackground))
                                .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                        )

                        // 验证码模式
                        if loginMode == .sms {
                            if isCodeSent {
                                HStack(spacing: 12) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(.green)
                                        .frame(width: 24)

                                    TextField("验证码", text: $code)
                                        .font(.system(size: 17, weight: .regular, design: .default))
                                        .foregroundColor(Color(.label))
                                        .keyboardType(.numberPad)
                                        .focused($focusedField, equals: .code)
                                        .accentColor(.blue)
                                        .onChange(of: code) {
                                            code = String(code.prefix(6)).filter { $0.isNumber }
                                        }

                                    // 重新发送按钮
                                    Button(action: {
                                        sendCode()
                                    }) {
                                        Text(countdown > 0 ? "\(countdown)s" : "重发")
                                            .font(.system(size: 15, weight: .medium, design: .default))
                                            .foregroundColor(countdown > 0 ? .gray : .blue)
                                            .frame(width: 50)
                                    }
                                    .disabled(countdown > 0)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.secondarySystemBackground))
                                        .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                                )
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }

                        // 密码模式
                        if loginMode == .password {
                            VStack(spacing: 12) {
                                HStack(spacing: 12) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(.green)
                                        .frame(width: 24)

                                    SecureField("密码", text: $password)
                                        .font(.system(size: 17, weight: .regular, design: .default))
                                        .foregroundColor(Color(.label))
                                        .focused($focusedField, equals: .password)
                                        .accentColor(.blue)
                                        .onChange(of: password) {
                                            password = String(password.prefix(20))
                                        }
                                }

                                // 密码强度规则（输入时实时显示）
                                if !password.isEmpty {
                                    let strength = PasswordStrength.evaluate(password)
                                    VStack(spacing: 5) {
                                        ForEach(strength.rules) { rule in
                                            HStack(spacing: 6) {
                                                Image(systemName: rule.isMet ? "checkmark.circle.fill" : "circle")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(rule.isMet ? .green : Color(.systemGray3))
                                                Text(rule.label)
                                                    .font(.system(size: 11))
                                                    .foregroundColor(rule.isMet ? .secondary : Color(.tertiaryLabel))
                                                Spacer()
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                    .transition(.opacity)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.secondarySystemBackground))
                                    .shadow(color: colorScheme == .dark ? Color.clear : Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // 错误提示
                        if let errorMessage = errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.red)
                                Text(errorMessage)
                                    .font(.system(size: 15, weight: .medium, design: .default))
                                    .foregroundColor(.red)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                            .padding(.top, 8)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // 主按钮 - 青春活力的渐变色
                        Button(action: {
                            if loginMode == .password {
                                loginWithPassword()
                            } else if isCodeSent {
                                login()
                            } else {
                                sendCode()
                            }
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(buttonTitle)
                                        .font(.system(size: 17, weight: .semibold, design: .default))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: canProceed ? [
                                        Color(red: 1.0, green: 0.4, blue: 0.4),
                                        Color(red: 1.0, green: 0.6, blue: 0.3)
                                    ] : [
                                        Color.gray.opacity(0.3),
                                        Color.gray.opacity(0.2)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(
                                color: canProceed ? Color(red: 1.0, green: 0.4, blue: 0.4).opacity(0.4) : Color.clear,
                                radius: 15,
                                x: 0,
                                y: 8
                            )
                        }
                        .disabled(!canProceed || isLoading)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Text("登录即表示你已阅读并同意")
                            .font(.system(size: 13, weight: .regular, design: .default))
                            .foregroundColor(Color(.tertiaryLabel))
                        
                        HStack(spacing: 4) {
                            Button("《用户协议》") {
                                activeLegalDocument = .terms
                            }
                            Button("《隐私政策》") {
                                activeLegalDocument = .privacy
                            }
                        }
                        .font(.system(size: 13, weight: .medium, design: .default))
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCodeSent)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: errorMessage)
        .sheet(item: $activeLegalDocument) { document in
            LegalDocumentView(document: document)
        }
    }
    
    // MARK: - 是否可以继续
    private var canProceed: Bool {
        if loginMode == .password {
            return phone.count == 11 && !password.isEmpty
        }
        if isCodeSent {
            return phone.count == 11 && code.count == 6
        } else {
            return phone.count == 11
        }
    }

    // MARK: - 按钮文案
    private var buttonTitle: String {
        if loginMode == .password {
            return "登录"
        }
        if isCodeSent {
            return "登录"
        }
        return "获取验证码"
    }
    
    // MARK: - 发送验证码
    private func sendCode() {
        // 验证手机号格式
        guard phone.count == 11 else {
            errorMessage = "请输入11位手机号"
            return
        }
        
        // 检查手机号格式（简单的中国手机号格式验证：1开头，第二位3-9）
        guard phone.hasPrefix("1"), 
              let secondChar = phone.dropFirst().first,
              ("3"..."9").contains(secondChar) else {
            errorMessage = "请输入正确的手机号"
            return
        }
        
        // 检查是否在倒计时中
        guard countdown == 0 else {
            errorMessage = "请稍候再试（\(countdown)秒后可重新发送）"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                _ = try await NetworkService.shared.sendCode(phone: phone)
                await MainActor.run {
                    isCodeSent = true
                    isLoading = false
                    countdown = 60
                    startCountdown()
                    focusedField = .code
                    
                    // 如需调试提示，可在 DEBUG 环境下补充额外文案
                    #if DEBUG
                    // 开发环境占位
                    #endif
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    // 友好的错误提示
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .apiError(let message):
                            // 直接显示后端返回的错误信息（如"发送过于频繁，请45秒后再试"）
                            errorMessage = message
                            // 如果错误信息中包含秒数，尝试提取并设置倒计时
                            // 例如："发送过于频繁，请45秒后再试"
                            let pattern = #"请(\d+)秒后再试"#
                            if let regex = try? NSRegularExpression(pattern: pattern),
                               let match = regex.firstMatch(in: message, range: NSRange(message.startIndex..., in: message)),
                               match.numberOfRanges > 1,
                               let range = Range(match.range(at: 1), in: message),
                               let seconds = Int(String(message[range])),
                               seconds > 0 && seconds < 120 {
                                countdown = seconds
                                startCountdown()
                            }
                        case .httpError(let statusCode):
                            if statusCode == 429 {
                                errorMessage = "请求过于频繁，请稍后再试"
                            } else if statusCode >= 500 {
                                errorMessage = "服务器错误，请稍后重试"
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
    
    // MARK: - 密码登录
    private func loginWithPassword() {
        guard phone.count == 11 else {
            errorMessage = "请填写完整信息"
            return
        }
        guard !password.isEmpty else {
            errorMessage = "请输入密码"
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                let loginResponse = try await NetworkService.shared.loginWithPassword(phone: phone, password: password)

                await MainActor.run {
                    userManager.saveUserInfo(
                        userId: loginResponse.userId,
                        phone: phone,
                        accessToken: loginResponse.accessToken,
                        refreshToken: loginResponse.refreshToken,
                        expireTime: loginResponse.expireTime
                    )
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .apiError(let message):
                            errorMessage = message.isEmpty ? "登录失败，请稍后重试" : message
                        case .httpError(let code):
                            if code == 401 {
                                errorMessage = "密码错误或已过期"
                            } else if code >= 500 {
                                errorMessage = "服务器错误，请稍后重试"
                            } else {
                                errorMessage = "网络错误，请稍后重试"
                            }
                        default:
                            errorMessage = "登录失败，请稍后重试"
                        }
                    } else {
                        errorMessage = "登录失败：\(error.localizedDescription)"
                    }
                }
            }
        }
    }

    // MARK: - 登录
    private func login() {
        guard phone.count == 11 && code.count == 6 else {
            errorMessage = "请填写完整信息"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                print("🔵 开始登录请求...")
                let loginResponse = try await NetworkService.shared.login(phone: phone, code: code)
                print("✅ 登录请求成功，收到响应: userId=\(loginResponse.userId), token=\(loginResponse.accessToken.prefix(20))...")
                
                await MainActor.run {
                    print("🔄 开始保存用户信息...")
                    // 保存用户信息，这会自动触发 RootView 的视图更新
                    userManager.saveUserInfo(
                        userId: loginResponse.userId,
                        phone: phone,
                        accessToken: loginResponse.accessToken,
                        refreshToken: loginResponse.refreshToken,
                        expireTime: loginResponse.expireTime
                    )
                    print("✅ 用户信息已保存，当前 isLoggedIn = \(userManager.isLoggedIn)")
                    // 注意：不要在这里清空输入框或重置状态
                    // 因为视图会立即切换到 ContentViewButtons
                    // 如果清空状态，可能会导致视图闪烁
                    isLoading = false
                }
            } catch {
                print("❌ 登录失败: \(error)")
                await MainActor.run {
                    isLoading = false
                    // 友好的错误提示
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .apiError(let message):
                            // 直接显示后端返回的错误信息
                            errorMessage = message.isEmpty ? "登录失败，请稍后重试" : message
                        case .httpError(let code):
                            if code == 401 {
                                errorMessage = "验证码错误或已过期"
                            } else if code >= 500 {
                                errorMessage = "服务器错误，请稍后重试"
                            } else {
                                errorMessage = "网络错误，请稍后重试"
                            }
                        default:
                            errorMessage = "登录失败，请稍后重试"
                        }
                    } else {
                        errorMessage = "登录失败：\(error.localizedDescription)"
                    }
                    // 登录失败时，不清空输入框，保持验证码输入状态
                    // 但重置 isCodeSent 会导致回到手机号输入，所以不重置
                }
            }
        }
    }
    
    // MARK: - 倒计时
    private func startCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdown > 0 {
                countdown -= 1
            } else {
                timer.invalidate()
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(UserManager.shared)
}
