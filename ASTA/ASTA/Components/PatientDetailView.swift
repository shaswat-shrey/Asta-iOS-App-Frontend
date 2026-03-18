//  PatientDetailView.swift
//  ASTA
//  Created by Shaswat Shrey on 06/02/26.

import SwiftUI

struct Patient: Identifiable, Hashable {

    let id: String
    let patientName: String?
    let bedNumber: Int

    let heartRate: Int?
    let systolic: Int?
    let diastolic: Int?
    let spo2: Int?
    let pulse: Int?
    let respirationRate: Int?
    let pvc: Int?

    let bedStatus: String
    let image: String?
}

struct PatientDetailView: View {
    
    let patient: Patient
    @ObservedObject var vm: ICUWardViewModel 
    let onViewDetails: (Patient) -> Void
    @State private var showFullscreenMonitor = false
    
    @State private var showAddPatientSheet = false
    @State private var issueText: String = ""
    @State private var isLoading = false
    
    @State private var showDischargeAlert = false
    @State private var isDischarging = false
    @State private var goToAnalytics = false
    
    var condition: String {
        
        if patient.bedStatus == "available" {
            return "AVAILABLE"
        }
        
        if let hr = patient.heartRate, hr > 120 { return "CRITICAL" }
        if let spo2 = patient.spo2, spo2 < 90 { return "CRITICAL" }
        if let pvc = patient.pvc, pvc > 10 { return "CRITICAL" }
        
        return "STABLE"
    }
    
    var statusColor: Color {
        switch condition {
        case "CRITICAL": return .red
        case "AVAILABLE": return .gray
        default: return .green
        }
    }
    
    var shortcut: String {
        if let name = patient.patientName {
            return String(name.prefix(2)).uppercased()
        }
        return "--"
    }
    
    var bpString: String {
        if let sys = patient.systolic,
           let dia = patient.diastolic {
            return "\(sys)/\(dia)"
        }
        return "--"
    }
    
    @State private var isPressed: Bool = false
    private let gridColumns: [GridItem] = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    @ViewBuilder
    private var headerView: some View {
        HStack {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Text(shortcut)
                            .font(.system(size: 64 * 0.35, weight: .semibold))
                            .foregroundColor(.black)
                            .fontDesign(Font.Design.rounded)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .shadow(color: .black.opacity(0.1),
                            radius: 4, x: 0, y: 2)
                Circle()
                    .fill(statusColor)
                    .frame(width: 64 * 0.26, height: 64 * 0.26)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .offset(x: 4, y: 4)
            }
            
            VStack(alignment: .leading) {
                Text(patient.patientName ?? "No Patient")
                    .font(.headline)
                    .foregroundColor(.black)
                
                Text("Bed: \(patient.bedNumber)")
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(condition)
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(statusColor.opacity(0.12))
                .foregroundColor(statusColor)
                .clipShape(Capsule())
        }
    }

    @ViewBuilder
    private var monitorSection: some View {
        VStack {
            VStack {
                Spacer()
                if let imageString = patient.image,
                   let url = URL(string: "\(imageString)?t=\(Date().timeIntervalSince1970)") {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .tint(.white)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .padding(5)
                        case .failure:
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title)
                                .foregroundColor(.yellow)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "waveform.path.ecg")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.6))
                    Text("Monitor Display")
                        .foregroundColor(.white.opacity(0.6))
                }
                Spacer()
            }
            .frame(height: 180)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 18/255, green: 28/255, blue: 58/255),
                        Color(red: 10/255, green: 18/255, blue: 40/255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(18)
            
            Text("View Fullscreen")
                .foregroundStyle(
                    LinearGradient(
                        colors: [.orange, .pink, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .font(.subheadline)
                .fontWeight(.medium)
                .onTapGesture {
                    showFullscreenMonitor = true
                }
                .fullScreenCover(isPresented: $showFullscreenMonitor) {
                    MonitorFullscreenView(imageURL: patient.image)
                }
        }
    }

    @ViewBuilder
    private var vitalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("VITAL SIGNS")
                .font(.caption)
                .foregroundColor(.black)
            
            LazyVGrid(columns: gridColumns, spacing: 16) {
                PatientVitalCard(title: "HR",
                                 value: patient.heartRate != nil ? "\(patient.heartRate!)" : "--",
                                 unit: "bpm",
                                 color: statusColor)
                
                PatientVitalCard(title: "BP",
                                 value: bpString,
                                 unit: "mmHg",
                                 color: .black)
                
                PatientVitalCard(title: "SpO₂",
                                 value: patient.spo2 != nil ? "\(patient.spo2!)" : "--",
                                 unit: "%",
                                 color: statusColor)
                
                PatientVitalCard(title: "Pulse",
                                 value: patient.pulse != nil ? "\(patient.pulse!)" : "--",
                                 unit: "bpm",
                                 color: .purple)
                
                PatientVitalCard(title: "RR",
                                 value: patient.respirationRate != nil ? "\(patient.respirationRate!)" : "--",
                                 unit: "bpm",
                                 color: .orange)
                
                PatientVitalCard(title: "PVC",
                                 value: patient.pvc != nil ? "\(patient.pvc!)" : "--",
                                 unit: "count",
                                 color: .orange)
            }
        }
    }

    @ViewBuilder
    private var actionsSection: some View {
        VStack {
            
            HStack(spacing: 16) {
                Button("View Details") {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    isPressed = true
                    onViewDetails(patient)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.orange, .pink, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(14)
                .shadow(color:.red.opacity(0.5), radius: 5)
                .disabled(patient.bedStatus == "available")
                .opacity(patient.bedStatus == "available" ? 0.5 : 1.0)
                
                if patient.bedStatus == "available" {
                    Button("Add Patient") {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showAddPatientSheet = true
                    }
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.green.opacity(0.6))
                    )
                    .shadow(color:.green.opacity(0.4), radius: 5)
                } else {
                    Button("Discharge") {
                        print("Button Tapped")
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showDischargeAlert = true
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.gray.opacity(0.5))
                    )
                    .shadow(color:.black.opacity(0.5), radius: 5)
                    .alert("Discharge Patient", isPresented: $showDischargeAlert) {
                        Button("Cancel", role: .cancel) {}
                        
                        Button("Discharge", role: .destructive) {
                            isDischarging = true
                            Task {
                                do {
                                    try await WardService.shared.discharge(bedNumber: patient.bedNumber)
                                } catch {
                                    print("Discharge failed:", error)
                                }
                                await vm.fetchWardDetails(wardId: vm.currentWardId ?? "NIL")
                                isDischarging = false
                            }
                        }
                    } message: {
                        Text(
                            "Do you want to discharge \(patient.patientName ?? "this patient") from bed \(patient.bedNumber)?"
                        )
                    }
                }
            }
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                goToAnalytics = true
            } label: {
                HStack {
                    Image(systemName: "chart.xyaxis.line")
                    Text("Analytics")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(14)
                .shadow(color: .blue.opacity(0.4), radius: 5)
            }
            .navigationDestination(isPresented: $goToAnalytics) {
                AnalyticsView(patientId: patient.id)
            }
            
        }
    }

    var body: some View {
        ZStack {
            // CARD
            VStack(spacing: 24) {
                headerView
                
                Divider()
                
                monitorSection
                
                vitalsSection
                
                actionsSection
            }
            .padding()
            .background(Color.white)
            .cornerRadius(28)
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(statusColor.opacity(0.35), lineWidth: 4)
            )
            .shadow(color: statusColor.opacity(0.25), radius: 20)
            .padding()
        }
        .sheet(isPresented: $showAddPatientSheet) {
            AddPatientSheet(isPresented: $showAddPatientSheet, issueText: $issueText, bedNumber: patient.bedNumber)
        }
    }
    
    struct AddPatientSheet: View {
        @Binding var isPresented: Bool
        @Binding var issueText: String
        let bedNumber: Int
        
        var body: some View {
            VStack(spacing: 20) {
                
                Text("Reason for Admitting")
                    .font(.headline)
                
                TextField("Enter issue here...", text: $issueText)
                    .cornerRadius(15)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button("Confirm") {
                    Task {
                        do {
                            try await WardService.shared.addPatient(
                                bedNumber: bedNumber,
                                issueText: issueText
                            )
                            isPresented = false
                            issueText = ""
                            
                        } catch {
                            print("FAILED:", error)
                        }
                        
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [.orange, .pink, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
        }
    }
    
    // MARK: Patient Vital Card
    struct PatientVitalCard: View {
        
        let title: String
        let value: String
        let unit: String
        let color: Color
        
        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                
                Text(title)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .frame(width: 110, height: 110)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 6, y: 4)
        }
    }
}

