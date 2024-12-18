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
    @StateObject private var openAIManager = OpenAIManager()
    @State private var sidebarWidth: CGFloat = 200

    var body: some View {
        NavigationSplitView {
            SidebarView(recordingManager: recordingManager, openAIManager: openAIManager, width: $sidebarWidth)
                .frame(width: sidebarWidth)
        }detail: {
            
        }
    }
}

struct SidebarView: View {
    @ObservedObject var recordingManager: RecordingManager
    @ObservedObject var openAIManager: OpenAIManager
    @Binding var width: CGFloat

    var body: some View {
        List {
            NavigationLink(destination: ChatView(recordingManager: recordingManager, openAIManager: openAIManager), isActive: .constant(true)) {
                HStack {
                    Image(systemName: "mic.fill")
                        .foregroundColor(.blue)

                    Text("实时翻译")
                }
            }
            NavigationLink(destination: SettingsView()) {
                HStack {
                    Image(systemName: "gear")
                        .foregroundColor(.gray)

                    Text("设置")
                }
            }
        }
    }
}


#Preview {
    ContentView()
}

// End of file. No additional code.





