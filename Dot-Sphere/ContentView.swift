//
//  ContentView.swift
//  Dot-Sphere
//
//  Created by Pavel Korostelev on 20.04.2026.
//

import SwiftUI

private enum ParticleShapePreset: String, CaseIterable, Identifiable {
    case sphere
    case cube
    case logo

    var id: Self { self }

    var title: String {
        switch self {
        case .sphere:
            return "Sphere"
        case .cube:
            return "Cube"
        case .logo:
            return "Logo"
        }
    }

    var shapeBlend: Float {
        switch self {
        case .sphere:
            return 0
        case .cube:
            return 1
        case .logo:
            return 2
        }
    }
}

private enum ParticleGestureMode {
    case interaction
    case rotation
}

struct ContentView: View {
    @State private var progress: Float = 0
    @State private var selectedShape: ParticleShapePreset = .sphere
    @State private var shapeBlend: Float = 0
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
    @State private var objectRotation = SIMD2<Float>(0, 0)
    @State private var isObjectRotationHeld = false
    @State private var activeGestureMode: ParticleGestureMode?
    @State private var rotationAtGestureStart = SIMD2<Float>(0, 0)

    var body: some View {
        ZStack {
            ParticleMetalView(
                progress: $progress,
                shapeBlend: $shapeBlend,
                rotationSpeed: $rotationSpeed,
                gradientRandomness: $gradientRandomness,
                breakupForce: $breakupForce,
                interactionRadius: $interactionRadius,
                returnSpeed: $returnSpeed,
                particleBrightness: $particleBrightness,
                particleGlow: $particleGlow,
                interactionPoint: $interactionPoint,
                interactionStrength: $interactionStrength,
                objectRotation: $objectRotation,
                isObjectRotationHeld: $isObjectRotationHeld
            )
                .ignoresSafeArea()

            GeometryReader { proxy in
                Color.clear
                    .contentShape(Rectangle())
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .local)
                            .onChanged { value in
                                updateGesture(with: value, in: proxy.size)
                            }
                            .onEnded { _ in
                                interactionStrength = 0
                                isObjectRotationHeld = false
                                activeGestureMode = nil
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
                    shapePresetPicker

                    controlSlider(
                        value: $progress,
                        range: 0...1,
                        leading: "Shape",
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

    private var shapePresetPicker: some View {
        Picker("Shape", selection: $selectedShape) {
            ForEach(ParticleShapePreset.allCases) { preset in
                Text(preset.title)
                    .tag(preset)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedShape) { _, newValue in
            shapeBlend = newValue.shapeBlend
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

    private func updateGesture(with value: DragGesture.Value, in size: CGSize) {
        let mode: ParticleGestureMode

        if let activeGestureMode {
            mode = activeGestureMode
        } else {
            mode = gestureMode(startingAt: value.startLocation, in: size)
            self.activeGestureMode = mode
            rotationAtGestureStart = objectRotation
        }

        switch mode {
        case .interaction:
            isObjectRotationHeld = false
            updateInteraction(at: value.location, in: size)
        case .rotation:
            interactionStrength = 0
            updateObjectRotation(with: value, in: size)
        }
    }

    private func gestureMode(startingAt location: CGPoint, in size: CGSize) -> ParticleGestureMode {
        isParticleArea(at: location, in: size) ? .interaction : .rotation
    }

    private func isParticleArea(at location: CGPoint, in size: CGSize) -> Bool {
        guard size.width > 0, size.height > 0 else {
            return false
        }

        let shorterSide = min(size.width, size.height)
        let cloudPadding = CGFloat(progress) * shorterSide * 0.06
        let center = CGPoint(
            x: size.width * 0.5,
            y: size.height * 0.45
        )

        switch selectedShape {
        case .sphere:
            let halfWidth = shorterSide * 0.26 + cloudPadding
            let halfHeight = shorterSide * 0.29 + cloudPadding
            let x = (location.x - center.x) / halfWidth
            let y = (location.y - center.y) / halfHeight

            return x * x + y * y <= 1
        case .cube:
            let halfSize = shorterSide * 0.31 + cloudPadding

            return abs(location.x - center.x) <= halfSize
                && abs(location.y - center.y) <= halfSize
        case .logo:
            let halfWidth = shorterSide * 0.34 + cloudPadding
            let top = center.y - shorterSide * 0.32 - cloudPadding
            let bottom = center.y + shorterSide * 0.34 + cloudPadding

            return abs(location.x - center.x) <= halfWidth
                && location.y >= top
                && location.y <= bottom
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

    private func updateObjectRotation(with value: DragGesture.Value, in size: CGSize) {
        isObjectRotationHeld = true

        guard size.width > 0, size.height > 0 else {
            return
        }

        let dragScale = max(Float(min(size.width, size.height)), 1)
        let deltaX = Float(value.translation.width) / dragScale
        let deltaY = Float(value.translation.height) / dragScale

        objectRotation.x = rotationAtGestureStart.x + deltaX * 4.2
        objectRotation.y = min(max(rotationAtGestureStart.y + deltaY * 3.2, -1.15), 1.15)
    }
}

#Preview {
    ContentView()
}
