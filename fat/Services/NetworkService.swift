//
//  NetworkService.swift
//  fat
//
//  Created by Hello World on 2026/1/12.
//

import Foundation

class NetworkService {
    static let shared = NetworkService()
    
    // 后端API基础URL - 根据实际情况修改
    private let baseURL = "http://localhost:8080/web/weight"
    
    private init() {}
    
    // MARK: - 发送验证码
    func sendCode(phone: String) async throws -> String {
        let url = URL(string: "\(baseURL)/send-code")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = SendCodeRequest(phone: phone)
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        let result = try JSONDecoder().decode(ApiResponse<String>.self, from: data)
        
        if result.isSuccess, let message = result.data {
            return message
        } else {
            throw NetworkError.apiError(result.msg ?? "发送验证码失败")
        }
    }
    
    // MARK: - 登录
    func login(phone: String, code: String) async throws -> LoginResponse {
        let url = URL(string: "\(baseURL)/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = LoginRequest(phone: phone, code: code)
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
            throw NetworkError.apiError(result.msg ?? "登录失败")
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
            throw NetworkError.apiError(result.msg ?? "刷新Token失败")
        }
    }
    
    // MARK: - 创建体重记录（带Token自动刷新）
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
        
        // 注意：userId现在从Token中获取，不需要在请求体中传递
        let body = CreateRecordRequest(userId: 0, weightType: weightType)  // userId会被后端从Token中获取
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
            throw NetworkError.apiError(result.msg ?? "创建记录失败")
        }
    }
    
    // MARK: - 确保Token有效
    private func ensureValidToken() async throws {
        let userManager = UserManager.shared
        
        // 检查Token是否过期
        if userManager.isTokenExpired() {
            // Token过期，尝试刷新
            try await refreshTokenIfNeeded()
        }
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
