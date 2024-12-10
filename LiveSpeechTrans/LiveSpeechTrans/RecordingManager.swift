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
    
    // 音量监测相关
    private var silenceTimer: Timer?
    private let silenceThreshold: Float = 0.05  // 音量阈值
    private let silenceDuration: TimeInterval = 1.5  // 停顿持续时间（秒）
    private var lastAudioLevel: Float = 0
    
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
        // 设置为中文识别
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
        if speechRecognizer == nil {
            errorMessage = "Speech recognition not available for Chinese."
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
        
        startNewRecognition()
    }
    
    private func startNewRecognition() {
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
            
            // 安装音频监测
            let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentPath.appendingPathComponent("audio.caf")
            
            // 安装音频 tap 用于音量监测
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer, time) in
                guard let self = self else { return }
                self.recognitionRequest?.append(buffer)
                
                // 计算音量
                let channelData = buffer.floatChannelData?[0]
                let frames = buffer.frameLength
                
                var sum: Float = 0
                for i in 0..<Int(frames) {
                    sum += abs(channelData?[i] ?? 0)
                }
                
                let average = sum / Float(frames)
                self.lastAudioLevel = average
                
                // 检查音量是否低于阈值
                DispatchQueue.main.async {
                    if average < self.silenceThreshold {
                        self.handleSilence()
                    } else {
                        self.silenceTimer?.invalidate()
                        self.silenceTimer = nil
                    }
                }
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            print("Recording started")
            
            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                if let result = result {
                    DispatchQueue.main.async {
                        self.recordedText = result.bestTranscription.formattedString
                        print("Recognition result: \(self.recordedText)")
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
    
    private func handleSilence() {
        if silenceTimer == nil {
            silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceDuration, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                
                // 停顿时间达到阈值，结束当前识别
                if !self.recordedText.isEmpty {
                    self.finalText = self.recordedText
                    print("Final result (silence detected): \(self.finalText)")
                    self.recordedText = ""
                }
                
                // 重新开始新的识别
                self.restartRecognition()
            }
        }
    }
    
    private func restartRecognition() {
        // 停止当前识别
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        // 开始新的识别
        startNewRecognition()
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
