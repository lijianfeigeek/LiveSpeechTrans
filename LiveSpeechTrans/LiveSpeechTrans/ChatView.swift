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
    @State private var scrollProxy: ScrollViewProxy? = nil

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages) { _ in
                    withAnimation {
                        proxy.scrollTo(messages.last?.id, anchor: .bottom)
                    }
                }
                .onAppear {
                    scrollProxy = proxy
                }
            }

            RecordingButton(recordingManager: recordingManager)
        }
        .background(Color.primary.opacity(0.1))

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
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
            Text(message.text)
                .padding(10)
                .background(message.isUser ? Color.blue : Color.secondary.opacity(0.2))
                .foregroundColor(message.isUser ? .white : .primary)
                .cornerRadius(16)
            
            if !message.translation.isEmpty {
                Text(message.translation)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
    }
}

struct RecordingButton: View {
    @ObservedObject var recordingManager: RecordingManager
    
    var body: some View {
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
                .frame(width: 60, height: 60)
                .foregroundColor(recordingManager.isRecording ? .red : .blue)
                .background(Color.primary.opacity(0.1))
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .padding()
    }
}
