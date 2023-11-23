//
//  ChatView.swift
//  PiedPiper
//
//  Created by Sulaiman Ghori on 11/22/23.
//

import SwiftUI

struct ChatView: View {
    @State private var messageText = ""
    @State private var messages: [String] = []

    struct ResponseData: Codable {
        let model: String
        let createdAt: String
        let response: String
        let done: Bool

        enum CodingKeys: String, CodingKey {
            case model
            case createdAt = "created_at"
            case response
            case done
        }
    }

    func sendMessage() {
        // Add the user input to the list and clear the text field
        messages.append(messageText)
        let userInput = messageText
        messageText = ""

        // Networking call to your HTTP endpoint
        guard let url = URL(string: "http://127.0.0.1:11434/api/generate") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": "mistral-openorca",
            "prompt": userInput
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                // Handle error...
                print("Network request failed: \(error)")
                return
            }

            // Handle the streaming data
            if let data = data {
                self.handleStream(data: data)
            }
        }

        // Set the task to handle a stream
        task.resume()
    }
    
    func handleStream(data: Data) {
        // Convert data to string
        guard let streamString = String(data: data, encoding: .utf8) else { return }

        // Split the string by newlines or other delimiters as per your stream's format
        let responses = streamString.split(separator: "\n") // Assuming each JSON is separated by a newline

        for response in responses {
            do {
                let responseData = try JSONDecoder().decode(ResponseData.self, from: Data(response.utf8))
                DispatchQueue.main.async {
                    // Update your UI with each response
                    self.messages.append(responseData.response)
                }
            } catch {
                // Handle parsing error for individual responses
            }
        }
    }
    
    var body: some View {
        VStack {
            // Message List
            ScrollView {
                ForEach(messages, id: \.self) { message in
                    Text(message)
                        .padding()
                }
            }

            // Text Input Area
            HStack {
                TextField("Enter message", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("Send") {
                    sendMessage()
                }
                .padding()
            }
        }
    }

}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}
