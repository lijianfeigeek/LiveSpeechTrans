import Foundation
import AVFoundation
import Combine
import Speech

class RecordingManager: ObservableObject {
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioPlayer: AVAudioPlayer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?
    
    @Published var isRecording = false
    @Published var recordedText = ""
    @Published var recordedSentences: [String] = []
    private var currentSentence = ""
    private let punctuationMarks = [".", "!", "?", "。", "！", "？"]
    
    @Published var errorMessage: String?
    @Published var currentLanguage: String = "en-US" {
        didSet {
            updateSpeechRecognizer()
        }
    }
    
    init() {
        setupAudioSession()
        requestSpeechAuthorization()
        updateSpeechRecognizer()
    }
    
    private func setupAudioSession() {
        // setupAudioSession remains the same
    }
    
    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self.errorMessage = nil
                case .denied:
                    self.errorMessage = "Speech recognition permission denied. Please enable it in Settings."
                case .restricted:
                    self.errorMessage = "Speech recognition is restricted on this device."
                case .notDetermined:
                    self.errorMessage = "Speech recognition not yet authorized."
                @unknown default:
                    self.errorMessage = "Unknown authorization status for speech recognition."
                }
            }
        }
    }
    
    private func updateSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: currentLanguage))
        if speechRecognizer == nil {
            errorMessage = "Speech recognition not available for \(currentLanguage)"
        } else {
            errorMessage = nil
        }
    }
    
    func startRecording() {
        guard !isRecording else { return }
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            errorMessage = "Speech recognition not authorized. Please check app permissions in Settings."
            return
        }
        
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "Unable to create speech recognition request"
            return
        }
        recognitionRequest.shouldReportPartialResults = true
        
        do {
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer, _) in
                self?.recognitionRequest?.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                if let result = result {
                    let newText = result.bestTranscription.formattedString
                    if newText != self.recordedText {
                        self.recordedText = newText
                        self.processSentence(newText)
                        print("New recorded text: \(newText)")
                    }
                }
                if let error = error {
                    self.stopRecording()
                    self.errorMessage = "Recognition task error: \(error.localizedDescription)"
                    print("Recognition error: \(error.localizedDescription)")
                }
            }
            
            isRecording = true
        } catch {
            errorMessage = "Failed to start audio engine: \(error.localizedDescription)"
        }
    }
    
    func stopRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        isRecording = false
        recognitionRequest = nil
        recognitionTask = nil
    }
    
    private func processSentence(_ text: String) {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        for word in words {
            currentSentence += word + " "
            if punctuationMarks.contains(where: { word.hasSuffix($0) }) {
                let newSentence = currentSentence.trimmingCharacters(in: .whitespaces)
                recordedSentences.append(newSentence)
                print("New sentence added: \(newSentence)")
                currentSentence = ""
            }
        }
    }
}
