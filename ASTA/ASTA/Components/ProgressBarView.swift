//  ProgressBarView.swift
//  ASTA
//  Created by Shaswat Shrey on 04/02/26.

import SwiftUI

struct ProgressBarView: View {

    let progress: Double   
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.25))
                    .frame(height: 8)

                Capsule()
                    .fill(color)
                    .frame(
                        width: geo.size.width * progress,
                        height: 8
                    )
            }
        }
        .frame(height: 8)
    }
}
