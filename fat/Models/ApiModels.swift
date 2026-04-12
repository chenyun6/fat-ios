//
//  ApiModels.swift
//  fat
//
//  Created by Hello World on 2026/1/12.
//

import Foundation

// MARK: - API 响应模型（匹配后端ResultDTO）
struct ApiResponse<T: Codable>: Codable {
    let code: Int?
    let msg: String?
    let data: T?
    let success: Bool?
    
    // 兼容性：检查是否成功
    var isSuccess: Bool {
        if let success = success {
            return success
        }
        // 后端实际返回 code: 100 表示成功
        return code == 0 || code == 100 || code == 200
    }
}

// MARK: - 发送验证码请求
struct SendCodeRequest: Codable {
    let phone: String
}

// MARK: - 登录请求
struct LoginRequest: Codable {
    let phone: String
    let code: String
}

// MARK: - 创建体重记录请求
struct CreateRecordRequest: Codable {
    let userId: Int64
    let weightType: Int  // 1-胖了，2-瘦了
}

// MARK: - 登录响应
struct LoginResponse: Codable {
    let userId: Int64
    let accessToken: String
    let refreshToken: String
    let expireTime: Int64  // 毫秒时间戳
}

// MARK: - 刷新Token请求
struct RefreshTokenRequest: Codable {
    let refreshToken: String
}

struct TodayRecordResponse: Codable {
    let id: Int64?
    let userId: Int64?
    let weightType: Int?
    let recordDate: String?
    let createTime: String?
}

// MARK: - 用户信息
struct UserInfo: Codable {
    let userId: Int64
    let phone: String
    let hasPassword: Bool?
}

// MARK: - 体重记录列表响应
struct WeightRecordListResponse: Codable {
    let list: [WeightRecordItem]
    let total: Int
}

struct WeightRecordItem: Codable {
    let id: Int64?
    let userId: Int64?
    let weightType: Int?
    let recordDate: String?
    let createTime: String?
}

// MARK: - 密码登录请求
struct PasswordLoginRequest: Codable {
    let phone: String
    let password: String
}

// MARK: - 设置密码请求
struct SetPasswordRequest: Codable {
    let password: String
}

// MARK: - 修改密码请求
struct ChangePasswordRequest: Codable {
    let oldPassword: String
    let newPassword: String
}

// MARK: - 删除账号请求
struct DeleteAccountRequest: Codable {
    let verifyType: String  // "sms" 或 "password"
    let code: String        // 验证码或密码
}
