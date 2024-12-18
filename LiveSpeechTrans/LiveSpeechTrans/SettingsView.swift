//
//  SettingsView.swift
//  LiveSpeechTrans
//
//  Created by LIJIANFEI on 18/12/24.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("selectedLanguage") private var selectedLanguageIdentifier = "zh-CN" // Default to Chinese
    @AppStorage("selectedTranslationLanguage") private var selectedTranslationLanguageIdentifier = "English" // Default to English
    @AppStorage("aiBaseUrl") private var aiBaseUrl = "http://192.168.0.111:1234" // 默认基本 URL
    @AppStorage("APIKey") private var APIKey = ""
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
            Section(header: Text("翻译 AI 设置（OpenAI接口风格）")) {
                HStack {
                    TextField("URL", text: $aiBaseUrl)
                }
                TextField("APIKey(本地模型可为空)", text: $APIKey)
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    SettingsView()
}
