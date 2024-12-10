//
//  ContentView.swift
//  LiveSpeechTrans
//
//  Created by LIJIANFEI on 9/12/24.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    var body: some View {
        RecordingView()
    }
}

struct RecordingView: View {
    @StateObject private var recordingManager = RecordingManager()
    @StateObject private var openAIManager = OpenAIManager(apiKey: "YOUR_API_KEY_HERE")
    
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
            
            Text("Recognized Text:")
                .font(.headline)
                .padding(.top)
            Text(recordingManager.recordedText)
                .padding()
            
            Text("Translated Text:")
                .font(.headline)
                .padding(.top)
            Text(openAIManager.translation)
                .padding()
            
            if let errorMessage = recordingManager.errorMessage ?? openAIManager.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .onChange(of: recordingManager.recordedText) { newValue in
            openAIManager.translate(text: newValue, from: "English", to: "Chinese")
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
