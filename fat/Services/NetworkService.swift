//
//  NetworkService.swift
//  fat
//
//  Created by Hello World on 2026/1/12.
//

import Foundation

class NetworkService {
    static let shared = NetworkService()

    // 后端API基础URL
    #if DEBUG
    private let baseURL = "http://localhost:8080/app/weight"
    #else
    private let baseURL = "https://sanzhong.online/app/weight"
    #endif

    @MainActor private var refreshTask: Task<Void, Error>?

    private init() {}
    
    // MARK: - 发送验证码
    func sendCode(phone: String) async throws -> String {
        let url = URL(string: "\(baseURL)/send-code")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = SendCodeRequest(phone: phone)
        request.httpBody = try JSONEncoder().encode(body)
        
        print("📤 发送验证码请求: \(url.absoluteString), phone: \(phone)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ 无效的HTTP响应")
            throw NetworkError.invalidResponse
        }
        
        print("📥 HTTP状态码: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 响应数据: \(responseString)")
        }
        
        // 尝试解析响应（无论状态码是什么，都尝试解析错误信息）
        do {
            let result = try JSONDecoder().decode(ApiResponse<String>.self, from: data)
            print("📥 解析结果: code=\(result.code ?? -1), success=\(result.success ?? false), msg=\(result.msg ?? "nil")")
            
            if result.isSuccess, let message = result.data {
                print("✅ 验证码发送成功")
                return message
            } else {
                // 优先使用后端返回的错误信息
                let errorMsg = Self.normalizedBackendMessage(result.msg ?? "发送验证码失败")
                print("❌ 验证码发送失败: \(errorMsg)")
                throw NetworkError.apiError(errorMsg)
            }
        } catch let decodeError as DecodingError {
            // 如果解析失败，但状态码不是200，使用HTTP错误
            if httpResponse.statusCode != 200 {
                print("❌ JSON解析失败，使用HTTP状态码: \(httpResponse.statusCode)")
                throw NetworkError.httpError(httpResponse.statusCode)
            }
            throw decodeError
        }
    }
    
    // MARK: - 登录（验证码）
    func login(phone: String, code: String) async throws -> LoginResponse {
        let url = URL(string: "\(baseURL)/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = LoginRequest(phone: phone, code: code)
        request.httpBody = try JSONEncoder().encode(body)

        print("📤 发送登录请求: \(url.absoluteString)")
        if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            print("📤 请求体: \(bodyString)")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ 无效的HTTP响应")
            throw NetworkError.invalidResponse
        }

        print("📥 HTTP状态码: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("📥 响应数据: \(responseString)")
        }

        guard httpResponse.statusCode == 200 else {
            print("❌ HTTP错误: \(httpResponse.statusCode)")
            throw NetworkError.httpError(httpResponse.statusCode)
        }

        let result = try JSONDecoder().decode(ApiResponse<LoginResponse>.self, from: data)

        print("📥 解析结果: code=\(result.code ?? -1), success=\(result.success ?? false), msg=\(result.msg ?? "nil")")

        if result.isSuccess, let loginResponse = result.data {
            print("✅ 登录响应解析成功: userId=\(loginResponse.userId)")
            return loginResponse
        } else {
            let errorMsg = Self.normalizedBackendMessage(result.msg ?? "登录失败")
            print("❌ 登录失败: \(errorMsg)")
            throw NetworkError.apiError(errorMsg)
        }
    }

    // MARK: - 密码登录
    func loginWithPassword(phone: String, password: String) async throws -> LoginResponse {
        let url = URL(string: "\(baseURL)/login/password")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = PasswordLoginRequest(phone: phone, password: password)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }

        let result = try JSONDecoder().decode(ApiResponse<LoginResponse>.self, from: data)

        if result.isSuccess, let loginResponse = result.data {
            return loginResponse
        } else {
            throw NetworkError.apiError(Self.normalizedBackendMessage(result.msg ?? "手机号或密码错误"))
        }
    }

    // MARK: - 设置密码（首次）
    func setPassword(_ password: String) async throws {
        try await ensureValidToken()

        let url = URL(string: "\(baseURL)/set-password")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = UserManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body = SetPasswordRequest(password: password)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            try await refreshTokenIfNeeded()
            return try await setPassword(password)
        }

        guard httpResponse.statusCode == 200 else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }

        let result = try JSONDecoder().decode(ApiResponse<String>.self, from: data)

        if !result.isSuccess {
            throw NetworkError.apiError(Self.normalizedBackendMessage(result.msg ?? "设置密码失败"))
        }
    }

    // MARK: - 修改密码
    func changePassword(oldPassword: String, newPassword: String) async throws {
        try await ensureValidToken()

        let url = URL(string: "\(baseURL)/change-password")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = UserManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body = ChangePasswordRequest(oldPassword: oldPassword, newPassword: newPassword)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            try await refreshTokenIfNeeded()
            return try await changePassword(oldPassword: oldPassword, newPassword: newPassword)
        }

        guard httpResponse.statusCode == 200 else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }

        let result = try JSONDecoder().decode(ApiResponse<String>.self, from: data)

        if !result.isSuccess {
            throw NetworkError.apiError(Self.normalizedBackendMessage(result.msg ?? "修改密码失败"))
        }
    }

    // MARK: - 删除账号
    func deleteAccount(verifyType: String, code: String) async throws {
        try await ensureValidToken()

        let url = URL(string: "\(baseURL)/delete-account")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = UserManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body = DeleteAccountRequest(verifyType: verifyType, code: code)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            try await refreshTokenIfNeeded()
            return try await deleteAccount(verifyType: verifyType, code: code)
        }

        guard httpResponse.statusCode == 200 else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }

        let result = try JSONDecoder().decode(ApiResponse<String>.self, from: data)

        if !result.isSuccess {
            throw NetworkError.apiError(Self.normalizedBackendMessage(result.msg ?? "删除失败"))
        }
    }
    
    // MARK: - 刷新Token
    func refreshToken(refreshToken: String) async throws -> LoginResponse {
        let url = URL(string: "\(baseURL)/refresh-token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = RefreshTokenRequest(refreshToken: refreshToken)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        let result = try JSONDecoder().decode(ApiResponse<LoginResponse>.self, from: data)
        
        if result.isSuccess, let loginResponse = result.data {
            return loginResponse
        } else {
            throw NetworkError.apiError(Self.normalizedBackendMessage(result.msg ?? "刷新Token失败"))
        }
    }
    
    // MARK: - 获取今天的记录详情
    func getTodayRecord() async throws -> TodayRecordResponse? {
        // 确保Token有效
        try await ensureValidToken()
        
        let url = URL(string: "\(baseURL)/get-today-record")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加Token到请求头
        if let token = UserManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // 后端从Token中获取userId，不需要请求体
        request.httpBody = "{}".data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        // 如果是401，尝试刷新Token后重试
        if httpResponse.statusCode == 401 {
            try await refreshTokenIfNeeded()
            // 重试请求
            return try await getTodayRecord()
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        let result = try JSONDecoder().decode(ApiResponse<TodayRecordResponse>.self, from: data)
        
        if result.isSuccess {
            return result.data
        } else {
            return nil
        }
    }
    
    // MARK: - 创建体重记录（以实际后端实现为准）
    func createRecord(weightType: Int) async throws -> Int64 {
        // 确保Token有效
        try await ensureValidToken()

        let url = URL(string: "\(baseURL)/create-record")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 添加Token到请求头
        if let token = UserManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // 后端实际期望: {userId, weightType}，userId 从 Token 解析，此处传 0 占位
        let body = CreateRecordRequest(userId: 0, weightType: weightType)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        // 如果是401，尝试刷新Token后重试
        if httpResponse.statusCode == 401 {
            try await refreshTokenIfNeeded()
            // 重试请求
            return try await createRecord(weightType: weightType)
        }

        guard httpResponse.statusCode == 200 else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }

        let result = try JSONDecoder().decode(ApiResponse<Int64>.self, from: data)

        if result.isSuccess, let recordId = result.data {
            // 更新最后使用时间
            UserManager.shared.updateLastUsedTime()
            return recordId
        } else {
            throw NetworkError.apiError(Self.normalizedBackendMessage(result.msg ?? "创建记录失败"))
        }
    }

    // MARK: - 获取用户信息（契约定义，待后端实现）
    func getUserProfile() async throws -> UserInfo {
        try await ensureValidToken()

        let url = URL(string: "\(baseURL)/user/profile")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = UserManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // 从 Token 中解析 userId，请求体传空对象
        request.httpBody = "{}".data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            try await refreshTokenIfNeeded()
            return try await getUserProfile()
        }

        guard httpResponse.statusCode == 200 else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }

        let result = try JSONDecoder().decode(ApiResponse<UserInfo>.self, from: data)

        if result.isSuccess, let userInfo = result.data {
            UserManager.shared.updateLastUsedTime()
            return userInfo
        } else {
            throw NetworkError.apiError(Self.normalizedBackendMessage(result.msg ?? "获取用户信息失败"))
        }
    }

    // MARK: - 获取体重记录列表（契约定义，待后端实现）
    func getWeightList(startDate: String? = nil, endDate: String? = nil) async throws -> WeightRecordListResponse {
        try await ensureValidToken()

        let url = URL(string: "\(baseURL)/weight/list")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = UserManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // 契约定义参数在 body 中
        var bodyDict: [String: Any] = [:]
        if let startDate = startDate {
            bodyDict["startDate"] = startDate
        }
        if let endDate = endDate {
            bodyDict["endDate"] = endDate
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: bodyDict)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            try await refreshTokenIfNeeded()
            return try await getWeightList(startDate: startDate, endDate: endDate)
        }

        guard httpResponse.statusCode == 200 else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }

        let result = try JSONDecoder().decode(ApiResponse<WeightRecordListResponse>.self, from: data)

        if result.isSuccess, let listResponse = result.data {
            UserManager.shared.updateLastUsedTime()
            return listResponse
        } else {
            throw NetworkError.apiError(Self.normalizedBackendMessage(result.msg ?? "获取记录列表失败"))
        }
    }
    
    // MARK: - 确保Token有效
    private func ensureValidToken() async throws {
        let userManager = UserManager.shared

        // 检查Token是否过期
        if userManager.isTokenExpired() {
            if let existingTask = refreshTask {
                try await existingTask.value
            } else {
                let task = Task { try await _refreshToken() }
                refreshTask = task
                try await task.value
                refreshTask = nil
            }
        }
    }

    // MARK: - 刷新Token（实际逻辑）
    private func _refreshToken() async throws {
        let userManager = UserManager.shared

        guard let refreshTokenValue = userManager.refreshToken else {
            throw NetworkError.apiError("未登录或Token已过期")
        }

        let loginResponse = try await refreshToken(refreshToken: refreshTokenValue)
        userManager.updateToken(
            accessToken: loginResponse.accessToken,
            refreshToken: loginResponse.refreshToken,
            expireTime: loginResponse.expireTime
        )
    }

    // MARK: - 刷新Token（如果需要）
    private func refreshTokenIfNeeded() async throws {
        let userManager = UserManager.shared

        guard let refreshTokenValue = userManager.refreshToken else {
            throw NetworkError.apiError("未登录或Token已过期")
        }

        let loginResponse = try await refreshToken(refreshToken: refreshTokenValue)
        userManager.updateToken(
            accessToken: loginResponse.accessToken,
            refreshToken: loginResponse.refreshToken,
            expireTime: loginResponse.expireTime
        )
    }
    
    private static func normalizedBackendMessage(_ message: String) -> String {
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch trimmedMessage {
        case "", "common.system.error":
            return "服务器开小差了，请稍后重试"
        default:
            return trimmedMessage
        }
    }
}

// MARK: - 网络错误
enum NetworkError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "无效的响应"
        case .httpError(let code):
            return "HTTP错误: \(code)"
        case .apiError(let message):
            return message
        }
    }
}
