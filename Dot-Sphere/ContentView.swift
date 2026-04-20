//
//  ContentView.swift
//  Dot-Sphere
//
//  Created by Pavel Korostelev on 20.04.2026.
//

import SwiftUI

struct ContentView: View {
    @State private var progress: Float = 0

    var body: some View {
        ZStack {
            ParticleMetalView(progress: $progress)
                .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 12) {
                    Slider(
                        value: Binding(
                            get: { Double(progress) },
                            set: { progress = Float($0) }
                        ),
                        in: 0...1
                    )
                    .tint(.white)

                    HStack {
                        Text("Сфера")
                        Spacer()
                        Text("Облако")
                    }
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 42)
            }
        }
        .background(.black)
    }
}

#Preview {
    ContentView()
}
