//
//  fatApp.swift
//  fat
//
//  Created by Hello World on 2026/1/12.
//

import SwiftUI

@main
struct fatApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    @ObservedObject private var userManager = UserManager.shared
    
    var body: some View {
        Group {
            if userManager.isLoggedIn {
                ContentViewButtons()
                    .transition(.opacity)
                    .onAppear {
                        // 检查Token是否过期
                        if userManager.isTokenExpired() {
                            // Token过期，尝试刷新
                            Task {
                                await refreshTokenIfNeeded()
                            }
                        }
                    }
            } else {
                LoginView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: userManager.isLoggedIn)
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
