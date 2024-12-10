//
//  ContentView.swift
//  LiveSpeechTrans
//
//  Created by LIJIANFEI on 9/12/24.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            RecordingView()
                .tabItem {
                    Label("Record", systemImage: "mic")
                }
                .tag(0)
            
            TranslationView()
                .tabItem {
                    Label("Translate", systemImage: "globe")
                }
                .tag(1)
        }
    }
}

struct RecordingView: View {
    @StateObject private var recordingManager = RecordingManager()
    
    var body: some View {
        VStack {
            Text(recordingManager.isRecording ? "Recording..." : "Tap to Record")
                .font(.title)
            
            Button(action: {
                if recordingManager.isRecording {
                    recordingManager.stopRecording()
                } else {
                    recordingManager.startRecording()
                }
            }) {
                Image(systemName: recordingManager.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(recordingManager.isRecording ? .red : .blue)
            }
            
            Text(recordingManager.recordedText)
                .padding()
            
            if let errorMessage = recordingManager.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }
}

struct TranslationView: View {
    @StateObject private var openAIManager = OpenAIManager(apiKey: "YOUR_API_KEY_HERE")
    @State private var sourceText = ""
    @State private var sourceLanguage = "English"
    @State private var targetLanguage = "Chinese"
    
    var body: some View {
        VStack {
            TextField("Enter text to translate", text: $sourceText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            HStack {
                Picker("From", selection: $sourceLanguage) {
                    Text("English").tag("English")
                    Text("Chinese").tag("Chinese")
                }
                
                Picker("To", selection: $targetLanguage) {
                    Text("English").tag("English")
                    Text("Chinese").tag("Chinese")
                }
            }
            .padding()
            
            Button(action: {
                openAIManager.translate(text: sourceText, from: sourceLanguage, to: targetLanguage)
            }) {
                Text("Translate")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(openAIManager.isLoading)
            
            if openAIManager.isLoading {
                ProgressView()
            } else if let errorMessage = openAIManager.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            } else {
                Text(openAIManager.translation)
                    .padding()
            }
        }
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
