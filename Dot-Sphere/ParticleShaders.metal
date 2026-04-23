#include <metal_stdlib>
using namespace metal;

struct Particle {
    float4 spherePosition;
    float4 cubePosition;
    float4 scatterPosition;
    float4 colorAndSize;
    float4 motion;
};

struct ParticleState {
    float4 position;
    float4 velocity;
};

struct Uniforms {
    float4x4 viewProjectionMatrix;
    float4 interaction;
    float4 physics;
    float4 appearance;
    float time;
    float deltaTime;
    float progress;
    float aspectRatio;
    float pointScale;
    float rotationSpeed;
    float gradientRandomness;
    uint particleCount;
};

struct VertexOut {
    float4 position [[position]];
    float3 color;
    float alpha;
    float glow;
    float pointSize [[point_size]];
};

static float3 targetPosition(Particle particle, constant Uniforms &uniforms) {
    float t = smoothstep(0.0, 1.0, uniforms.progress);
    float shapeT = smoothstep(0.0, 1.0, uniforms.appearance.z);
    float3 formPosition = mix(
        particle.spherePosition.xyz,
        particle.cubePosition.xyz,
        shapeT
    );
    float3 localPosition = mix(
        formPosition,
        particle.scatterPosition.xyz,
        t
    );
    float driftPhase = uniforms.time * (0.58 + particle.motion.w * 0.42) + particle.motion.w * 6.283185;
    float scatterWeight = 0.18 + t * 0.82;
    float3 drift = particle.motion.xyz * sin(driftPhase) * 0.026 * scatterWeight;
    localPosition += drift;

    return localPosition * mix(0.46, 0.62, t);
}

static float3 displayPosition(float3 localPosition, constant Uniforms &uniforms) {
    float t = smoothstep(0.0, 1.0, uniforms.progress);
    float spin = 0.7853982 + uniforms.time * uniforms.rotationSpeed * mix(0.36, 0.28, t);
    float tilt = 0.6154797;
    float spinCos = cos(spin);
    float spinSin = sin(spin);
    float tiltCos = cos(tilt);
    float tiltSin = sin(tilt);

    float3 spunPosition = float3(
        localPosition.x * spinCos + localPosition.z * spinSin,
        localPosition.y,
        -localPosition.x * spinSin + localPosition.z * spinCos
    );

    return float3(
        spunPosition.x,
        spunPosition.y * tiltCos - spunPosition.z * tiltSin,
        spunPosition.y * tiltSin + spunPosition.z * tiltCos
    );
}

kernel void particlePhysics(
    uint particleID [[thread_position_in_grid]],
    const device Particle *particles [[buffer(0)]],
    device ParticleState *states [[buffer(1)]],
    constant Uniforms &uniforms [[buffer(2)]]
) {
    if (particleID >= uniforms.particleCount) {
        return;
    }

    Particle particle = particles[particleID];
    ParticleState state = states[particleID];
    float3 currentPosition = state.position.xyz;
    float3 currentVelocity = state.velocity.xyz;
    float3 target = targetPosition(particle, uniforms);
    float dt = clamp(uniforms.deltaTime, 0.0, 1.0 / 30.0);
    float breakupForce = uniforms.physics.x;
    float returnSpeed = uniforms.physics.z;

    float3 acceleration = (target - currentPosition) * (34.0 * returnSpeed);
    acceleration -= currentVelocity * (8.5 * mix(0.82, 1.16, returnSpeed));

    float3 projectedPosition = displayPosition(currentPosition, uniforms);
    float4 viewPosition = uniforms.viewProjectionMatrix * float4(projectedPosition, 1.0);
    float2 screenPosition = viewPosition.xy / max(viewPosition.w, 0.001);
    float2 touchDelta = screenPosition - uniforms.interaction.xy;
    float touchDistance = length(touchDelta);
    float touchFalloff = 1.0 - smoothstep(0.0, uniforms.interaction.w, touchDistance);
    float touchStrength = uniforms.interaction.z * touchFalloff;

    if (touchStrength > 0.001) {
        float2 push2D = touchDelta + particle.motion.xy * 0.12;
        float2 pushDirection2D = push2D / max(length(push2D), 0.001);
        float depthKick = particle.motion.z * 0.48 + (particle.motion.w - 0.5) * 0.24;
        float3 pushDirection = normalize(float3(
            pushDirection2D.x * max(uniforms.aspectRatio, 0.001),
            pushDirection2D.y,
            depthKick
        ));
        float particleVariance = mix(0.72, 1.38, fract(particle.motion.w + particle.motion.x * 0.27));
        acceleration += pushDirection * touchStrength * particleVariance * 28.0 * breakupForce;
        currentVelocity += pushDirection * touchStrength * particleVariance * 0.34 * breakupForce;
    }

    currentVelocity += acceleration * dt;
    currentVelocity *= pow(0.985, dt * 60.0);
    currentPosition += currentVelocity * dt;

    states[particleID].position = float4(currentPosition, 1.0);
    states[particleID].velocity = float4(currentVelocity, 0.0);
}

vertex VertexOut particleVertex(
    uint vertexID [[vertex_id]],
    const device Particle *particles [[buffer(0)]],
    constant Uniforms &uniforms [[buffer(1)]],
    const device ParticleState *states [[buffer(2)]]
) {
    Particle particle = particles[vertexID];
    float t = smoothstep(0.0, 1.0, uniforms.progress);
    ParticleState state = states[vertexID];
    float3 rotatedPosition = displayPosition(state.position.xyz, uniforms);

    float4 viewPosition = uniforms.viewProjectionMatrix * float4(rotatedPosition, 1.0);
    float depth = clamp((rotatedPosition.z + 1.6) / 3.2, 0.0, 1.0);
    float velocityGlow = clamp(length(state.velocity.xyz) * 0.9, 0.0, 1.0);

    VertexOut out;
    out.position = viewPosition;
    float3 randomA = float3(0.42, 0.12, 1.0);
    float3 randomB = float3(1.0, 0.06, 0.5);
    float3 randomC = float3(1.0, 0.13, 0.22);
    float colorSeed = fract(particle.motion.w + particle.motion.x * 0.31 + particle.motion.y * 0.17);
    float3 randomGradient = mix(randomA, randomB, smoothstep(0.0, 0.72, colorSeed));
    randomGradient = mix(randomGradient, randomC, smoothstep(0.58, 1.0, colorSeed));
    float brightness = uniforms.appearance.x;
    float glowAmount = uniforms.appearance.y;
    out.color = mix(particle.colorAndSize.rgb, randomGradient, uniforms.gradientRandomness) * mix(0.56, 1.2, depth) * mix(1.0, 1.16, velocityGlow) * brightness;
    out.alpha = mix(0.16, 0.88, depth) * mix(0.9, 1.0, 1.0 - t) * mix(0.72, 1.16, brightness);
    out.glow = glowAmount;
    out.pointSize = particle.colorAndSize.a * uniforms.pointScale * mix(0.82, 1.0, t) * mix(0.56, 1.24, depth) * mix(1.0, 1.12, velocityGlow) * mix(0.82, 1.22, glowAmount);
    return out;
}

fragment float4 particleFragment(
    VertexOut in [[stage_in]],
    float2 pointCoord [[point_coord]]
) {
    float2 centered = pointCoord * 2.0 - 1.0;
    float distanceSquared = dot(centered, centered);

    if (distanceSquared > 1.0) {
        discard_fragment();
    }

    float glow = smoothstep(1.0, 0.0, distanceSquared);
    float core = smoothstep(0.32, 0.0, distanceSquared);
    float glowAmount = in.glow;
    float halo = glow * mix(0.28, 0.88, glowAmount);
    float alpha = in.alpha * mix(halo, 1.0, core);

    return float4(in.color * mix(0.9, 1.18, glowAmount), alpha);
}
