//  WardServiceModel.swift
//  ASTA
//  Created by Shaswat Shrey on 14/02/26.

import Foundation
class SessionManager {
    static let shared = SessionManager()

    var orgId: String? {
        UserDefaults.standard.string(forKey: "orgId")
    }

    var userId: String? {
        UserDefaults.standard.string(forKey: "userId")
    }
    
    var wardId: String? {
        UserDefaults.standard.string(forKey: "wardId")
    }
}

class AuthManager {
    static let shared = AuthManager()
    
    var token: String? {
        UserDefaults.standard.string(forKey: "authToken")
    }
}




class WardService {
    
    static let shared = WardService()
    
    private let baseURL = "https://ios-backend.astahealthtech.net"
    
    // 🔐 Common request builder
    private func authorizedRequest(url: URL, method: String) throws -> URLRequest {
        
        guard let token = AuthManager.shared.token else {
            throw URLError(.userAuthenticationRequired)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    // 🔴 DISCHARGE
    func discharge(bedNumber: Int) async throws {
        
        guard let url = URL(string: "\(baseURL)/discharge") else { return }
        
        var request = try authorizedRequest(url: url, method: "POST")
        
        let body: [String: Any] = [
            "bedNumber": bedNumber
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode == 401 {
            throw URLError(.userAuthenticationRequired)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
    
    
    // 🟢 ADD PATIENT
    func addPatient(bedNumber: Int, issueText: String) async throws {
        
        let orgId = SessionManager.shared.orgId
        let wardId = SessionManager.shared.wardId
        
        guard let url = URL(string: "\(baseURL)/add-patient") else { return }
        
        var request = try authorizedRequest(url: url, method: "POST")
        
        let body: [String: Any] = [
            "bedNumber": bedNumber,
            "issueText": issueText,
            "hospitalId": orgId ?? "NIL",
            "ward": wardId ?? "NIL"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode == 401 {
            throw URLError(.userAuthenticationRequired)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
