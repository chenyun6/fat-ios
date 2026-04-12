# ATS 配置说明 - 允许 HTTP 连接

## 📋 问题描述

iOS 的 App Transport Security (ATS) 默认要求所有网络连接使用 HTTPS 加密。当连接 HTTP 服务器时会报错：

```
The resource could not be loaded because the App Transport Security policy
requires the use of a secure connection.
```

## ✅ 已完成的修改

### 1. 创建 Info.plist 文件
**位置**: `/fat/Info.plist`

已添加 ATS 配置，允许 HTTP 连接：

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <!-- 方案1：允许所有不安全的 HTTP 加载（开发环境） -->
    <key>NSAllowsArbitraryLoads</key>
    <true/>

    <!-- 方案2：只允许特定域名（更安全，推荐生产环境） -->
    <key>NSExceptionDomains</key>
    <dict>
        <key>11.192.195.121</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
        <key>localhost</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

### 2. 修正后端地址
**位置**: `/fat/Services/NetworkService.swift`

已将 `111.192.195.121` 修正为 `11.192.195.121`

---

## 🔧 Xcode 配置步骤

### 方法1：通过 Xcode 界面配置（推荐）

1. **打开 Xcode 项目**
   - 双击 `fat.xcodeproj` 打开项目

2. **选择 Target**
   - 在左侧导航栏选择项目名称
   - 在 TARGETS 列表中选择 "fat"

3. **配置 Info.plist**
   - 选择 "Info" 标签页
   - 如果看到 "Generate Info.plist File" 选项，**取消勾选**
   - 在 "Custom iOS Target Properties" 下，找到或添加 `NSAppTransportSecurity`

4. **添加 ATS 例外**
   - 点击 "Custom iOS Target Properties" 右侧的 `+` 按钮
   - 添加 Key: `App Transport Security Settings` (NSAppTransportSecurity)
   - 展开这个条目，点击右侧的 `+` 按钮
   - 添加：
     - `Allow Arbitrary Loads` (NSAllowsArbitraryLoads) = `YES`

5. **保存并重新编译**
   - Command + B 编译项目
   - Command + R 运行项目

---

### 方法2：手动编辑 project.pbxproj（高级）

如果 Xcode 界面配置不生效，可以手动修改项目文件：

1. **打开项目配置文件**
   ```bash
   open /Users/huyingjun/handsome/fat-ios/fat.xcodeproj/project.pbxproj
   ```

2. **查找并修改**
   搜索 `GENERATE_INFOPLIST_FILE`，将其改为：
   ```
   GENERATE_INFOPLIST_FILE = NO;
   ```

3. **添加 Info.plist 路径**
   在同一个配置块中添加：
   ```
   INFOPLIST_FILE = fat/Info.plist;
   ```

4. **保存并重新打开项目**

---

## 🎯 验证配置

### 1. 检查 Info.plist 是否生效

运行应用后，在控制台查看日志：
```
📤 发送登录请求: http://11.192.195.121:8080/web/weight/login
```

如果能看到网络请求日志，说明配置成功。

### 2. 测试后端连接

```bash
# 测试后端是否可访问
curl -X POST http://11.192.195.121:8080/web/weight/send-code \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000"}'
```

---

## ⚠️ 安全提示

### 开发环境 vs 生产环境

**当前配置（开发环境）**:
```xml
<key>NSAllowsArbitraryLoads</key>
<true/>
```
- ✅ 允许所有 HTTP 连接，方便开发
- ❌ 不安全，不推荐用于生产环境

**生产环境推荐配置**:
```xml
<key>NSAllowsArbitraryLoads</key>
<false/>
<key>NSExceptionDomains</key>
<dict>
    <key>your-production-domain.com</key>
    <dict>
        <key>NSExceptionAllowsInsecureHTTPLoads</key>
        <true/>
    </dict>
</dict>
```
- ✅ 只允许特定域名的 HTTP 连接
- ✅ 其他连接仍需要 HTTPS

**最佳实践（生产环境）**:
- 🔒 使用 HTTPS 加密所有 API 连接
- 🔒 申请 SSL 证书
- 🔒 完全移除 ATS 例外配置

---

## 🐛 常见问题

### Q1: 修改后仍然报错？
**解决方案**:
1. 完全清理项目：Product → Clean Build Folder (Command + Shift + K)
2. 删除 Derived Data：
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
3. 重启 Xcode
4. 重新运行项目

### Q2: Info.plist 找不到？
**解决方案**:
- 确保 `fat/Info.plist` 文件存在
- 在 Xcode 左侧文件导航中，右键点击 "fat" 文件夹
- 选择 "Add Files to fat..."
- 选择 `Info.plist` 文件并添加

### Q3: 配置了 ATS 但网络请求超时？
**检查清单**:
- [ ] 后端服务是否启动？
- [ ] IP 地址是否正确？`11.192.195.121`
- [ ] 端口是否正确？`8080`
- [ ] 防火墙是否阻止连接？
- [ ] 使用 `curl` 测试后端是否可访问

### Q4: Xcode 中看不到 Info 标签页？
**解决方案**:
- 确保选择了 TARGETS 中的 "fat"，而不是 PROJECT
- 点击顶部标签栏中的 "Info"

---

## 📝 下一步操作

### 立即执行：

1. **打开 Xcode**
   ```bash
   open /Users/huyingjun/handsome/fat-ios/fat.xcodeproj
   ```

2. **在 Xcode 中配置**
   - 选择 fat target → Info 标签
   - 取消 "Generate Info.plist File" 勾选
   - 或者按照上面的方法添加 ATS 配置

3. **清理并重新编译**
   - Command + Shift + K (Clean Build Folder)
   - Command + B (Build)
   - Command + R (Run)

4. **测试登录功能**
   - 输入任意11位手机号
   - 获取验证码
   - 输入验证码
   - 登录

---

## 📊 配置检查清单

- [x] 创建 Info.plist 文件
- [x] 添加 NSAppTransportSecurity 配置
- [x] 修正后端 IP 地址（11.192.195.121）
- [ ] 在 Xcode 中禁用自动生成 Info.plist
- [ ] 清理项目缓存
- [ ] 重新编译运行
- [ ] 测试网络连接

---

**最后更新**: 2026年1月17日
**后端地址**: http://11.192.195.121:8080/web/weight
