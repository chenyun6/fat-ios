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
        // 先保存到UserDefaults
        UserDefaults.standard.set(String(userId), forKey: userIdKey)
        UserDefaults.standard.set(phone, forKey: phoneKey)
        UserDefaults.standard.set(accessToken, forKey: accessTokenKey)
        UserDefaults.standard.set(refreshToken, forKey: refreshTokenKey)
        UserDefaults.standard.set(expireTime, forKey: expireTimeKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastUsedTimeKey)
        UserDefaults.standard.synchronize()
        
        print("📝 UserDefaults 已保存: userId=\(userId), phone=\(phone)")
        
        // 更新 @Published 属性，触发视图刷新
        // 注意：此方法应在主线程调用（已在 MainActor.run 中调用）
        let oldIsLoggedIn = self.isLoggedIn
        
        // 先更新其他属性
        self.userId = userId
        self.phone = phone
        
        // 直接更新状态，无论之前是什么值
        print("🔄 准备更新 isLoggedIn: \(oldIsLoggedIn) -> true")
        print("📍 当前线程: \(Thread.isMainThread ? "主线程" : "后台线程")")
        print("📍 UserManager 实例地址: \(Unmanaged.passUnretained(self).toOpaque())")
        
        // 如果之前已经是 true，先设为 false 触发一次变化
        if oldIsLoggedIn {
            print("⚠️ isLoggedIn 已经是 true，先设为 false 再设为 true")
            self.isLoggedIn = false
            print("📝 isLoggedIn 已设为 false")
            // 立即触发一次更新
            objectWillChange.send()
            print("📢 objectWillChange 已发送 (false)")
            
            // 使用 Task 确保在下一个 runloop 中设置为 true
            Task { @MainActor [weak self] in
                guard let self = self else {
                    print("❌ self 已被释放")
                    return
                }
                print("📍 Task 中，当前线程: \(Thread.isMainThread ? "主线程" : "后台线程")")
                print("📍 Task 中，UserManager 实例地址: \(Unmanaged.passUnretained(self).toOpaque())")
                self.isLoggedIn = true
                print("✅ isLoggedIn 已设置为 true (在 Task 中)")
                // 再次触发更新，确保视图刷新
                self.objectWillChange.send()
                print("📢 objectWillChange 已发送 (true, 在 Task 中)")
            }
        } else {
            // 如果之前是 false，直接设置为 true
            self.isLoggedIn = true
            print("✅ isLoggedIn 已设置为 true (直接设置)")
            // 再次触发更新，确保视图刷新
            objectWillChange.send()
            print("📢 objectWillChange 已发送 (true, 直接设置)")
        }
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
