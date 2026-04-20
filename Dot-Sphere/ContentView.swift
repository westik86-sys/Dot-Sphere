//
//  ContentView.swift
//  Dot-Sphere
//
//  Created by Pavel Korostelev on 20.04.2026.
//

import SwiftUI

struct ContentView: View {
    @State private var progress: Float = 0
    @State private var rotationSpeed: Float = 1
    @State private var gradientRandomness: Float = 0

    var body: some View {
        ZStack {
            ParticleMetalView(
                progress: $progress,
                rotationSpeed: $rotationSpeed,
                gradientRandomness: $gradientRandomness
            )
                .ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 18) {
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
                            Text("Sphere")
                            Spacer()
                            Text("Cloud")
                        }
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                    }

                    VStack(spacing: 12) {
                        Slider(
                            value: Binding(
                                get: { Double(rotationSpeed) },
                                set: { rotationSpeed = Float($0) }
                            ),
                            in: 0...2
                        )
                        .tint(.white)

                        HStack {
                            Text("Still")
                            Spacer()
                            Text("Rotation")
                            Spacer()
                            Text("Fast")
                        }
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                    }

                    VStack(spacing: 12) {
                        Slider(
                            value: Binding(
                                get: { Double(gradientRandomness) },
                                set: { gradientRandomness = Float($0) }
                            ),
                            in: 0...1
                        )
                        .tint(.white)

                        HStack {
                            Text("Gradient")
                            Spacer()
                            Text("Random color")
                        }
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 42)
                .opacity(0.86)
            }
        }
        .background(.black)
    }
}

#Preview {
    ContentView()
}
