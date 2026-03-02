//  AnalyticsView.swift
//  ASTA
//  Created by Shaswat Shrey on 22/02/26.

import SwiftUI
import Charts
import PDFKit

enum AnalyticsTimeRange: String, CaseIterable {
    case day = "24 Hours"
    case week = "7 Days"
    case month = "30 Days"
}

struct AnalyticsView: View {
    
    let patientId: String
    @StateObject private var vm = AnalyticsViewModel()
    @State private var selectedRange: AnalyticsTimeRange = .day
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Static Section
            headerSection
            // Scrollable Graphs
            ScrollView {
                VStack(spacing: 20) {
                    graphContent
                }
                .padding()
            }
            Button {
                generatePDF()
            } label: {
                HStack {
                    Image(systemName: "arrow.down.doc")
                    Text("Download PDF")
                        .fontWeight(.semibold)
                }
                .frame(width: 300, alignment: .init(horizontal: .center, vertical: .center))
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
            }
            .padding(.top, 10)
        }
        .onAppear {
            loadData()
        }
        .onChange(of: selectedRange) {
            loadData()
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.90, blue: 0.92),
                    Color(red: 0.92, green: 0.86, blue: 0.90)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.white, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Image(systemName: "chart.xyaxis.line")
                        .foregroundColor(.black)
                    Text("Analytics")
                        .font(.headline)
                        .foregroundColor(.black)
                }
            }
        }
    }
    private func loadData() {
        Task {
            await vm.fetchVitals(
                patientId: patientId,
                range: convertRange(selectedRange)
            )
        }
    }
    
    private func convertRange(_ range: AnalyticsTimeRange) -> String {
        switch range {
        case .day: return "24h"
        case .week: return "7d"
        case .month: return "30d"
        }
    }
    private var graphContent: some View {
        VStack(spacing: 20) {
            GraphCard(title: "SpO₂ Levels", unit: "%", color: .blue, data: vm.spo2Data)
            GraphCard(title: "Heart Rate", unit: "bpm", color: .red,data: vm.heartRateData)
            GraphCard(title: "Blood Pressure (Systolic)", unit: "mmHg", color: .purple, data: vm.systolicData)
            GraphCard(title: "Blood Pressure (Diastolic)", unit: "mmHg", color: .orange, data: vm.diastolicData)
            GraphCard(title: "Respiratory Rate", unit: "rpm", color: .green, data: vm.respirationData)
        }
    }
    private func generatePDF() {
        
        let renderer = ImageRenderer(content: graphContent.frame(width: 390))
        
        guard let uiImage = renderer.uiImage else { return }
        
        let pageWidth: CGFloat = 390
        let pageHeight: CGFloat = 690
        
        let pdfRenderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        )
        
        let data = pdfRenderer.pdfData { context in
            var currentY: CGFloat = 0
            while currentY < uiImage.size.height {
                context.beginPage()
                let drawRect = CGRect(
                    x: 0,
                    y: -currentY,
                    width: uiImage.size.width,
                    height: uiImage.size.height
                )
                uiImage.draw(in: drawRect)
                currentY += pageHeight
            }
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("AnalyticsReport.pdf")
        
        do {
            try data.write(to: url)
            sharePDF(url: url)
        } catch {
            print("Failed to write PDF:", error)
        }
    }
}

extension AnalyticsView {
    
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            Text("Patient's vital signs trends")
                .foregroundColor(.black)
            // Time Selector
            timeRangeSelector
        }
        .padding()
        .background(Color.white)
    }
    
    private var timeRangeSelector: some View {
        HStack(spacing: 12) {
            ForEach(AnalyticsTimeRange.allCases, id: \.self) { range in
                let isSelected = (selectedRange == range)
                Button {
                    selectedRange = range
                } label: {
                    Text(range.rawValue)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(isSelected ? .white : .black)
                }
                .padding(.vertical, 10)
                .background(
                    isSelected
                    ? AnyView(
                        LinearGradient(
                            colors: [.orange, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    : AnyView(Color.gray.opacity(0.15))
                )
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
            }
        }
    }
}

struct GraphCard: View {
    
    let title: String
    let unit: String
    let color: Color
    let data: [VitalPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.black)
                Spacer()
                
                Text(unit)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.1))
                    .clipShape(Capsule())
                    .foregroundColor(.black)
            }
            
            if data.isEmpty {
                Text("No Data Available")
                    .frame(height: 180)
                    .frame(maxWidth: .infinity)
                    .background(color.opacity(0.1))
                    .cornerRadius(12)
                    .foregroundColor(.black)
            } else {
                
                Chart(data) { point in
                    LineMark(
                        x: .value("Time", point.time),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(color)
                    .interpolationMethod(.catmullRom)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                            .foregroundStyle(.black)
                            .font(.caption)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                            .foregroundStyle(.black)
                            .font(.caption)
                    }
                }
            }
            
            statsSection
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 8)
    }
    
    private var statsSection: some View {
        HStack {
            statView(title: "Average", value: averageText)
            Spacer()
            statView(title: "Min", value: minText)
            Spacer()
            statView(title: "Max", value: maxText)
        }
    }
    
    private var averageText: String {
        guard !data.isEmpty else { return "-- \(unit)" }
        let avg = data.map { $0.value }.reduce(0,+) / Double(data.count)
        return String(format: "%.1f %@", avg, unit)
    }
    
    private var minText: String {
        guard let min = data.map({ $0.value }).min() else { return "-- \(unit)" }
        return String(format: "%.1f %@", min, unit)
    }
    
    private var maxText: String {
        guard let max = data.map({ $0.value }).max() else { return "-- \(unit)" }
        return String(format: "%.1f %@", max, unit)
    }
    
    private func statView(title: String, value: String) -> some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.black)
            Text(value)
                .font(.headline)
                .foregroundColor(.black)
        }
    }
}

private func sharePDF(url: URL) {
    let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
    
    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let root = scene.windows.first?.rootViewController {
        root.present(activityVC, animated: true)
    }
}
