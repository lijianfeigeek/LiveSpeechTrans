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

    private func speakTranslation(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        if let preferredVoice = getPreferredVoice() {
            utterance.voice = preferredVoice
            utterance.rate = 0.5
            utterance.volume = 1.0
            
            print("Starting speech synthesis...")
            Self.speechSynthesizer.speak(utterance)
            print("Speech synthesis initiated")
        }
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
                speakTranslation(translation)
            }
        }
        .onDisappear {
            messages.removeAll()
            recordingManager.finalText = ""
            recordingManager.stopRecording()
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    private static let speechSynthesizer = AVSpeechSynthesizer()
    @AppStorage("selectedTTSVoice") private var selectedTTSVoiceIdentifier = "com.apple.voice.enhanced.en-US.Evan"
    @State private var isPlaying = false
    
    // Store delegate as a property
    private let speechDelegate: SpeechDelegate
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    private class SpeechDelegate: NSObject, AVSpeechSynthesizerDelegate {
        private var isPlayingBinding: Binding<Bool>
        
        init(isPlaying: Binding<Bool>) {
            self.isPlayingBinding = isPlaying
            super.init()
        }
        
        func updateBinding(_ newBinding: Binding<Bool>) {
            self.isPlayingBinding = newBinding
        }
        
        func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
            DispatchQueue.main.async {
                self.isPlayingBinding.wrappedValue = true
            }
        }
        
        func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
            DispatchQueue.main.async {
                self.isPlayingBinding.wrappedValue = false
            }
        }
        
        func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
            DispatchQueue.main.async {
                self.isPlayingBinding.wrappedValue = false
            }
        }
        
        func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
            DispatchQueue.main.async {
                self.isPlayingBinding.wrappedValue = false
            }
        }
    }
    
    init(message: ChatMessage) {
        self.message = message
        // Initialize delegate with a temporary binding
        let isPlayingBinding = Binding<Bool>(
            get: { false },
            set: { _ in }
        )
        self.speechDelegate = SpeechDelegate(isPlaying: isPlayingBinding)
        // Set the delegate
        MessageBubble.speechSynthesizer.delegate = self.speechDelegate
    }
    
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
                HStack {
                    Text(message.translation)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: isPlaying ? "pause.fill" : "arrow.clockwise")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 10, height: 10)
                                .foregroundColor(.white)
                        )
                        .onTapGesture {
                            if isPlaying {
                                Self.speechSynthesizer.pauseSpeaking(at: .immediate)
                                isPlaying = false
                            } else {
                                if Self.speechSynthesizer.isPaused {
                                    Self.speechSynthesizer.continueSpeaking()
                                    isPlaying = true
                                } else {
                                    let utterance = AVSpeechUtterance(string: message.translation)
                                    if let voice = AVSpeechSynthesisVoice(identifier: selectedTTSVoiceIdentifier) {
                                        utterance.voice = voice
                                        utterance.rate = 0.5
                                        utterance.volume = 1.0
                                        Self.speechSynthesizer.speak(utterance)
                                        isPlaying = true
                                    }
                                }
                            }
                        }
                }
                .padding(.horizontal, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            // Update delegate's binding when view appears
            speechDelegate.updateBinding($isPlaying)
        }
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
