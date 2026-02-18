#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
};

vertex VertexOut vertex_main(uint vertexID [[vertex_id]]) {
    float2 positions[4] = {
        float2(-1.0, -1.0),
        float2( 1.0, -1.0),
        float2(-1.0,  1.0),
        float2( 1.0,  1.0)
    };

    VertexOut out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    return out;
}

struct Uniforms {
    float time;
    int state;
    float stateTime;
    float2 resolution;
};

float circle(float2 p, float2 center, float radius, float feather) {
    return 1.0 - smoothstep(radius - feather, radius + feather, length(p - center));
}

float ring(float2 p, float2 center, float radius, float width, float feather) {
    float d = length(p - center);
    return smoothstep(radius - width - feather, radius - width, d) * (1.0 - smoothstep(radius - feather, radius + feather, d));
}

fragment float4 fragment_main(float4 position [[stage_in]],
                             constant Uniforms &uniforms [[buffer(0)]]) {
    float2 uv = position.xy / uniforms.resolution;
    float2 p = (position.xy * 2.0 - uniforms.resolution) / min(uniforms.resolution.x, uniforms.resolution.y);

    float4 color = float4(0.0);

    if (uniforms.state == 1) { // Loading
        // Dark background with slight motion
        float bg = 0.05 + 0.02 * sin(uniforms.time * 0.5 + uv.x * 2.0 + uv.y * 2.0);
        color = float4(bg, bg, bg, 0.85);

        // Rotating ring
        float angle = atan2(p.y, p.x) + uniforms.time * 3.0;
        float r = length(p);
        float ring_val = ring(p, float2(0.0), 0.3, 0.02, 0.01);

        // Add some "gap" to the ring to make it look like it's rotating
        float mask = smoothstep(-0.5, 0.5, sin(angle * 1.0));
        color += float4(0.5, 0.5, 0.5, 1.0) * ring_val * mask;

        // Central pulse
        float pulse = 0.05 * sin(uniforms.time * 4.0);
        color += float4(0.3, 0.3, 0.3, 1.0) * circle(p, float2(0.0), 0.05 + pulse, 0.01);

    } else if (uniforms.state == 2) { // Success
        float t = uniforms.stateTime;
        // Expanding wave
        float wave_radius = t * 2.5;
        float wave = ring(p, float2(0.0), wave_radius, 0.1, 0.05);

        // Background transition to green
        float bg_fade = smoothstep(0.0, 0.5, t);
        float4 bg_color = float4(0.0, 0.2 * bg_fade, 0.0, 0.6 * bg_fade);

        color = mix(float4(0.0, 0.0, 0.0, 0.85), bg_color, bg_fade);
        color += float4(0.0, 1.0, 0.2, 1.0) * wave * (1.0 - smoothstep(1.0, 1.5, t));

        // Final glow
        if (t > 0.5) {
            float glow = circle(p, float2(0.0), 0.2, 0.5) * (1.0 - smoothstep(1.0, 1.5, t));
            color += float4(0.0, 0.8, 0.3, 1.0) * glow * 0.3;
        }

    } else if (uniforms.state == 3) { // Error
        float t = uniforms.stateTime;
        // Red pulse background
        float pulse = 0.1 * sin(uniforms.time * 5.0);
        float bg_pulse = 0.3 + pulse;
        color = float4(bg_pulse, 0.0, 0.0, 0.85);

        // Vignette
        float vignette = 1.0 - smoothstep(0.5, 1.5, length(p));
        color *= vignette;

        // Distortion effect
        float dist = sin(p.y * 10.0 + uniforms.time * 10.0) * 0.01;
        float dist_circle = circle(p + float2(dist, 0.0), float2(0.0), 0.3, 0.05);
        color += float4(1.0, 0.1, 0.1, 1.0) * dist_circle * 0.2;
    }

    return color;
}
