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
    @State private var breakupForce: Float = 1
    @State private var interactionRadius: Float = 1
    @State private var returnSpeed: Float = 1
    @State private var particleBrightness: Float = 1
    @State private var particleGlow: Float = 1
    @State private var isSettingsPresented = false
    @State private var interactionPoint = SIMD2<Float>(0, 0)
    @State private var interactionStrength: Float = 0

    var body: some View {
        ZStack {
            ParticleMetalView(
                progress: $progress,
                rotationSpeed: $rotationSpeed,
                gradientRandomness: $gradientRandomness,
                breakupForce: $breakupForce,
                interactionRadius: $interactionRadius,
                returnSpeed: $returnSpeed,
                particleBrightness: $particleBrightness,
                particleGlow: $particleGlow,
                interactionPoint: $interactionPoint,
                interactionStrength: $interactionStrength
            )
                .ignoresSafeArea()

            GeometryReader { proxy in
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .local)
                            .onChanged { value in
                                updateInteraction(at: value.location, in: proxy.size)
                            }
                            .onEnded { _ in
                                interactionStrength = 0
                            }
                    )
            }
            .ignoresSafeArea()

            VStack {
                Spacer()

                settingsControls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 34)
            }
        }
        .background(.black)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $isSettingsPresented) {
            settingsSheet
                .preferredColorScheme(.dark)
                .presentationDetents([.height(470)])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
        }
    }

    private var settingsControls: some View {
        Button {
            isSettingsPresented = true
        } label: {
            Text("Settings")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white)
                .frame(height: 44)
                .padding(.horizontal, 18)
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .glassEffect(
            .regular.tint(.white.opacity(0.08)).interactive(),
            in: Capsule()
        )
    }

    private var settingsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    controlSlider(
                        value: $progress,
                        range: 0...1,
                        leading: "Sphere",
                        trailing: "Cloud"
                    )

                    controlSlider(
                        value: $rotationSpeed,
                        range: 0...2,
                        leading: "Still",
                        center: "Rotation",
                        trailing: "Fast"
                    )

                    controlSlider(
                        value: $gradientRandomness,
                        range: 0...1,
                        leading: "Gradient",
                        trailing: "Random color"
                    )

                    controlSlider(
                        value: $breakupForce,
                        range: 0.35...2.2,
                        leading: "Soft",
                        center: "Breakup force",
                        trailing: "Hard"
                    )

                    controlSlider(
                        value: $interactionRadius,
                        range: 0.45...1.7,
                        leading: "Small",
                        center: "Touch radius",
                        trailing: "Wide"
                    )

                    controlSlider(
                        value: $returnSpeed,
                        range: 0.45...1.9,
                        leading: "Slow",
                        center: "Return speed",
                        trailing: "Fast"
                    )

                    controlSlider(
                        value: $particleBrightness,
                        range: 0.35...2,
                        leading: "Dim",
                        center: "Brightness",
                        trailing: "Bright"
                    )

                    controlSlider(
                        value: $particleGlow,
                        range: 0.2...2.2,
                        leading: "Soft",
                        center: "Glow",
                        trailing: "Bloom"
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isSettingsPresented = false
                    }
                }
            }
        }
    }

    private func controlSlider(
        value: Binding<Float>,
        range: ClosedRange<Double>,
        leading: String,
        center: String? = nil,
        trailing: String
    ) -> some View {
        VStack(spacing: 10) {
            Slider(
                value: Binding(
                    get: { Double(value.wrappedValue) },
                    set: { value.wrappedValue = Float($0) }
                ),
                in: range
            )
            .tint(.white)

            HStack {
                Text(leading)
                Spacer()

                if let center {
                    Text(center)
                    Spacer()
                }

                Text(trailing)
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.72))
        }
    }

    private func updateInteraction(at location: CGPoint, in size: CGSize) {
        guard size.width > 0, size.height > 0 else {
            return
        }

        let normalizedX = Float((location.x / size.width) * 2 - 1)
        let normalizedY = Float(1 - (location.y / size.height) * 2)

        interactionPoint = SIMD2<Float>(normalizedX, normalizedY)
        interactionStrength = 1
    }
}

#Preview {
    ContentView()
}
