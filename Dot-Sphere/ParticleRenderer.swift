import MetalKit

final class ParticleRenderer: NSObject, MTKViewDelegate {
    private struct Particle {
        var spherePosition: SIMD4<Float>
        var scatterPosition: SIMD4<Float>
        var colorAndSize: SIMD4<Float>
        var motion: SIMD4<Float>
    }

    private struct Uniforms {
        var viewProjectionMatrix: simd_float4x4
        var time: Float
        var progress: Float
        var aspectRatio: Float
        var pointScale: Float
        var rotationSpeed: Float
        var gradientRandomness: Float
    }

    private let particleCount = 1_900

    private var commandQueue: MTLCommandQueue?
    private var pipelineState: MTLRenderPipelineState?
    private var particleBuffer: MTLBuffer?
    private var uniformBuffer: MTLBuffer?
    private var startTime = CACurrentMediaTime()

    var progress: Float = 0
    var rotationSpeed: Float = 1
    var gradientRandomness: Float = 0

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
            var random = SeededRandom(seed: UInt32(index) &* 747_796_405 &+ 2_891_336_453)
            let shellBias = pow(random.nextFloat(), 0.34)
            let radiusJitter = 0.58 + shellBias * 0.46
            let spherePosition = sphere * radiusJitter
            let scatterDistance = 1.18 + pow(random.nextFloat(), 0.72) * 1.55
            let scatterNoise = randomUnitVector(random: &random) * (0.08 + random.nextFloat() * 0.42)
            let verticalLift = SIMD3<Float>(
                random.nextSignedFloat() * 0.1,
                random.nextSignedFloat() * 0.36,
                random.nextSignedFloat() * 0.08
            )
            let scatterPosition = SIMD3<Float>(
                sphere.x * scatterDistance * 1.16,
                sphere.y * scatterDistance * 0.86,
                sphere.z * scatterDistance * 1.02
            ) + scatterNoise + verticalLift

            let vertical = (sphere.y + 1) * 0.5
            let purple = SIMD3<Float>(0.46, 0.16, 1.0)
            let magenta = SIMD3<Float>(0.94, 0.08, 0.62)
            let red = SIMD3<Float>(1.0, 0.09, 0.27)
            let upperColor = magenta + (red - magenta) * smoothstep(edge0: 0.45, edge1: 1, x: vertical)
            let color = purple + (upperColor - purple) * vertical
            let size = 2.4 + pow(random.nextFloat(), 2.2) * 5.6
            let motion = SIMD4<Float>(
                random.nextSignedFloat(),
                random.nextSignedFloat(),
                random.nextSignedFloat(),
                random.nextFloat()
            )

            particles.append(
                Particle(
                    spherePosition: SIMD4<Float>(spherePosition, 1),
                    scatterPosition: SIMD4<Float>(scatterPosition, 1),
                    colorAndSize: SIMD4<Float>(color.x, color.y, color.z, size),
                    motion: motion
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
        let viewMatrix = makeTranslationMatrix(x: 0, y: 0.4, z: -4.35)
        let uniforms = Uniforms(
            viewProjectionMatrix: projection * viewMatrix,
            time: elapsed,
            progress: progress,
            aspectRatio: aspectRatio,
            pointScale: min(width, height) / 390,
            rotationSpeed: rotationSpeed,
            gradientRandomness: gradientRandomness
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

    private func randomUnitVector(random: inout SeededRandom) -> SIMD3<Float> {
        let z = random.nextSignedFloat()
        let angle = random.nextFloat() * 2 * .pi
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

    private func smoothstep(edge0: Float, edge1: Float, x: Float) -> Float {
        let t = min(max((x - edge0) / (edge1 - edge0), 0), 1)
        return t * t * (3 - 2 * t)
    }
}

private struct SeededRandom {
    private var state: UInt32

    init(seed: UInt32) {
        state = seed == 0 ? 1 : seed
    }

    mutating func nextFloat() -> Float {
        state = state &* 1_664_525 &+ 1_013_904_223
        return Float(state >> 8) / Float(UInt32.max >> 8)
    }

    mutating func nextSignedFloat() -> Float {
        nextFloat() * 2 - 1
    }
}
