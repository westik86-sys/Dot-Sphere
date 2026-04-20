import MetalKit
import SwiftUI

struct ParticleMetalView: UIViewRepresentable {
    @Binding var progress: Float
    @Binding var rotationSpeed: Float
    @Binding var gradientRandomness: Float

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
        context.coordinator.rotationSpeed = rotationSpeed
        context.coordinator.gradientRandomness = gradientRandomness
    }
}
