//
//  fatApp.swift
//  fat
//
//  Created by Hello World on 2026/1/12.
//

import SwiftUI
import Combine

@main
struct fatApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(UserManager.shared)
                .onAppear {
                    print("🚀 App 启动，isLoggedIn = \(UserManager.shared.isLoggedIn)")
                }
        }
    }
}

struct RootView: View {
    @ObservedObject private var userManager = UserManager.shared
    @State private var isLoggedIn: Bool = false
    
    var body: some View {
        let _ = print("🔄 RootView body 重新计算，isLoggedIn = \(isLoggedIn), userManager.isLoggedIn = \(userManager.isLoggedIn)")
        
        return Group {
            if isLoggedIn {
                let _ = print("✅ RootView: 准备显示 ContentViewButtons")
                ContentViewButtons()
                    .id("ContentView")
                    .environmentObject(UserManager.shared)
                    .transition(.opacity)
                    .onAppear {
                        print("✅ ContentViewButtons 已显示，isLoggedIn = \(isLoggedIn)")
                        // 检查Token是否过期
                        if userManager.isTokenExpired() {
                            // Token过期，尝试刷新
                            Task {
                                await refreshTokenIfNeeded()
                            }
                        }
                    }
            } else {
                let _ = print("📱 RootView: 准备显示 LoginView")
                LoginView()
                    .id("LoginView")
                    .environmentObject(UserManager.shared)
                    .transition(.opacity)
                    .onAppear {
                        print("📱 LoginView 已显示，isLoggedIn = \(isLoggedIn)")
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoggedIn)
        .onAppear {
            print("🎬 RootView onAppear，isLoggedIn = \(userManager.isLoggedIn)")
            isLoggedIn = userManager.isLoggedIn
        }
        .onChange(of: userManager.isLoggedIn) { newValue in
            print("🔄 onChange: userManager.isLoggedIn = \(newValue)")
            isLoggedIn = newValue
        }
        .onReceive(userManager.$isLoggedIn) { newValue in
            print("📡 onReceive: userManager.isLoggedIn = \(newValue)")
            isLoggedIn = newValue
        }
        .onReceive(userManager.objectWillChange) { _ in
            print("📢 RootView 收到 objectWillChange 通知，当前 userManager.isLoggedIn = \(userManager.isLoggedIn)")
            // 同步状态
            isLoggedIn = userManager.isLoggedIn
        }
    }
    
    // MARK: - 刷新Token
    private func refreshTokenIfNeeded() async {
        guard let refreshToken = userManager.refreshToken else {
            userManager.logout()
            return
        }
        
        do {
            let loginResponse = try await NetworkService.shared.refreshToken(refreshToken: refreshToken)
            await MainActor.run {
                userManager.updateToken(
                    accessToken: loginResponse.accessToken,
                    refreshToken: loginResponse.refreshToken,
                    expireTime: loginResponse.expireTime
                )
            }
        } catch {
            // 刷新失败，登出
            await MainActor.run {
                userManager.logout()
            }
        }
    }
}
