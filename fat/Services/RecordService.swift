//
//  RecordService.swift
//  fat
//
//  Created by Hello World on 2026/1/12.
//

import Foundation

class RecordService {
    static let shared = RecordService()
    
    private let todayRecordKey = "today_record_date"
    private let todayRecordTypeKey = "today_record_type"
    
    private init() {}
    
    // MARK: - 检查今天是否已记录
    func hasRecordedToday() -> Bool {
        guard let lastRecordDate = UserDefaults.standard.string(forKey: todayRecordKey) else {
            return false
        }
        
        let today = getTodayString()
        return lastRecordDate == today
    }
    
    // MARK: - 获取今天记录的类型
    func getTodayRecordType() -> WeightOption? {
        guard hasRecordedToday(),
              let typeString = UserDefaults.standard.string(forKey: todayRecordTypeKey),
              let typeInt = Int(typeString) else {
            return nil
        }
        return typeInt == 1 ? .fat : .notFat
    }
    
    // MARK: - 保存今天的记录
    func saveTodayRecord(type: WeightOption) {
        let today = getTodayString()
        UserDefaults.standard.set(today, forKey: todayRecordKey)
        UserDefaults.standard.set(type == .fat ? "1" : "2", forKey: todayRecordTypeKey)
    }
    
    // MARK: - 清除今天的记录（用于测试或重置）
    func clearTodayRecord() {
        UserDefaults.standard.removeObject(forKey: todayRecordKey)
        UserDefaults.standard.removeObject(forKey: todayRecordTypeKey)
    }
    
    // MARK: - 获取今天的日期字符串
    private func getTodayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        return formatter.string(from: Date())
    }
    
    // MARK: - 检查是否需要清除昨天的记录
    func checkAndClearIfNeeded() {
        guard let lastRecordDate = UserDefaults.standard.string(forKey: todayRecordKey) else {
            return
        }
        
        let today = getTodayString()
        if lastRecordDate != today {
            // 不是今天，清除记录
            clearTodayRecord()
        }
    }
}
