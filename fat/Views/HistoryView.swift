//
//  HistoryView.swift
//  fat
//
//  Created by Codex on 2026/4/12.
//

import SwiftUI

// MARK: - 历史记录主视图
struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss

    // 顶部面板数据（首次加载，切换日期不刷新）
    @State private var userProfile: UserInfo?
    @State private var allRecords: [WeightRecordItem] = []
    @State private var isPanelLoading = true

    // 列表数据（随日期切换局部刷新）
    @State private var filteredRecords: [WeightRecordItem] = []
    @State private var isListLoading = false
    @State private var selectedDateRange: DateRange = .last7days

    enum DateRange: String, CaseIterable {
        case last7days = "近7天"
        case last30days = "近30天"
        case all = "全部"

        var startDate: String? {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")

            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())

            switch self {
            case .last7days:
                let start = calendar.date(byAdding: .day, value: -6, to: today)!
                return formatter.string(from: start)
            case .last30days:
                let start = calendar.date(byAdding: .day, value: -29, to: today)!
                return formatter.string(from: start)
            case .all:
                return nil
            }
        }

        var endDate: String? {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
            return formatter.string(from: Date())
        }
    }

    // 统计数据（始终基于全部记录）
    private var totalCount: Int { allRecords.count }
    private var fatCount: Int { allRecords.filter { $0.weightType == 1 }.count }
    private var notFatCount: Int { allRecords.filter { $0.weightType == 2 }.count }

    // 近 7 天数据（固定 7 格，基于全部记录）
    private var last7DaysData: [DayStatus] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")

        return (0..<7).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            let dateStr = formatter.string(from: day)
            let record = allRecords.first { $0.recordDate == dateStr }

            if let record = record, let type = record.weightType {
                return DayStatus(date: day, status: type == 1 ? .fat : .notFat)
            } else {
                return DayStatus(date: day, status: .none)
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 用户信息卡片
                        if let profile = userProfile {
                            UserProfileCard(phone: profile.phone)
                        }

                        // 顶部面板（首次加载时显示）
                        if isPanelLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 100)
                        } else {
                            StatsCard(total: totalCount, fat: fatCount, notFat: notFatCount)
                            WeekTrendChart(data: last7DaysData)
                        }

                        // 日期范围选择
                        dateRangePicker

                        // 记录列表（独立刷新区域）
                        Group {
                            if isListLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity, minHeight: 120)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color(.systemBackground))
                                            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                                    )
                            } else if filteredRecords.isEmpty {
                                EmptyStateView()
                            } else {
                                RecordList(records: filteredRecords)
                            }
                        }
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.25), value: isListLoading)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("历史记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .task {
                await loadPanelData()
            }
        }
    }

    // MARK: - 日期范围选择器
    private var dateRangePicker: some View {
        HStack(spacing: 8) {
            ForEach(DateRange.allCases, id: \.self) { range in
                Button {
                    selectedDateRange = range
                    Task { await loadFilteredList() }
                } label: {
                    Text(range.rawValue)
                        .font(.system(size: 13, weight: selectedDateRange == range ? .semibold : .regular))
                        .foregroundColor(selectedDateRange == range ? .white : .secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(selectedDateRange == range ? Color.primary : Color(.systemGray5))
                        )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - 加载顶部面板数据（仅首次）
    private func loadPanelData() async {
        do {
            async let recordsTask = NetworkService.shared.getWeightList(startDate: nil, endDate: nil)
            async let profileTask = NetworkService.shared.getUserProfile()

            let (listResponse, profile) = try await (recordsTask, profileTask)

            await MainActor.run {
                self.allRecords = listResponse.list
                self.userProfile = profile
                self.isPanelLoading = false
            }

            // 面板加载完成后，加载当前筛选的列表
            await loadFilteredList()
        } catch {
            await MainActor.run {
                self.isPanelLoading = false
            }
        }
    }

    // MARK: - 加载筛选后的列表（切换日期时调用）
    private func loadFilteredList() async {
        do {
            await MainActor.run { isListLoading = true }

            let listResponse = try await NetworkService.shared.getWeightList(
                startDate: selectedDateRange.startDate,
                endDate: selectedDateRange.endDate
            )

            await MainActor.run {
                self.filteredRecords = listResponse.list
                self.isListLoading = false
            }
        } catch {
            await MainActor.run {
                self.filteredRecords = []
                self.isListLoading = false
            }
        }
    }
}

// MARK: - 用户信息卡片
struct UserProfileCard: View {
    let phone: String

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.8), Color.green.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("用户 \(phone)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Text("点击记录今天的状态")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - 统计卡片
struct StatsCard: View {
    let total: Int
    let fat: Int
    let notFat: Int

    var body: some View {
        HStack(spacing: 12) {
            StatItem(
                label: "总记录",
                value: "\(total)",
                icon: "calendar",
                color: .primary
            )

            StatItem(
                label: "胖了",
                value: "\(fat)",
                icon: "arrow.up.circle.fill",
                color: .orange
            )

            StatItem(
                label: "没胖",
                value: "\(notFat)",
                icon: "checkmark.circle.fill",
                color: .green
            )
        }
    }
}

struct StatItem: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - 近 7 天趋势图
struct WeekTrendChart: View {
    let data: [DayStatus]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("近 7 天")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)

            HStack(spacing: 4) {
                ForEach(data.indices, id: \.self) { i in
                    VStack(spacing: 6) {
                        // 状态方块
                        RoundedRectangle(cornerRadius: 6)
                            .fill(statusColor(data[i].status))
                            .frame(width: 36, height: 36)
                            .overlay(
                                statusIcon(data[i].status)
                                    .font(.system(size: 16))
                            )

                        // 星期标签
                        Text(weekdayLabel(data[i].date))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }

    private func statusColor(_ status: DayStatus.Status) -> Color {
        switch status {
        case .fat: return Color.orange.opacity(0.15)
        case .notFat: return Color.green.opacity(0.15)
        case .none: return Color(.systemGray6)
        }
    }

    private func statusIcon(_ status: DayStatus.Status) -> some View {
        Group {
            switch status {
            case .fat:
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(.orange)
            case .notFat:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .none:
                Image(systemName: "minus")
                    .foregroundColor(.secondary)
            }
        }
    }

    private func weekdayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        let weekday = Calendar.current.component(.weekday, from: date)
        let labels = ["日", "一", "二", "三", "四", "五", "六"]
        return labels[weekday - 1]
    }
}

struct DayStatus {
    enum Status { case fat, notFat, none }
    let date: Date
    let status: Status
}

// MARK: - 记录列表
struct RecordList: View {
    let records: [WeightRecordItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("详细记录")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)

            VStack(spacing: 0) {
                ForEach(Array(records.enumerated()), id: \.offset) { _, record in
                    RecordRow(record: record)

                    if record.id != records.last?.id {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
    }
}

struct RecordRow: View {
    let record: WeightRecordItem

    private var isFat: Bool { record.weightType == 1 }
    private var statusColor: Color { isFat ? .orange : .green }
    private var statusText: String { isFat ? "胖了" : "没胖" }
    private var icon: String { isFat ? "arrow.up.circle.fill" : "checkmark.circle.fill" }

    var body: some View {
        HStack(spacing: 12) {
            // 左侧图标
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(statusColor)
                .frame(width: 36)

            // 中间信息
            VStack(alignment: .leading, spacing: 4) {
                Text(statusText)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                if let date = record.recordDate {
                    Text(date)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // 右侧时间
            if let time = record.createTime {
                Text(formatTime(time))
                    .font(.system(size: 12))
                    .foregroundColor(Color(.tertiaryLabel))
            }
        }
        .padding(.vertical, 6)
    }

    private func formatTime(_ time: String) -> String {
        // "2026-04-12T17:25:17" -> "17:25"
        if let index = time.firstIndex(of: "T") {
            let timePart = String(time[index...].dropFirst())
            let components = timePart.split(separator: ":")
            if components.count >= 2 {
                return "\(components[0]):\(components[1])"
            }
        }
        return time
    }
}

// MARK: - 空状态
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("暂无记录")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            Text("完成今日打卡后，这里会显示你的记录")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        HistoryView()
    }
    .environmentObject(UserManager.shared)
}
