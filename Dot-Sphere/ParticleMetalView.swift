import MetalKit
import SwiftUI

struct ParticleMetalView: UIViewRepresentable {
    @Binding var progress: Float
    @Binding var shapeBlend: Float
    @Binding var rotationSpeed: Float
    @Binding var gradientRandomness: Float
    @Binding var breakupForce: Float
    @Binding var interactionRadius: Float
    @Binding var returnSpeed: Float
    @Binding var particleBrightness: Float
    @Binding var particleGlow: Float
    @Binding var interactionPoint: SIMD2<Float>
    @Binding var interactionStrength: Float
    @Binding var objectRotation: SIMD2<Float>
    @Binding var isObjectRotationHeld: Bool

    func makeCoordinator() -> ParticleRenderer {
        ParticleRenderer()
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.backgroundColor = .black
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        view.colorPixelFormat = .bgra8Unorm
        view.preferredFramesPerSecond = 60
        view.isPaused = false
        view.enableSetNeedsDisplay = false
        view.delegate = context.coordinator

        context.coordinator.configure(with: view)

        return view
    }

    func updateUIView(_ view: MTKView, context: Context) {
        context.coordinator.progress = progress
        context.coordinator.shapeBlend = shapeBlend
        context.coordinator.rotationSpeed = rotationSpeed
        context.coordinator.gradientRandomness = gradientRandomness
        context.coordinator.breakupForce = breakupForce
        context.coordinator.interactionRadius = interactionRadius
        context.coordinator.returnSpeed = returnSpeed
        context.coordinator.particleBrightness = particleBrightness
        context.coordinator.particleGlow = particleGlow
        context.coordinator.interactionPoint = interactionPoint
        context.coordinator.interactionStrength = interactionStrength
        context.coordinator.objectRotation = objectRotation
        context.coordinator.isObjectRotationHeld = isObjectRotationHeld
    }
}
