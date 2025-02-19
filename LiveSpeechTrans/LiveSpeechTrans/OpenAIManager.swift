import Foundation
import os.log
import SwiftUI

class OpenAIManager: ObservableObject {
    @AppStorage("APIKey") private var APIKey = ""
//    private let baseURL = "http://192.168.0.111:1234/v1/chat/completions"
    @AppStorage("aiBaseUrl") private var aiBaseUrl = "http://192.168.0.111:1234" // 默认基本 URL

    @Published var translation: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let logger = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "OpenAIManager")
    
    func translate(text: String, from: String, to: String) {
        guard !text.isEmpty else {
            self.translation = ""
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let prompt = "Translate the following text from \(from) to \(to): \(text)"
        let body: [String: Any] = [
            "model": "phi-4",
            "messages": [
                ["role": "system", "content": "You are a helpful assistant that translates text.Translate directly, don't add any of your own words."],
                ["role": "user", "content": prompt]
            ]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            errorMessage = "Failed to create request body"
            isLoading = false
            os_log("Failed to create request body", log: logger, type: .error)
            return
        }
        
        guard let url = URL(string: aiBaseUrl+"/v1/chat/completions") else {
            DispatchQueue.main.async {
                self.errorMessage = "Invalid URL"
                self.isLoading = false
            }
            os_log("Invalid URL: %{public}@", log: logger, type: .error, aiBaseUrl+"/v1/chat/completions")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(APIKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        
        os_log("Sending request to %{public}@", log: logger, type: .debug, aiBaseUrl+"/v1/chat/completions")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    os_log("Network error: %{public}@", log: self?.logger ?? .default, type: .error, error.localizedDescription)
                    print("Translation network error: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    os_log("HTTP Status Code: %{public}d", log: self?.logger ?? .default, type: .debug, httpResponse.statusCode)
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    os_log("No data received", log: self?.logger ?? .default, type: .error)
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        self?.translation = content.trimmingCharacters(in: .whitespacesAndNewlines)
                        os_log("Translation successful", log: self?.logger ?? .default, type: .debug)
                        print("Translation successful: \(content)")
                    } else {
                        self?.errorMessage = "Failed to parse response"
                        os_log("Failed to parse response", log: self?.logger ?? .default, type: .error)
                        print("Failed to parse translation response")
                    }
                } catch {
                    self?.errorMessage = "Decoding error: \(error.localizedDescription)"
                    os_log("Decoding error: %{public}@", log: self?.logger ?? .default, type: .error, error.localizedDescription)
                    print("Translation decoding error: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
}
