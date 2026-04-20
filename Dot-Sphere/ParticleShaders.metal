#include <metal_stdlib>
using namespace metal;

struct Particle {
    float4 spherePosition;
    float4 scatterPosition;
    float4 colorAndSize;
    float4 motion;
};

struct Uniforms {
    float4x4 viewProjectionMatrix;
    float time;
    float progress;
    float aspectRatio;
    float pointScale;
};

struct VertexOut {
    float4 position [[position]];
    float3 color;
    float alpha;
    float pointSize [[point_size]];
};

vertex VertexOut particleVertex(
    uint vertexID [[vertex_id]],
    const device Particle *particles [[buffer(0)]],
    const device Uniforms &uniforms [[buffer(1)]]
) {
    Particle particle = particles[vertexID];
    float t = smoothstep(0.0, 1.0, uniforms.progress);
    float3 localPosition = mix(
        particle.spherePosition.xyz,
        particle.scatterPosition.xyz,
        t
    );
    float driftPhase = uniforms.time * (0.58 + particle.motion.w * 0.42) + particle.motion.w * 6.283185;
    float scatterWeight = 0.18 + t * 0.82;
    float3 drift = particle.motion.xyz * sin(driftPhase) * 0.026 * scatterWeight;
    localPosition += drift;
    localPosition *= mix(0.46, 0.62, t);

    float spin = uniforms.time * mix(0.36, 0.28, t);
    float tilt = -0.18;
    float spinCos = cos(spin);
    float spinSin = sin(spin);
    float tiltCos = cos(tilt);
    float tiltSin = sin(tilt);

    float3 spunPosition = float3(
        localPosition.x * spinCos + localPosition.z * spinSin,
        localPosition.y,
        -localPosition.x * spinSin + localPosition.z * spinCos
    );
    float3 rotatedPosition = float3(
        spunPosition.x,
        spunPosition.y * tiltCos - spunPosition.z * tiltSin,
        spunPosition.y * tiltSin + spunPosition.z * tiltCos
    );

    float4 viewPosition = uniforms.viewProjectionMatrix * float4(rotatedPosition, 1.0);
    float depth = clamp((rotatedPosition.z + 1.6) / 3.2, 0.0, 1.0);

    VertexOut out;
    out.position = viewPosition;
    out.color = particle.colorAndSize.rgb * mix(0.56, 1.2, depth);
    out.alpha = mix(0.16, 0.88, depth) * mix(0.9, 1.0, 1.0 - t);
    out.pointSize = particle.colorAndSize.a * uniforms.pointScale * mix(0.82, 1.0, t) * mix(0.56, 1.24, depth);
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
    float alpha = in.alpha * mix(glow * 0.62, 1.0, core);

    return float4(in.color, alpha);
}
