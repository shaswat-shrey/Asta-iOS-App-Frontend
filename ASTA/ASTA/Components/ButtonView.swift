//  ButtonView.swift
//  ASTA
//  Created by Shaswat Shrey on 05/02/26.


import SwiftUI

struct ButtonView: View {
    
    let title: String
    let onTap: () -> Void
    
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onTap()
        } label: {
                Text(title)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.orange, .pink, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .shadow(color: .red.opacity(0.5), radius: 5)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(
                DragGesture(minimumDistance: 50)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
        }
        
    }


#Preview {
    ButtonView(
        title: "Louis Vitton"
    ) {
        print("tapped")
    }
}
