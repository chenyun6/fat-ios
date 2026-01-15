//
//  UserManager.swift
//  fat
//
//  Created by Hello World on 2026/1/12.
//

import Foundation
import Combine

class UserManager: ObservableObject {
    static let shared = UserManager()
    
    @Published var isLoggedIn: Bool = false
    @Published var userId: Int64?
    @Published var phone: String?
    
    private let userIdKey = "saved_user_id"
    private let phoneKey = "saved_phone"
    private let accessTokenKey = "saved_access_token"
    private let refreshTokenKey = "saved_refresh_token"
    private let expireTimeKey = "saved_expire_time"
    private let lastUsedTimeKey = "saved_last_used_time"
    
    var accessToken: String? {
        return UserDefaults.standard.string(forKey: accessTokenKey)
    }
    
    var refreshToken: String? {
        return UserDefaults.standard.string(forKey: refreshTokenKey)
    }
    
    private init() {
        loadUserInfo()
        checkTokenExpiration()
    }
    
    // MARK: - 保存用户信息和Token
    func saveUserInfo(userId: Int64, phone: String, accessToken: String, refreshToken: String, expireTime: Int64) {
        // 注意：此方法应在主线程调用
        // 先保存到UserDefaults
        UserDefaults.standard.set(String(userId), forKey: userIdKey)
        UserDefaults.standard.set(phone, forKey: phoneKey)
        UserDefaults.standard.set(accessToken, forKey: accessTokenKey)
        UserDefaults.standard.set(refreshToken, forKey: refreshTokenKey)
        UserDefaults.standard.set(expireTime, forKey: expireTimeKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastUsedTimeKey)
        
        // 最后更新 @Published 属性，触发视图刷新
        self.userId = userId
        self.phone = phone
        self.isLoggedIn = true
        
        // 手动触发 objectWillChange 确保视图更新
        objectWillChange.send()
    }
    
    // MARK: - 更新Token
    func updateToken(accessToken: String, refreshToken: String, expireTime: Int64) {
        UserDefaults.standard.set(accessToken, forKey: accessTokenKey)
        UserDefaults.standard.set(refreshToken, forKey: refreshTokenKey)
        UserDefaults.standard.set(expireTime, forKey: expireTimeKey)
        updateLastUsedTime()
    }
    
    // MARK: - 更新最后使用时间
    func updateLastUsedTime() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastUsedTimeKey)
    }
    
    // MARK: - 加载用户信息
    private func loadUserInfo() {
        if let userIdString = UserDefaults.standard.string(forKey: userIdKey),
           let userId = Int64(userIdString),
           let phone = UserDefaults.standard.string(forKey: phoneKey),
           let _ = UserDefaults.standard.string(forKey: accessTokenKey) {
            self.userId = userId
            self.phone = phone
            self.isLoggedIn = true
        }
    }
    
    // MARK: - 检查Token过期（7天未使用）
    private func checkTokenExpiration() {
        guard let lastUsedTime = UserDefaults.standard.object(forKey: lastUsedTimeKey) as? TimeInterval else {
            return
        }
        
        let sevenDaysAgo = Date().timeIntervalSince1970 - (7 * 24 * 60 * 60)
        if lastUsedTime < sevenDaysAgo {
            // 7天未使用，清除登录状态
            logout()
        }
    }
    
    // MARK: - 检查Token是否过期
    func isTokenExpired() -> Bool {
        guard let expireTime = UserDefaults.standard.object(forKey: expireTimeKey) as? Int64 else {
            return true
        }
        
        let expireDate = Date(timeIntervalSince1970: TimeInterval(expireTime / 1000))
        return expireDate < Date()
    }
    
    // MARK: - 登出
    func logout() {
        self.userId = nil
        self.phone = nil
        self.isLoggedIn = false
        
        UserDefaults.standard.removeObject(forKey: userIdKey)
        UserDefaults.standard.removeObject(forKey: phoneKey)
        UserDefaults.standard.removeObject(forKey: accessTokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: expireTimeKey)
        UserDefaults.standard.removeObject(forKey: lastUsedTimeKey)
    }
}
