//  ICUWardViewModel.swift
//  ASTA
//  Created by Shaswat Shrey on 12/02/26.

import Foundation
import Combine

@MainActor
class ICUWardViewModel: ObservableObject {
    
    @Published var beds: [BedDetail] = []
    @Published var patients: [Patient] = []
    @Published var errorMessage: String?
    var currentWardId: String?
    
    func fetchWardDetails(wardId: String) async {
        currentWardId = wardId
        guard let url = URL(string: "https://ios-backend.astahealthtech.net/ward-details/\(wardId)") else {
            errorMessage = "Invalid URL"
            return
        }
        var request = URLRequest(url: url)
            request.httpMethod = "GET"

        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            errorMessage = "User not authenticated"
            return
        }

        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                errorMessage = "Failed to fetch ward data"
                return
            }
            
            let decodedBeds = try JSONDecoder().decode([BedDetail].self, from: data)
            
            // Update published properties
            self.beds = decodedBeds
            self.patients = decodedBeds.map { $0.toPatient() }
            
        } catch {
            print("Decoding/Network error:", error)
            errorMessage = "Network or decoding error"
        }
    }
    
    struct BedDetail: Identifiable, Codable {
        // BED
        let bed_id: String
        let bed_number: Int
        let bed_status: String
        
        // PATIENT
        let patient_id: String?
        let patient_name: String?
        
        // VITALS
        let vital_id: String?
        let heartRate: Int?
        let SpO2: Int?
        let NBPSystolic: Int?
        let NBPDiastolic: Int?
        
        let respirationRate: Int?
        let pulse: Int?
        let PVC: Int?
        let image: String?
        
        var id: String { bed_id }
    }
}

// MARK: - Mapping
extension ICUWardViewModel.BedDetail {
    func toPatient() -> Patient {
        Patient(
            id: patient_id ?? bed_id,
            patientName: patient_name,
            bedNumber: bed_number,
            
            heartRate: heartRate,
            systolic: NBPSystolic,
            diastolic: NBPDiastolic,
            spo2: SpO2,
            pulse: pulse,
            respirationRate: respirationRate,
            pvc: PVC,
            
            bedStatus: bed_status,
            image: image
        )
    }
}
