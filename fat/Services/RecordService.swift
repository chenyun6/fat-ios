//
//  RecordService.swift
//  fat
//
//  Created by Hello World on 2026/1/12.
//

import Foundation

class RecordService {
    static let shared = RecordService()
    
    private let todayRecordKeyPrefix = "today_record_date_"
    private let todayRecordTypeKeyPrefix = "today_record_type_"
    
    private init() {}
    
    // MARK: - 获取当前用户的记录Key
    private func getRecordDateKey(userId: Int64?) -> String {
        guard let userId = userId else {
            return "today_record_date_guest"
        }
        return "\(todayRecordKeyPrefix)\(userId)"
    }
    
    private func getRecordTypeKey(userId: Int64?) -> String {
        guard let userId = userId else {
            return "today_record_type_guest"
        }
        return "\(todayRecordTypeKeyPrefix)\(userId)"
    }
    
    // MARK: - 检查今天是否已记录
    func hasRecordedToday(userId: Int64? = nil) -> Bool {
        let userId = userId ?? UserManager.shared.userId
        let recordDateKey = getRecordDateKey(userId: userId)
        
        guard let lastRecordDate = UserDefaults.standard.string(forKey: recordDateKey) else {
            return false
        }
        
        let today = getTodayString()
        return lastRecordDate == today
    }
    
    // MARK: - 获取今天记录的类型
    func getTodayRecordType(userId: Int64? = nil) -> WeightOption? {
        let userId = userId ?? UserManager.shared.userId
        
        guard hasRecordedToday(userId: userId),
              let typeString = UserDefaults.standard.string(forKey: getRecordTypeKey(userId: userId)),
              let typeInt = Int(typeString) else {
            return nil
        }
        return typeInt == 1 ? .fat : .notFat
    }
    
    // MARK: - 保存今天的记录
    func saveTodayRecord(type: WeightOption, userId: Int64? = nil) {
        let userId = userId ?? UserManager.shared.userId
        let today = getTodayString()
        UserDefaults.standard.set(today, forKey: getRecordDateKey(userId: userId))
        UserDefaults.standard.set(type == .fat ? "1" : "2", forKey: getRecordTypeKey(userId: userId))
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - 清除今天的记录（用于测试或重置）
    func clearTodayRecord(userId: Int64? = nil) {
        let userId = userId ?? UserManager.shared.userId
        UserDefaults.standard.removeObject(forKey: getRecordDateKey(userId: userId))
        UserDefaults.standard.removeObject(forKey: getRecordTypeKey(userId: userId))
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - 清除所有用户的记录（用于切换用户时）
    func clearAllUserRecords() {
        // 清除所有以 today_record_date_ 开头的key
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            if key.hasPrefix(todayRecordKeyPrefix) || key.hasPrefix(todayRecordTypeKeyPrefix) {
                defaults.removeObject(forKey: key)
            }
        }
        defaults.synchronize()
    }
    
    // MARK: - 获取今天的日期字符串
    private func getTodayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        return formatter.string(from: Date())
    }
    
    // MARK: - 检查是否需要清除昨天的记录
    func checkAndClearIfNeeded(userId: Int64? = nil) {
        let userId = userId ?? UserManager.shared.userId
        let recordDateKey = getRecordDateKey(userId: userId)
        
        guard let lastRecordDate = UserDefaults.standard.string(forKey: recordDateKey) else {
            return
        }
        
        let today = getTodayString()
        if lastRecordDate != today {
            // 不是今天，清除记录
            clearTodayRecord(userId: userId)
        }
    }
}
