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
    @State private var isSettingsPresented = false

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
                .presentationDetents([.height(300)])
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
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
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
}

#Preview {
    ContentView()
}
