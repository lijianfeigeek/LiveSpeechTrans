import Foundation
import AVFoundation
import Combine
import Speech

class RecordingManager: ObservableObject {
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?
    
    @Published var isRecording = false
    @Published var recordedText = ""
    @Published var finalText = ""
    @Published var errorMessage: String?
    
    private var lastProcessedText = ""
    private var silenceTimer: Timer?
    private let silenceThreshold = 1.0
    
    init() {
        setupAudioSession()
        requestSpeechAuthorization()
        updateSpeechRecognizer()
    }
    
    private func setupAudioSession() {
        // 设置音频会话
    }
    
    private func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self.errorMessage = nil
                case .denied:
                    self.errorMessage = "Speech recognition permission denied."
                case .restricted:
                    self.errorMessage = "Speech recognition is restricted."
                case .notDetermined:
                    self.errorMessage = "Speech recognition not yet authorized."
                @unknown default:
                    self.errorMessage = "Unknown authorization status."
                }
            }
        }
    }
    
    private func updateSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        if speechRecognizer == nil {
            errorMessage = "Speech recognition not available for the current language."
        } else {
            errorMessage = nil
        }
    }
    
    func startRecording() {
        guard !isRecording else { return }
        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            errorMessage = "Speech recognition not authorized."
            return
        }
        
        recordedText = ""
        finalText = ""
        lastProcessedText = ""
        
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "Unable to create recognition request."
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
            
            print("Recording started")
            
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                if let result = result {
                    let transcription = result.bestTranscription.formattedString
                    
                    DispatchQueue.main.async {
                        self.recordedText = transcription
                        print("Partial result: \(transcription)")
                        
                        self.silenceTimer?.invalidate()
                        
                        if transcription != self.lastProcessedText {
                            self.silenceTimer = Timer.scheduledTimer(withTimeInterval: self.silenceThreshold, repeats: false) { _ in
                                if !transcription.isEmpty && transcription != self.lastProcessedText {
                                    self.finalText = transcription
                                    print("Final result: \(transcription)")
                                    self.lastProcessedText = transcription
                                    self.recordedText = ""
                                }
                            }
                        }
                    }
                }
                
                if let error = error {
                    self.errorMessage = "Recognition error: \(error.localizedDescription)"
                    print("Recognition error: \(error.localizedDescription)")
                }
            }
            
            isRecording = true
            
        } catch {
            errorMessage = "Failed to start audio engine: \(error.localizedDescription)"
            print("Audio engine start error: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        isRecording = false
        recognitionRequest = nil
        recognitionTask = nil
        
        print("Recording stopped")
    }
}
