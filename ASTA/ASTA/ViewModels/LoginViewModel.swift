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
    
    private let sessionDuration: TimeInterval = 7 * 24 * 60 * 60
    
    init() {
        self.isLoggedIn = isSessionValid()
    }
    
    private func isSessionValid() -> Bool {
        guard
            let loginDate = UserDefaults.standard.object(forKey: "loginDate") as? Date,
            UserDefaults.standard.string(forKey: "authToken") != nil
        else {
            return false
        }
        
        let timeInterval = Date().timeIntervalSince(loginDate)
        return timeInterval < sessionDuration
    }
    
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
            UserDefaults.standard.set(Date(), forKey: "loginDate")
            self.isLoggedIn = true
            self.errorMessage = nil
            self.isLoading = false
        } catch {
            self.errorMessage = "Invalid credentials"
            self.isLoggedIn = false
            self.isLoading = false
        }
    }
    
    func logout() {
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "loginDate")
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "orgId")
        UserDefaults.standard.removeObject(forKey: "wardId")
        self.isLoggedIn = false
    }
}

struct LoginResponse: Codable {
    let message: String
    let token: String
}

