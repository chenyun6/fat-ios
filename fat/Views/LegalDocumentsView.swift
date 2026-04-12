//
//  LegalDocumentsView.swift
//  fat
//
//  Created by Codex on 2026/3/22.
//

import SwiftUI

enum LegalDocument: String, Identifiable {
    case terms
    case privacy
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .terms:
            return "用户协议"
        case .privacy:
            return "隐私政策"
        }
    }
    
    var intro: String {
        switch self {
        case .terms:
            return "正式发布前，请再次确认本页内容与官网公示页及实际服务规则一致。"
        case .privacy:
            return "发布前请确保联系方式、删除机制与真实后端能力一致。"
        }
    }
    
    var sections: [LegalSection] {
        switch self {
        case .terms:
            return [
                LegalSection(
                    title: "一、协议适用范围",
                    paragraphs: [
                        "\(AppReleaseInfo.appName) 由开发者通过 iOS 客户端和相关服务向用户提供每日体重状态记录服务。",
                        "你在注册、登录、浏览或使用本服务时，即表示你已阅读、理解并同意受本协议约束。"
                    ]
                ),
                LegalSection(
                    title: "二、服务内容",
                    paragraphs: [
                        "本服务当前主要提供手机号验证码登录、每日“胖了/没胖”记录、记录状态同步等功能。",
                        "我们有权根据产品运营情况对功能进行更新、调整、维护或下线，并会在合理范围内提前提示。"
                    ]
                ),
                LegalSection(
                    title: "三、账号规则",
                    paragraphs: [
                        "你应当使用本人合法持有的手机号完成登录，并妥善保管验证码、登录状态及相关设备。",
                        "你不得冒用他人身份、批量注册、恶意调用接口、攻击服务或利用本服务从事违法违规活动。",
                        "如因你的不当使用导致账号被盗、数据异常、服务中断或第三方损失，相关责任由你自行承担。"
                    ]
                ),
                LegalSection(
                    title: "四、用户行为规范",
                    paragraphs: [
                        "你承诺遵守中华人民共和国相关法律法规，不得利用本服务发布、传播或存储违法信息。",
                        "你不得干扰本服务正常运行，不得进行逆向工程、抓包滥用、批量请求或其他影响平台稳定性的行为。"
                    ]
                ),
                LegalSection(
                    title: "五、责任声明",
                    paragraphs: [
                        "本服务提供的是轻量级体重状态记录工具，不构成医疗建议、营养建议或减肥方案。",
                        "因不可抗力、网络故障、第三方服务异常、系统维护、黑客攻击或通信运营商原因造成的服务中断、延迟、短信失败或数据异常，我们将在法律允许范围内尽力处理，但不承担超出法定范围的责任。"
                    ]
                ),
                LegalSection(
                    title: "六、协议变更与终止",
                    paragraphs: [
                        "我们可根据法律法规、监管要求或产品迭代需要更新本协议。更新后如你继续使用本服务，即视为接受更新后的协议。",
                        "如你违反本协议，或我们基于安全、合规、运营需要判断有必要时，可限制、中止或终止向你提供服务。"
                    ]
                ),
                LegalSection(
                    title: "七、联系我们",
                    paragraphs: [
                        "如你对本协议有疑问，可通过以下方式联系我们：\(AppReleaseInfo.supportEmail)",
                        "建议同时在官网提供客服入口和问题反馈页面，便于审核人员和用户查阅。"
                    ]
                )
            ]
        case .privacy:
            return [
                LegalSection(
                    title: "一、我们收集哪些信息",
                    paragraphs: [
                        "账号与登录信息：手机号、验证码登录过程产生的用户编号、访问令牌、刷新令牌。",
                        "业务数据：你每日提交的体重状态记录（如“胖了/没胖”、记录日期、记录时间）。",
                        "必要的设备与日志信息：为保障接口安全和排查故障，服务器可能记录请求时间、IP、设备基础信息和错误日志。",
                        "我们当前不会主动向你请求通讯录、相册、麦克风、定位等与核心功能无关的权限数据。"
                    ]
                ),
                LegalSection(
                    title: "二、我们如何使用这些信息",
                    paragraphs: [
                        "用于完成手机号验证码登录、识别用户身份、维持登录状态与保障账号安全。",
                        "用于保存、展示和同步你的每日记录，防止重复打卡，并提升服务稳定性。",
                        "用于接口监控、问题排查、风控分析与产品基础运维。"
                    ]
                ),
                LegalSection(
                    title: "三、我们是否共享你的信息",
                    paragraphs: [
                        "除法律法规另有要求外，我们不会出售你的个人信息。",
                        "在实现核心功能所必需的范围内，我们可能与短信服务提供商、云服务器或基础设施服务商共享必要数据，例如手机号、验证码发送请求或接口访问日志。",
                        "如我们接入第三方服务商，我们会要求其按照不低于本政策的标准保护你的信息。"
                    ]
                ),
                LegalSection(
                    title: "四、数据保存与删除",
                    paragraphs: [
                        "我们会在实现产品功能和满足法律法规要求所必需的期限内保存你的账号与记录数据。",
                        "你可以通过应用内后续提供的账号删除能力，或发送邮件至 \(AppReleaseInfo.privacyEmail) 申请删除账号与相关数据。",
                        "在正式发布前，请确保删除路径、处理时效和后端实际能力一致；如果尚未提供应用内删除入口，建议不要提交审核。"
                    ]
                ),
                LegalSection(
                    title: "五、你的权利",
                    paragraphs: [
                        "你有权查询、更正、删除你的个人信息，并可撤回基于同意进行的数据处理请求。",
                        "如你对隐私处理有疑问、投诉或建议，可通过 \(AppReleaseInfo.privacyEmail) 联系我们。"
                    ]
                ),
                LegalSection(
                    title: "六、未成年人保护",
                    paragraphs: [
                        "如你是未成年人，请在监护人阅读并同意本政策后使用本服务。",
                        "如我们发现未经监护人同意收集了未成年人个人信息，将尽快删除相关信息或停止处理。"
                    ]
                ),
                LegalSection(
                    title: "七、政策更新",
                    paragraphs: [
                        "当法律法规、服务功能或数据处理方式发生变化时，我们可能更新本政策，并通过应用内或官网页面进行提示。",
                        "你继续使用本服务，即视为你已知悉并同意更新后的内容。"
                    ]
                )
            ]
        }
    }
}

struct LegalSection: Identifiable {
    let id = UUID()
    let title: String
    let paragraphs: [String]
}

struct LegalDocumentView: View {
    let document: LegalDocument
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(document.title)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    
                    ForEach(document.sections) { section in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(section.title)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            ForEach(section.paragraphs, id: \.self) { paragraph in
                                Text(paragraph)
                                    .font(.system(size: 15, weight: .regular, design: .default))
                                    .foregroundColor(.secondary)
                                    .lineSpacing(4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color(.secondarySystemBackground))
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("官网公示链接")
                            .font(.system(size: 16, weight: .semibold))
                        if let privacyURL = AppReleaseInfo.privacyPolicyURL {
                            Link("隐私政策 URL：\(privacyURL.absoluteString)", destination: privacyURL)
                                .font(.system(size: 14))
                        }
                        if let termsURL = AppReleaseInfo.termsOfServiceURL {
                            Link("用户协议 URL：\(termsURL.absoluteString)", destination: termsURL)
                                .font(.system(size: 14))
                        }
                        if let supportURL = AppReleaseInfo.supportURL {
                            Link("支持页：\(supportURL.absoluteString)", destination: supportURL)
                                .font(.system(size: 14))
                        }
                        if let websiteURL = AppReleaseInfo.websiteURL {
                            Link("官网：\(websiteURL.absoluteString)", destination: websiteURL)
                                .font(.system(size: 14))
                        }
                    }
                    .foregroundColor(.blue)
                }
                .padding(20)
            }
            .background(Color(.systemBackground))
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct LegalCenterSheet: View {
    let onShowTerms: () -> Void
    let onShowPrivacy: () -> Void
    let onLogout: () -> Void

    @State private var userProfile: UserInfo?
    @State private var showingAccountSettings = false

    var body: some View {
        NavigationStack {
            List {
                // 用户信息卡片
                Section("账号设置") {
                    Button("账号与安全") {
                        showingAccountSettings = true
                    }
                }

                Section("账户信息") {
                    if let profile = userProfile {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange.opacity(0.8), Color.green.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                )
                            VStack(alignment: .leading, spacing: 2) {
                                Text("手机号：\(profile.phone)")
                                    .font(.system(size: 15, weight: .medium))
                                Text("ID：\(profile.userId)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        HStack {
                            Text("加载中...")
                                .foregroundColor(.secondary)
                            Spacer()
                            ProgressView()
                        }
                    }
                }

                Section("协议与政策") {
                    Button("查看《用户协议》", action: onShowTerms)
                    Button("查看《隐私政策》", action: onShowPrivacy)
                }

                Section("支持信息") {
                    Text("客服邮箱：\(AppReleaseInfo.supportEmail)")
                    Text("隐私邮箱：\(AppReleaseInfo.privacyEmail)")
                }

                Section {
                    Button("退出登录", role: .destructive, action: onLogout)
                }
            }
            .navigationTitle("账户与设置")
        }
        .task {
            await loadUserProfile()
        }
        .sheet(isPresented: $showingAccountSettings) {
            AccountSettingsView()
        }
    }

    private func loadUserProfile() async {
        do {
            let profile = try await NetworkService.shared.getUserProfile()
            await MainActor.run {
                self.userProfile = profile
            }
        } catch {
            // 加载失败不影响页面使用
            print("⚠️ 获取用户信息失败: \(error)")
        }
    }
}
