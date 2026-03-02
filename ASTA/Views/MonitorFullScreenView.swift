//
//  MonitorFullScreenView.swift
//  ASTA
//
//  Created by Shaswat Shrey on 12/02/26.
//
import SwiftUI

struct MonitorFullscreenView: View {

    let imageURL: String?
    @Environment(\.dismiss) private var dismiss

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

            if let imageString = imageURL,
               let encoded = imageString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let url = URL(string: encoded) {

                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(.white)

                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding()

                    case .failure:
                        Text("Failed to load image")
                            .foregroundColor(.black)

                    @unknown default:
                        EmptyView()
                    }
                }
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                Spacer()
            }
        }
    }
}

