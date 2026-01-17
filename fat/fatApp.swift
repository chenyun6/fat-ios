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
    @ObservedObject var userManager = UserManager.shared
    @State private var viewId = UUID()
    
    var body: some View {
        let _ = print("🔄 RootView body 重新计算，userManager.isLoggedIn = \(userManager.isLoggedIn), viewId = \(viewId)")
        
        ZStack {
            if userManager.isLoggedIn {
                let _ = print("✅ RootView: 准备显示 ContentViewButtons")
                ContentViewButtons()
                    .id("ContentView-\(viewId)")
                    .environmentObject(userManager)
                    .transition(.opacity)
                    .onAppear {
                        print("✅ ContentViewButtons 已显示")
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
                    .id("LoginView-\(viewId)")
                    .environmentObject(userManager)
                    .transition(.opacity)
                    .onAppear {
                        print("📱 LoginView 已显示")
                    }
            }
        }
        .id("RootView-\(userManager.isLoggedIn)-\(viewId)")
        .animation(.easeInOut(duration: 0.3), value: userManager.isLoggedIn)
        .onChange(of: userManager.isLoggedIn) { oldValue, newValue in
            print("🔄 RootView onChange: isLoggedIn 从 \(oldValue) 变为 \(newValue)")
            viewId = UUID()
            print("🔄 viewId 已更新为: \(viewId)")
        }
        .onReceive(userManager.$isLoggedIn) { newValue in
            print("📡 RootView onReceive: isLoggedIn = \(newValue)")
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
