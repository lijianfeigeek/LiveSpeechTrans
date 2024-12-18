//
//  SettingsView.swift
//  LiveSpeechTrans
//
//  Created by LIJIANFEI on 18/12/24.
//

import SwiftUI
import Speech

struct SettingsView: View {
    @AppStorage("selectedLanguage") private var selectedLanguageIdentifier = "zh-CN" // Default to Chinese
    @AppStorage("selectedTranslationLanguage") private var selectedTranslationLanguageIdentifier = "English" // Default to English
    @AppStorage("aiBaseUrl") private var aiBaseUrl = "http://192.168.0.111:1234" // 默认基本 URL
    @AppStorage("APIKey") private var APIKey = ""
    @AppStorage("selectedTTSVoice") private var selectedTTSVoiceIdentifier = "com.apple.voice.enhanced.en-US.Evan" // Default to empty string
    
    @State private var isValidUrl = true
    @State private var isCheckingUrl = false // 添加检查状态
    
    private var availableVoices: [AVSpeechSynthesisVoice] = AVSpeechSynthesisVoice.speechVoices() // Store fetched voices
    
    // 更新 URL 验证函数为异步函数
    private func validateUrl(_ urlString: String) async -> Bool {
        guard let url = URL(string: urlString) else { return false }
        
        // 基本格式验证
        guard url.scheme != nil && url.host != nil else { return false }
        
        // 创建网络请求
        var request = URLRequest(url: url)
        request.timeoutInterval = 5 // 5秒超时
        request.httpMethod = "HEAD" // 只请求头部信息
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return false }
            // 检查状态码是否在有效范围内 (200-299)
            return (200...299).contains(httpResponse.statusCode)
        } catch {
            print("URL validation error: \(error.localizedDescription)")
            return false
        }
    }

    var body: some View {
        Form {
            Section(header: Text("语言选择")) {
                Picker("麦克风识别语言", selection: $selectedLanguageIdentifier) {
                    Text("English (US)")
                        .tag("en-US")
                    Text("Chinese (Simplified)")
                        .tag("zh-CN")
                    // Add more languages here as needed
                }
                
                Picker("翻译为语言", selection: $selectedTranslationLanguageIdentifier) {
                    Text("English")
                        .tag("English")
                    Text("Chinese")
                        .tag("Chinese")
                    // Add more languages here as needed
                }
            }
            Section(header: Text("TTS语音")) {
                Picker("选择TTS语音(id-language-quality)", selection: $selectedTTSVoiceIdentifier) {
                    ForEach(availableVoices.filter { voice in
                        voice.language == "en-US" || voice.language == "zh-CN"
                    }, id: \.identifier) { voice in
                        Text("\(voice.identifier) - \(voice.language) (\(voice.quality.rawValue))")
                            .tag(voice.identifier)
                    }

                }
            }
            Section(header: Text("翻译 AI 设置( OpenAI 接口风格)")) {
                HStack {
                    TextField("URL", text: $aiBaseUrl)
                    if isCheckingUrl {
                        ProgressView() // 显示加载指示器
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: isValidUrl ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isValidUrl ? .green : .red)
                    }
                }
                TextField("APIKey(本地模型可为空)", text: $APIKey)
            }
        }
        .onChange(of: aiBaseUrl) { newValue in
            // 使用 Task 处理异步验证
            Task {
                isCheckingUrl = true
                isValidUrl = await validateUrl(newValue)
                isCheckingUrl = false
            }
        }
        .onAppear {
            // 初始验证
            Task {
                isCheckingUrl = true
                isValidUrl = await validateUrl(aiBaseUrl)
                isCheckingUrl = false
            }
        }
        .formStyle(.grouped)
    }

}

#Preview {
    SettingsView()
}
