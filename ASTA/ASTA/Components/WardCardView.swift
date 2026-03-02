//  WardCardView.swift
//  ASTA
//  Created by Shaswat Shrey on 04/02/26.

import SwiftUI

struct WardCardView: View {

    let title: String
    let type: String
    let floor: String
    let occupied: Int
    let total: Int
    let color: Color
    let onTap: () -> Void

    @State private var isPressed = false

    private var percentage: Int {
        Int((Double(occupied) / Double(total)) * 100)
    }

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onTap()
        } label: {

            VStack(alignment: .leading, spacing: 14) {

                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
                    .foregroundColor(.black)

                Text("Type: \(type)")
                    .foregroundColor(.gray)

                Text("Floor: \(floor)")
                    .foregroundColor(.gray)

                HStack {
                    Text("Occupancy: \(occupied)/\(total) beds")
                        .foregroundColor(.black)

                    Spacer()

                    Text("\(percentage)%")
                        .fontDesign(.monospaced)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                }

                ProgressBarView(
                    progress: Double(occupied) / Double(total),
                    color: color
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(1.0))
            )
            .shadow(color: color.opacity(0.3),
                    radius: 12,
                    x: 0,
                    y: 6)
            .padding(.horizontal)
            .padding(.top, 20)

            // 3D press effect
            .scaleEffect(isPressed ? 0.97 : 1)
            .rotation3DEffect(
                .degrees(isPressed ? 8 : 0),
                axis: (x: 1, y: 0, z: 0)
            )
            .animation(.spring(), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 50)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

