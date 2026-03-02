//  ICUWardView.swift
//  ASTA
//  Created by Shaswat Shrey on 04/02/26.

import SwiftUI

struct ICUWardView: View {
    
    @State private var selectedPatient: Patient?
    let ward: Ward
    @StateObject private var vm = ICUWardViewModel()

    var body: some View {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.90, blue: 0.92),
                        Color(red: 0.92, green: 0.86, blue: 0.90)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    // TOP PANEL
                    TopPanelView(
                        wardName: ward.name,
                        totalBeds: vm.beds.count
                    )
                    
                    
                    // ATIENT CARDS
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 1) {
                            
                            ForEach(vm.patients) { patient in
                                PatientDetailView(
                                    patient: patient,
                                    vm: vm,
                                ) { selected in
                                    selectedPatient = selected
                                }
                            }

                        }
                        .padding(.vertical, 20)
                    }
                    .frame(maxHeight: .infinity) // FOR SCROLLING
                }
                
            }
            .navigationDestination(item: $selectedPatient) { patient in
                GenerateVideoView(patient: patient)
            }
            .task {
                await vm.fetchWardDetails(wardId: ward.ward_id)
            }
            
        }
    }


struct TopPanelView: View {
        
    let wardName: String
    let totalBeds: Int

    var body: some View {
        VStack(spacing: 16) {
                // Ward Summary
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Ward")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.gray)
                    Text(wardName.uppercased())
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Beds")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.gray)
                    Text("\(totalBeds)")
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.08), radius: 10, y: 6)

        }
        .padding(.horizontal)
        .padding(.bottom, 10)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Ward Monitors")
                    .font(.headline)
                    .foregroundColor(.black)
            }
        }

    }
                
}

//func convertToPatient(from bed: BedDetail) -> Patient {
//
//    return Patient(
//        id: bed.patient_id ?? bed.bed_id,
//        patientName: bed.patient_name,
//        bedNumber: bed.bed_number,
//        heartRate: bed.heartRate,
//        systolic: bed.NBPSystolic,
//        diastolic: bed.NBPDiastolic,
//        spo2: bed.SpO2,
//        pulse: bed.pulse,
//        respirationRate: bed.respirationRate,
//        pvc: bed.PVC, 
//        bedStatus: bed.bed_status,
//        image: bed.image
//    )
//}


