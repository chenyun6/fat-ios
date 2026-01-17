//
//  ContentViewButtons.swift
//  fat - 双按钮版本
//
//  Created by Hello World on 2026/1/12.
//

import SwiftUI

struct ContentViewButtons: View {
    @EnvironmentObject var userManager: UserManager
    @State private var selectedOption: WeightOption? = nil
    @State private var showFireworks = false
    @State private var fireworksId = UUID()
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var showSuccessMessage = false
    @State private var hasRecordedToday = false
    @State private var todayRecordType: WeightOption? = nil
    @State private var showLogoutAlert = false
    
    private let recordService = RecordService.shared
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Apple 风格的渐变背景
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGray6).opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 顶部标题区域
                    VStack(spacing: 12) {
                        HStack {
                            Spacer()
                            Button(action: {
                                showLogoutAlert = true
                            }) {
                                Image(systemName: "person.circle")
                                    .font(.system(size: 24))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.trailing, 32)
                        }
                        .padding(.top, 20)
                        .alert("确认退出登录", isPresented: $showLogoutAlert) {
                            Button("取消", role: .cancel) {
                                showLogoutAlert = false
                            }
                            Button("退出", role: .destructive) {
                                userManager.logout()
                            }
                        } message: {
                            Text("退出后需要重新登录才能使用")
                        }
                        
                        Text("今天")
                            .font(.system(size: 17, weight: .regular, design: .default))
                            .foregroundColor(.secondary)
                            .tracking(0.2)
                        
                        Text("今天你胖了吗？")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .tracking(-0.5)
                        
                        // 今天已记录提示
                        if hasRecordedToday, let recordType = todayRecordType {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.green)
                                Text("今天已记录：\(recordType == .fat ? "胖了" : "没胖")")
                                    .font(.system(size: 15, weight: .medium, design: .default))
                                    .foregroundColor(.green)
                            }
                            .padding(.top, 8)
                            .transition(.opacity.combined(with: .scale))
                        } else {
                            Text("诚实一点")
                                .font(.system(size: 15, weight: .regular, design: .default))
                                .foregroundColor(.secondary)
                                .tracking(0.1)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 60)
                    
                    Spacer()
                    
                    // 双按钮区域
                    VStack(spacing: 24) {
                        // 胖了按钮
                        AppleStyleButton(
                            title: "胖了",
                            subtitle: "承认吧",
                            icon: "arrow.up.circle.fill",
                            color: .orange,
                            isSelected: selectedOption == WeightOption.fat,
                            action: {
                                handleSelection(WeightOption.fat)
                            }
                        )
                        
                        // 没胖按钮
                        AppleStyleButton(
                            title: "没胖",
                            subtitle: "继续保持",
                            icon: "checkmark.circle.fill",
                            color: .green,
                            isSelected: selectedOption == WeightOption.notFat,
                            action: {
                                handleSelection(WeightOption.notFat)
                            }
                        )
                    }
                    .padding(.horizontal, 32)
                    .disabled(hasRecordedToday)
                    .opacity(hasRecordedToday ? 0.6 : 1.0)
                    
                    Spacer()
                    
                    // 成功提示
                    if showSuccessMessage, let successMessage = successMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.green)
                            Text(successMessage)
                                .font(.system(size: 15, weight: .medium, design: .default))
                                .foregroundColor(.green)
                        }
                        .padding(.bottom, 20)
                        .transition(.opacity.combined(with: .scale))
                    }
                    
                    // 错误提示
                    if let errorMessage = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.system(size: 15, weight: .regular, design: .default))
                                .foregroundColor(.red)
                        }
                        .padding(.bottom, 20)
                        .transition(.opacity.combined(with: .scale))
                    }
                }
                
                // Apple 风格烟花效果
                if showFireworks {
                    AppleStyleFeedback(
                        id: fireworksId,
                        centerX: geometry.size.width / 2,
                        centerY: geometry.size.height / 2,
                        isPositive: selectedOption == WeightOption.notFat
                    )
                    .transition(.opacity)
                }
                
                // 加载指示器
                if isLoading {
                    Color(.systemBackground).opacity(0.8)
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                }
            }
        }
        .onAppear {
            checkTodayRecord()
        }
    }
    
    // MARK: - 检查今天是否已记录
    private func checkTodayRecord() {
        guard let userId = userManager.userId else {
            hasRecordedToday = false
            todayRecordType = nil
            return
        }
        
        // 先检查本地缓存
        recordService.checkAndClearIfNeeded(userId: userId)
        let localHasRecord = recordService.hasRecordedToday(userId: userId)
        let localRecordType = recordService.getTodayRecordType(userId: userId)
        
        // 先使用本地缓存状态（立即显示）
        hasRecordedToday = localHasRecord
        todayRecordType = localRecordType
        
        // 从后端查询今天的记录详情（同步状态）
        Task {
            do {
                let todayRecord = try await NetworkService.shared.getTodayRecord()
                await MainActor.run {
                    if let record = todayRecord, let weightType = record.weightType {
                        // 后端有记录，同步本地状态
                        let recordType: WeightOption = weightType == 1 ? .fat : .notFat
                        recordService.saveTodayRecord(type: recordType, userId: userId)
                        hasRecordedToday = true
                        todayRecordType = recordType
                    } else if todayRecord == nil && localHasRecord {
                        // 后端没有记录但本地有：清除本地状态
                        recordService.clearTodayRecord(userId: userId)
                        hasRecordedToday = false
                        todayRecordType = nil
                    } else if todayRecord == nil {
                        // 后端没有记录，确保本地也没有
                        hasRecordedToday = false
                        todayRecordType = nil
                    }
                }
            } catch {
                // 网络请求失败，保持使用本地缓存
                print("⚠️ 查询今天是否已记录失败: \(error)")
            }
        }
    }
    
    // MARK: - 选择处理
    private func handleSelection(_ option: WeightOption) {
        // 检查今天是否已记录
        if hasRecordedToday {
            errorMessage = "今天已经记录过了，明天再来吧~"
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation {
                    errorMessage = nil
                }
            }
            return
        }
        guard userManager.isLoggedIn else {
            errorMessage = "用户未登录"
            return
        }
        
        selectedOption = option
        isLoading = true
        errorMessage = nil
        
        // 触觉反馈
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // 调用后端API（不需要传递userId，从Token中获取）
        let weightType = option == .fat ? 1 : 2
        
        Task {
            do {
                _ = try await NetworkService.shared.createRecord(weightType: weightType)
                await MainActor.run {
                    isLoading = false
                    
                    // 保存今天的记录
                    if let userId = userManager.userId {
                        recordService.saveTodayRecord(type: option, userId: userId)
                        hasRecordedToday = true
                        todayRecordType = option
                    }
                    
                    // 显示成功消息
                    successMessage = option == .fat ? "已记录：今天胖了" : "已记录：今天没胖"
                    showSuccessMessage = true
                    
                    // 显示烟花效果
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showFireworks = true
                            fireworksId = UUID()
                        }
                    }
                    
                    // 隐藏烟花效果和成功消息
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            showFireworks = false
                        }
                    }
                    
                    // 3秒后隐藏成功消息
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation {
                            showSuccessMessage = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    // 友好的错误提示
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .apiError(let message):
                            errorMessage = message
                        case .httpError(let code):
                            if code == 401 {
                                errorMessage = "登录已过期，请重新登录"
                                // 自动登出
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                    userManager.logout()
                                }
                            } else {
                                errorMessage = "网络错误，请稍后重试"
                            }
                        default:
                            errorMessage = "操作失败，请稍后重试"
                        }
                    } else {
                        errorMessage = error.localizedDescription
                    }
                    
                    // 5秒后自动隐藏错误消息
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        withAnimation {
                            errorMessage = nil
                        }
                    }
                }
            }
        }
    }
}



#Preview {
    ContentViewButtons()
        .environmentObject(UserManager.shared)
}
