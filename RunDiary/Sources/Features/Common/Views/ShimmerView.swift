//
//  ShimmerView.swift
//  RunDiary
//
//  Created by Claude on 10/22/25.
//

import SwiftUI

struct ShimmerView: View {
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.gray.opacity(0.3)

                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        .white.opacity(0.6),
                        .clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: geometry.size.width * 0.5)
                .offset(x: isAnimating ? geometry.size.width : -geometry.size.width * 0.5)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .onAppear {
            withAnimation(
                .linear(duration: 1.2)
                .repeatForever(autoreverses: false)
            ) {
                isAnimating = true
            }
        }
    }
}
