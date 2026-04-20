import MetalKit

final class ParticleRenderer: NSObject, MTKViewDelegate {
    private struct Particle {
        var spherePosition: SIMD4<Float>
        var scatterPosition: SIMD4<Float>
        var colorAndSize: SIMD4<Float>
    }

    private struct Uniforms {
        var viewProjectionMatrix: simd_float4x4
        var time: Float
        var progress: Float
        var aspectRatio: Float
        var pointScale: Float
    }

    private let particleCount = 1_400

    private var commandQueue: MTLCommandQueue?
    private var pipelineState: MTLRenderPipelineState?
    private var particleBuffer: MTLBuffer?
    private var uniformBuffer: MTLBuffer?
    private var startTime = CACurrentMediaTime()

    var progress: Float = 0

    func configure(with view: MTKView) {
        guard let device = view.device else {
            return
        }

        commandQueue = device.makeCommandQueue()
        particleBuffer = makeParticleBuffer(device: device)
        uniformBuffer = device.makeBuffer(length: MemoryLayout<Uniforms>.stride, options: .storageModeShared)
        pipelineState = makePipelineState(device: device, view: view)
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard
            let drawable = view.currentDrawable,
            let renderPassDescriptor = view.currentRenderPassDescriptor,
            let commandBuffer = commandQueue?.makeCommandBuffer(),
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        else {
            return
        }

        updateUniforms(for: view)

        if let pipelineState, let particleBuffer, let uniformBuffer {
            encoder.setRenderPipelineState(pipelineState)
            encoder.setVertexBuffer(particleBuffer, offset: 0, index: 0)
            encoder.setVertexBuffer(uniformBuffer, offset: 0, index: 1)
            encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particleCount)
        }

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private func makePipelineState(device: MTLDevice, view: MTKView) -> MTLRenderPipelineState? {
        guard
            let library = device.makeDefaultLibrary(),
            let vertexFunction = library.makeFunction(name: "particleVertex"),
            let fragmentFunction = library.makeFunction(name: "particleFragment")
        else {
            return nil
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].rgbBlendOperation = .add
        descriptor.colorAttachments[0].alphaBlendOperation = .add
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        return try? device.makeRenderPipelineState(descriptor: descriptor)
    }

    private func makeParticleBuffer(device: MTLDevice) -> MTLBuffer? {
        var particles = [Particle]()
        particles.reserveCapacity(particleCount)

        for index in 0..<particleCount {
            let sphere = fibonacciSpherePoint(index: index, count: particleCount)
            let radiusJitter = Float.random(in: 0.72...1.02)
            let spherePosition = sphere * radiusJitter
            let scatterDistance = Float.random(in: 1.2...2.45)
            let scatterNoise = randomUnitVector() * Float.random(in: 0.0...0.34)
            let scatterPosition = sphere * scatterDistance + scatterNoise

            let vertical = (sphere.y + 1) * 0.5
            let purple = SIMD3<Float>(0.48, 0.18, 1.0)
            let red = SIMD3<Float>(1.0, 0.08, 0.32)
            let color = purple + (red - purple) * vertical
            let size = Float.random(in: 3.0...6.4)

            particles.append(
                Particle(
                    spherePosition: SIMD4<Float>(spherePosition, 1),
                    scatterPosition: SIMD4<Float>(scatterPosition, 1),
                    colorAndSize: SIMD4<Float>(color.x, color.y, color.z, size)
                )
            )
        }

        return device.makeBuffer(
            bytes: particles,
            length: MemoryLayout<Particle>.stride * particles.count,
            options: .storageModeShared
        )
    }

    private func updateUniforms(for view: MTKView) {
        guard let uniformBuffer else {
            return
        }

        let elapsed = Float(CACurrentMediaTime() - startTime)
        let width = max(Float(view.drawableSize.width), 1)
        let height = max(Float(view.drawableSize.height), 1)
        let aspectRatio = width / height
        let projection = makePerspectiveMatrix(
            fieldOfViewY: 42 * .pi / 180,
            aspectRatio: aspectRatio,
            nearZ: 0.1,
            farZ: 100
        )
        let viewMatrix = makeTranslationMatrix(x: 0, y: 0, z: -4.2)
        let uniforms = Uniforms(
            viewProjectionMatrix: projection * viewMatrix,
            time: elapsed,
            progress: progress,
            aspectRatio: aspectRatio,
            pointScale: min(width, height) / 390
        )

        uniformBuffer.contents().copyMemory(from: [uniforms], byteCount: MemoryLayout<Uniforms>.stride)
    }

    private func fibonacciSpherePoint(index: Int, count: Int) -> SIMD3<Float> {
        let i = Float(index) + 0.5
        let n = Float(count)
        let goldenAngle = Float.pi * (3 - sqrt(5))
        let y = 1 - (i / n) * 2
        let radius = sqrt(max(0, 1 - y * y))
        let theta = goldenAngle * i

        return SIMD3<Float>(
            cos(theta) * radius,
            y,
            sin(theta) * radius
        )
    }

    private func randomUnitVector() -> SIMD3<Float> {
        let z = Float.random(in: -1...1)
        let angle = Float.random(in: 0...(2 * .pi))
        let radius = sqrt(max(0, 1 - z * z))

        return SIMD3<Float>(
            cos(angle) * radius,
            sin(angle) * radius,
            z
        )
    }

    private func makeTranslationMatrix(x: Float, y: Float, z: Float) -> simd_float4x4 {
        simd_float4x4(
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(x, y, z, 1)
        )
    }

    private func makePerspectiveMatrix(
        fieldOfViewY: Float,
        aspectRatio: Float,
        nearZ: Float,
        farZ: Float
    ) -> simd_float4x4 {
        let yScale = 1 / tan(fieldOfViewY * 0.5)
        let xScale = yScale / aspectRatio
        let zRange = farZ - nearZ
        let zScale = -(farZ + nearZ) / zRange
        let wzScale = -2 * farZ * nearZ / zRange

        return simd_float4x4(
            SIMD4<Float>(xScale, 0, 0, 0),
            SIMD4<Float>(0, yScale, 0, 0),
            SIMD4<Float>(0, 0, zScale, -1),
            SIMD4<Float>(0, 0, wzScale, 0)
        )
    }
}
