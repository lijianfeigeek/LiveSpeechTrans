//
//  ContentView.swift
//  LiveSpeechTrans
//
//  Created by LIJIANFEI on 9/12/24.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var recordingManager = RecordingManager()
    @StateObject private var openAIManager = OpenAIManager(apiKey: "YOUR_API_KEY_HERE")
    var body: some View {
        ChatView(recordingManager: recordingManager, openAIManager: openAIManager)
    }
}

struct SettingsView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}

// End of file. No additional code.
