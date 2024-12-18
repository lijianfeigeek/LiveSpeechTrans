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
    
    var body: some View {
        Form {
            Section(header: Text("语言选择")) {
                Picker("语音识别语言", selection: $selectedLanguageIdentifier) {
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
            
            // ... other settings ...
        }
        .formStyle(.grouped)
    }
}

#Preview {
    SettingsView()
}
