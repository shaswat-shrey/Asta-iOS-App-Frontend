//  AnalyticsViewModel.swift
//  ASTA
//  Created by Shaswat Shrey on 22/02/26.

import Foundation
import Combine

struct PatientVitalsResponse: Decodable {
    let range: String
    let count: Int
    let data: [VitalRaw]
}

struct VitalRaw: Decodable {
    let heartRate: Double?
    let SpO2: Double?
    let NBPSystolic: Double?
    let NBPDiastolic: Double?
    let NBPMap: Double?
    let respirationRate: Double?
    let pulse: Double?
    let PVC: Double?
    let updated_at: String
    let timestamp: String
}

struct VitalPoint: Identifiable {
    let id = UUID()
    let time: Date
    let value: Double
}

import Foundation

@MainActor
class AnalyticsViewModel: ObservableObject {
    
    // MARK: - Published Data
    
    @Published var heartRateData: [VitalPoint] = []
    @Published var spo2Data: [VitalPoint] = []
    @Published var systolicData: [VitalPoint] = []
    @Published var diastolicData: [VitalPoint] = []
    @Published var respirationData: [VitalPoint] = []
    @Published var pulseData: [VitalPoint] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Fetch
    
    func fetchVitals(patientId: String, range: String) async {
        
        guard let url = URL(string: "https://ios-backend.astahealthtech.net/patient-details/\(patientId)?range=\(range)") else {
            errorMessage = "Invalid URL"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
//            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//            
        // 🔥 If using JWT:
            if let token = UserDefaults.standard.string(forKey: "authToken") {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } else {
                errorMessage = "User not authenticated"
                return
            }
            
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let decoded = try JSONDecoder().decode(PatientVitalsResponse.self, from: data)
            
            // Testing 
            let raw = String(data: data, encoding: .utf8)
            print("RAW FROM APP:")
            print(raw ?? "No Data")
            
            processVitals(decoded.data)
            
        } catch {
            errorMessage = error.localizedDescription
            print("Fetch error:", error)
        }
        
        isLoading = false
    }
}

extension AnalyticsViewModel {
    
    private func processVitals(_ vitals: [VitalRaw]) {
        
        heartRateData = []
        spo2Data = []
        systolicData = []
        diastolicData = []
        respirationData = []
        pulseData = []
        
        for item in vitals {
            
            guard let ts = Double(item.timestamp) else { continue }
            let date = Date(timeIntervalSince1970: ts / 1000)
            
            if let value = item.heartRate {
                heartRateData.append(
                    VitalPoint(time: date, value: value)
                )
            }
            
            if let value = item.SpO2 {
                spo2Data.append(
                    VitalPoint(time: date, value: value)
                )
            }
            
            if let value = item.NBPSystolic {
                systolicData.append(
                    VitalPoint(time: date, value: value)
                )
            }
            
            if let value = item.NBPDiastolic {
                diastolicData.append(
                    VitalPoint(time: date, value: value)
                )
            }
            
            if let value = item.respirationRate {
                respirationData.append(
                    VitalPoint(time: date, value: value)
                )
            }
            
            if let value = item.pulse {
                pulseData.append(
                    VitalPoint(time: date, value: value)
                )
            }
        }
    }
}
