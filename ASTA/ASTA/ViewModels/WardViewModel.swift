//  WardViewModel.swift
//  ASTA
//  Created by Shaswat Shrey on 12/02/26.

import Foundation
import Combine

@MainActor
class WardViewModel: ObservableObject {
    
    @Published var wards: [Ward] = []
    @Published var errorMessage: String?
    
    // Persist and access the selected ward id in UserDefaults
    func setSelectedWard(_ ward: Ward) {
        UserDefaults.standard.set(ward.ward_id, forKey: "wardId")
    }
    
    var selectedWardId: String? {
        UserDefaults.standard.string(forKey: "wardId")
    }
    
    func fetchWards() async {
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            errorMessage = "User not authenticated"
            return
        }
        
        guard let url = URL(string: "https://ios-backend.astahealthtech.net/wards") else {
            errorMessage = "Invalid URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Invalid response"
                return
            }
            
            if httpResponse.statusCode == 401 {
                errorMessage = "Session expired. Please login again."
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                errorMessage = "Failed to fetch wards"
                return
            }
            
            wards = try JSONDecoder().decode([Ward].self, from: data)
            
        } catch {
            errorMessage = "Network error"
        }
    }
}

struct Ward: Identifiable, Codable, Hashable {
    let ward_id: String
    let name: String
    let type: String?
    let capacity: Int
    let floor: Int?
    let occupied_beds: Int
    
    var id: String { ward_id }
    
    static func == (lhs: Ward, rhs: Ward) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

