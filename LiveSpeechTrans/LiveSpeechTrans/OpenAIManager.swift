import Foundation
import os.log

class OpenAIManager: ObservableObject {
    private let apiKey: String
    private let baseURL = "http://localhost:1234/v1/chat/completions"
    
    @Published var translation: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let logger = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "OpenAIManager")
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func translate(text: String, from: String, to: String) {
        isLoading = true
        errorMessage = nil
        
        let prompt = "Translate the following text from \(from) to \(to): \(text)"
        let body: [String: Any] = [
            "model": "gemma-2-27b-it",
            "messages": [
                ["role": "system", "content": "You are a helpful assistant that translates text."],
                ["role": "user", "content": prompt]
            ]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            errorMessage = "Failed to create request body"
            isLoading = false
            os_log("Failed to create request body", log: logger, type: .error)
            return
        }
        
        guard let url = URL(string: baseURL) else {
            DispatchQueue.main.async {
                self.errorMessage = "Invalid URL"
                self.isLoading = false
            }
            os_log("Invalid URL: %{public}@", log: logger, type: .error, baseURL)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        
        os_log("Sending request to %{public}@", log: logger, type: .debug, baseURL)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    os_log("Network error: %{public}@", log: self?.logger ?? .default, type: .error, error.localizedDescription)
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
                    } else {
                        self?.errorMessage = "Failed to parse response"
                        os_log("Failed to parse response", log: self?.logger ?? .default, type: .error)
                    }
                } catch {
                    self?.errorMessage = "Decoding error: \(error.localizedDescription)"
                    os_log("Decoding error: %{public}@", log: self?.logger ?? .default, type: .error, error.localizedDescription)
                }
            }
        }.resume()
    }
}
