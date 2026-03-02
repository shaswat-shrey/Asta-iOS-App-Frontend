//  InitiationView.swift
//  ASTA
//  Created by Shaswat Shrey on 01/02/26.

import SwiftUI

struct InitiationView: View {
    
    let titleText = "ASTA"
    let subtitleText = "Health Tech"
    
    @State private var displayedTitle = ""
    @State private var displayedSubtitle = ""
    @State private var navigateToPage: Bool = false
    
    var body: some View {
        if navigateToPage {
            RootView()
        } else {
            ZStack {
                LinearGradient(
                    colors: [
                            Color(red: 0.98, green: 0.78, blue: 0.72), // deeper peach
                            Color(red: 0.95, green: 0.72, blue: 0.82), // richer pink
                            Color(red: 0.88, green: 0.76, blue: 0.90), // soft violet
                            Color(red: 0.78, green: 0.82, blue: 0.92), // muted sky blue
                            Color(red: 0.80, green: 0.88, blue: 0.86)  // gentle mint
                        ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()


                VStack(spacing: 8) {
                    
                    Text(displayedTitle)
                        .font(.system(size: 68, weight: .heavy, design: .rounded))
                        .foregroundColor(.black)
                    
                    Text(displayedSubtitle)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .opacity(0.8)
                        .foregroundColor(.black)
                }
            }
            .onAppear {
                animateTitle()
            }
        }
    }
    
    // MARK: - Animations
    
    func animateTitle() {
        displayedTitle = ""
        displayedSubtitle = ""
        
        
        for (index, letter) in titleText.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.10) {
                displayedTitle.append(letter)
            }
        }
        
        let titleDuration = Double(titleText.count) * 0.10 + 0.20
        
        for (index, letter) in subtitleText.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + titleDuration + Double(index) * 0.05) {
                displayedSubtitle.append(letter)
            }
        }
        
        let totalDuration =
        titleDuration + Double(subtitleText.count) * 0.05 + 0.50
        
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            withAnimation {
                navigateToPage = true
            }
        }
    }
}


#Preview {
    InitiationView()
}
