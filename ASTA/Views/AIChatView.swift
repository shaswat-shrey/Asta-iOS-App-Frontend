//  AIChatView.swift
//  ASTA
//  Created by Shaswat Shrey on 15/02/26.

import SwiftUI

struct AIChatView: View {
    
    let messageText: String = "Working on it..."
    @State private var displayText: String = ""
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.92, green: 0.80, blue: 0.85),
                    Color(red: 0.84, green: 0.70, blue: 0.76)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            VStack {
                Text(displayText)
                    .font(.system(size: 25, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(.black))
            }
            .padding(.top)
        }
        .navigationTitle("AI Assistant")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            animateMessage()
        }
    }
    
    func animateMessage() {
        displayText = ""
        for(index, letter) in messageText.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.10) {
                displayText.append(letter)
            }
        }
    }
}




