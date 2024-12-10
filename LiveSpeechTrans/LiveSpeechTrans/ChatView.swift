import SwiftUI

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let translation: String
    let isUser: Bool
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.id == rhs.id
    }
}

struct ChatView: View {
    @ObservedObject var recordingManager: RecordingManager
    @ObservedObject var openAIManager: OpenAIManager
    @State private var messages: [ChatMessage] = []
    @State private var scrollToBottom = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages) { _ in
                    scrollToBottom = true
                }
                .onChange(of: scrollToBottom) { _ in
                    if scrollToBottom {
                        withAnimation {
                            proxy.scrollTo(messages.last?.id, anchor: .bottom)
                        }
                        scrollToBottom = false
                    }
                }
            }

            RecordingButton(recordingManager: recordingManager)
                .padding(.bottom, 20)
        }
        .onReceive(recordingManager.$recordedText) { newText in
            print("Received new text: \(newText)")
            if !newText.isEmpty {
                let newMessage = ChatMessage(text: newText, translation: "", isUser: true)
                messages.append(newMessage)
                openAIManager.translate(text: newText, from: "English", to: "Chinese")
            }
        }
        .onReceive(openAIManager.$translation) { translation in
            print("Received translation: \(translation)")
            if let lastMessage = messages.last, lastMessage.isUser {
                let updatedMessage = ChatMessage(text: lastMessage.text, translation: translation, isUser: true)
                messages[messages.count - 1] = updatedMessage
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(message.text)
                .padding(10)
                .background(Color.blue.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(16)
            
            if !message.translation.isEmpty {
                Text(message.translation)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct RecordingButton: View {
    @ObservedObject var recordingManager: RecordingManager
    @State private var isRecording = false
    
    var body: some View {
        Circle()
            .fill(isRecording ? Color.red : Color.blue)
            .frame(width: 60, height: 60)
            .overlay(
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white)
            )
            .onTapGesture {
                isRecording.toggle()
                if isRecording {
                    recordingManager.startRecording()
                } else {
                    recordingManager.stopRecording()
                }
            }
    }
}
