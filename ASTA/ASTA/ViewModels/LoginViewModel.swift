//  LoginViewModel.swift
//  ASTA
//  Created by Shaswat Shrey on 11/02/26.

import Foundation
import Combine

@MainActor
class LoginViewModel: ObservableObject {
    
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoggedIn: Bool = false
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    
    func login() async {
        guard let url = URL(string: "https://ios-backend.astahealthtech.net/login") else { return }
        
        isLoading = true
        errorMessage = nil
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = [
            "email": email,
            "password": password
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                self.errorMessage = "Server error: \(httpResponse.statusCode)"
                self.isLoggedIn = false
                self.isLoading = false
                return
            }

            let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)

            UserDefaults.standard.set(loginResponse.token, forKey: "authToken")
            self.isLoggedIn = true
            self.errorMessage = nil
            self.isLoading = false
        } catch {
            self.errorMessage = "Invalid credentials"
            self.isLoggedIn = false
            self.isLoading = false
        }
    }
}

struct LoginResponse: Codable {
    let message: String
    let token: String
}

