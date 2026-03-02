//  GenerateVideoView.swift
//  ASTA
//  Created by Shaswat Shrey on 07/02/26.

import SwiftUI
import AVKit

enum VideoQuality: String, CaseIterable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
}

enum TimeRange: String, CaseIterable {
    case fiveMin = "5 min"
    case tenMin = "10 min"
    case thirtyMin = "30 min"
}

enum VideoDuration: String, CaseIterable {
    case twoSec = "2s"
    case fourSec = "4s"
    case sixSec = "6s"
}

extension VideoQuality {
    var backendValue: String {
        switch self {
        case .low: return "low"
        case .medium: return "medium"
        case .high: return "high"
        }
    }
}

extension TimeRange {
    var minutes: Int {
        switch self {
        case .fiveMin: return 5
        case .tenMin: return 10
        case .thirtyMin: return 30
        }
    }
}

extension VideoDuration {
    var seconds: Int {
        switch self {
        case .twoSec: return 2
        case .fourSec: return 4
        case .sixSec: return 6
        }
    }
}

struct GenerateVideoView: View {

    let patient: Patient

    @State private var selectedQuality: VideoQuality = .medium
    @State private var selectedTimeRange: TimeRange = .fiveMin
    @State private var selectedDuration: VideoDuration = .twoSec
    
    @State private var isGenerating = false
    @State private var generatedVideoURL: String?
    @State private var errorMessage: String?
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 1.00, green: 0.88, blue: 0.90),
                    Color(red: 0.95, green: 0.80, blue: 0.90)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {

                    // MARK: Title
                    Text("Generate Video")
                        .font(.largeTitle)
                        .foregroundColor(Color.black)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // MARK: Patient Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text(patient.patientName ?? "No Patient")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.black)

                        Text("ID :\(patient.id)")
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.08), radius: 10, y: 6)

                    // MARK: Video Settings
                    VStack(alignment: .leading, spacing: 20) {

                        Text("Video Settings")
                            .font(.headline)
                            .foregroundColor(Color.black)

                        Text("Create a timelapse video from recent monitoring images.")
                            .foregroundColor(.gray)

                        // Quality & Time Range
                        HStack(spacing: 16) {
                            SettingsDropdownCard(
                                    title: "Quality",
                                    selection: $selectedQuality,
                                    options: VideoQuality.allCases
                                )

                                SettingsDropdownCard(
                                    title: "Time Range",
                                    selection: $selectedTimeRange,
                                    options: TimeRange.allCases
                                )
                            }

                            SettingsDropdownCard(
                                title: "Duration",
                                selection: $selectedDuration,
                                options: VideoDuration.allCases
                            )
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.08), radius: 10, y: 6)

                    // MARK: Generate Button
                    Button {
                        Task {
                            await generateVideo()
                            }
                    } label: {
                        Text(isGenerating ? "Generating…" : "Generate Video")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(
                                LinearGradient(
                                    colors: [.orange, .pink, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color.red.opacity(0.3), radius: 12)
                    }
                    .disabled(isGenerating)
                    if isGenerating {
                        ProgressView("Generating video…")
                            .padding(.top, 16)
                    }
                    if let urlString = generatedVideoURL,
                       let url = URL(string: urlString) {

                        VideoPlayer(player: player)
                            .frame(height: 240)
                            .cornerRadius(16)
                            .padding(.top, 16)
                            .onAppear {
                                if player == nil {
                                    player = AVPlayer(url: url)
                                    player?.play()
                                }
                            }
                            .onDisappear {
                                player?.pause()
                            }
                    }
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding(.top, 12)
                    }

                    // MARK: Preview Info
                    Text("Preview: Video will include images from last 5 min, each shown for 2s.")
                        .font(.footnote)
                        .foregroundColor(.black)
                        .padding(.top, 4)

                }
                .padding()
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Patient Details")
                    .font(.headline)
                    .foregroundColor(.black)
            }
        }
    }
    
    func generateVideo() async {

        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }

        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
                errorMessage = "User not authenticated"
                return
        }

        guard let url = URL(string: "http://localhost:3000/generate-video-mongo") else {
            errorMessage = "Invalid backend URL"
            return
        }

        let payload: [String: Any] = [
            "patientId": patient.id,
            "minutes": selectedTimeRange.minutes,
            "frameDuration": selectedDuration.seconds,
            "quality": selectedQuality.backendValue
        ]


        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                errorMessage = "Invalid response"
                return
            }

            print("STATUS CODE:", http.statusCode)
            print("RAW RESPONSE:", String(data: data, encoding: .utf8) ?? "nil")

            if http.statusCode == 401 {
                errorMessage = "Session expired. Please login again."
                return
            }
            
            guard (200...299).contains(http.statusCode) else {
                errorMessage = "Failed to generate video"
                return
            }
            let decoded = try JSONDecoder().decode(VideoResponse.self, from: data)
            generatedVideoURL = decoded.videoUrl

        } catch {
            print("FRONTEND ERROR:", error)
            errorMessage = "Failed to generate video"
        }

        isGenerating = false
    }
}

struct DropdownCard: View {

    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .foregroundColor(.gray)

            HStack {
                Text(value)
                    .fontWeight(.medium)

                Spacer()

                Image(systemName: "chevron.down")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.gray.opacity(0.3))
            )
        }
        .frame(maxWidth: .infinity)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Patient Vitals")
                    .font(.headline)
                    .foregroundColor(.black)
            }
        }
        
    }
}
struct SettingsDropdownCard<Option: Hashable & RawRepresentable>: View
where Option.RawValue == String {

    let title: String
    @Binding var selection: Option
    let options: [Option]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            Text(title)
                .foregroundColor(.gray)

            Menu {
                ForEach(options, id: \.self) { option in
                    Button {
                        selection = option
                    } label: {
                        if option == selection {
                            Label(option.rawValue, systemImage: "checkmark")
                        } else {
                            Text(option.rawValue)
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selection.rawValue)
                        .fontWeight(.medium)
                        .foregroundColor(Color.black)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.gray.opacity(0.3))
                )
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct VideoResponse: Codable {
    let videoUrl: String?
}

