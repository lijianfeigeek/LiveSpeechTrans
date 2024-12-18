import SwiftUI
import AVFoundation

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let translation: String
    let isUser: Bool
    let timestamp: Date
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.id == rhs.id
    }
}

struct ChatView: View {
    @ObservedObject var recordingManager: RecordingManager
    @ObservedObject var openAIManager: OpenAIManager
    @State private var messages: [ChatMessage] = []
    @State private var scrollToBottom = false
    // Make synthesizer static to prevent deallocation
    private static let speechSynthesizer = AVSpeechSynthesizer()
    
    @AppStorage("selectedLanguage") private var selectedLanguageIdentifier = "zh-CN" // Default to Chinese
    @AppStorage("selectedTranslationLanguage") private var selectedTranslationLanguageIdentifier = "English" // Default to Englis
    @AppStorage("selectedTTSVoice") private var selectedTTSVoiceIdentifier = "com.apple.voice.enhanced.en-US.Evan" // Default to empty string

    private func getPreferredVoice() -> AVSpeechSynthesisVoice? {
        if let fredVoice = AVSpeechSynthesisVoice(identifier: selectedTTSVoiceIdentifier) {
            return fredVoice
        }
        
        return AVSpeechSynthesisVoice(language: "en-US")
    }

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
        .onAppear {
//            checkVoiceAvailability()
        }
        .onReceive(recordingManager.$finalText) { newText in
            print("Received final text: \(newText)")
            if !newText.isEmpty {
                let newMessage = ChatMessage(
                    text: newText,
                    translation: "",
                    isUser: true,
                    timestamp: Date()
                )
                messages.append(newMessage)
                openAIManager.translate(text: newText, from: selectedLanguageIdentifier, to: selectedTranslationLanguageIdentifier)
            }
        }
        .onReceive(openAIManager.$translation) { translation in
            print("Received translation: \(translation)")
            if let lastMessage = messages.last, lastMessage.isUser {
                let updatedMessage = ChatMessage(
                    text: lastMessage.text,
                    translation: translation,
                    isUser: true,
                    timestamp: lastMessage.timestamp
                )
                messages[messages.count - 1] = updatedMessage
                
                let utterance = AVSpeechUtterance(string: translation)
                if let preferredVoice = getPreferredVoice() {
                    utterance.voice = preferredVoice
                    utterance.rate = 0.5  // 降低语速
                    utterance.volume = 1.0 // 确保音量最大
                    
                    print("Starting speech synthesis...")
                    Self.speechSynthesizer.speak(utterance)
                    print("Speech synthesis initiated")
                }
            }
        }
        .onDisappear {
            messages.removeAll()
            recordingManager.finalText = ""
            recordingManager.stopRecording()
        }
    }
}

#if DEBUG
extension ChatView {
    private func listAvailableVoices() {
//        let voices = AVSpeechSynthesisVoice.speechVoices()
//        print("Available voices:")
//        for voice in voices {
//            print("- \(voice.identifier): \(voice.language)")
//        }
    }

    func checkVoiceAvailability() {
        // Check for premium voice
//        if let premiumVoice = AVSpeechSynthesisVoice(identifier: "com.apple.voice.premium.en-US.Zoe") {
//            print("Premium voice is available: \(premiumVoice.identifier)")
//            print("Quality: \(premiumVoice.quality.rawValue)")
//        } else {
//            print("Premium voice is not available")
//        }
        
        // List all available voices
        let voices = AVSpeechSynthesisVoice.speechVoices()
        print("\nAll available voices:")
        for voice in voices {
            print("ID: \(voice.identifier)")
            print("Language: \(voice.language)")
            print("Quality: \(voice.quality.rawValue)")
            print("---")
        }
    }
}
#endif

struct MessageBubble: View {
    let message: ChatMessage
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(dateFormatter.string(from: message.timestamp))
                .font(.caption2)
                .foregroundColor(.gray)
                .padding(.horizontal, 8)
            
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

#Preview {
    var recordingManager = RecordingManager()
    var openAIManager = OpenAIManager()
    ChatView(recordingManager: recordingManager, openAIManager: openAIManager)
}
