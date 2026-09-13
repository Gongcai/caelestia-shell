#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 panelSize;
    vec2 sourceSize;
    vec2 sampleOrigin;
    vec2 sampleAxisX;
    vec2 sampleAxisY;
    float radius;
    float refraction;
    vec4 tint;
};

layout(binding = 1) uniform sampler2D source;

float roundedBox(vec2 p, vec2 halfSize, float r) {
    vec2 q = abs(p) - halfSize + r;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

vec3 sampleBackdrop(vec2 uv) {
    vec2 pixel = 1.5 / sourceSize;
    vec3 c = texture(source, clamp(uv, 0.0, 1.0)).rgb * 0.4;
    c += texture(source, clamp(uv + vec2(pixel.x, 0.0), 0.0, 1.0)).rgb * 0.15;
    c += texture(source, clamp(uv - vec2(pixel.x, 0.0), 0.0, 1.0)).rgb * 0.15;
    c += texture(source, clamp(uv + vec2(0.0, pixel.y), 0.0, 1.0)).rgb * 0.15;
    c += texture(source, clamp(uv - vec2(0.0, pixel.y), 0.0, 1.0)).rgb * 0.15;
    return c;
}

void main() {
    vec2 size = max(panelSize, vec2(1.0));
    vec2 p = (qt_TexCoord0 - 0.5) * size;
    float r = clamp(radius, 0.0, min(size.x, size.y) * 0.5);
    float d = roundedBox(p, size * 0.5, r);
    float aa = max(fwidth(d), 0.5);
    float coverage = 1.0 - smoothstep(-aa, aa, d);
    if (coverage <= 0.0)
        discard;

    // The SDF normal bends the sample along each edge, including the corners.
    vec2 normal = vec2(
        roundedBox(p + vec2(0.5, 0.0), size * 0.5, r) - roundedBox(p - vec2(0.5, 0.0), size * 0.5, r),
        roundedBox(p + vec2(0.0, 0.5), size * 0.5, r) - roundedBox(p - vec2(0.0, 0.5), size * 0.5, r));
    normal /= max(length(normal), 0.001);
    float edge = 1.0 - smoothstep(0.0, min(48.0, min(size.x, size.y) * 0.25), -d);
    vec2 bend = -normal * refraction * edge * edge / size;
    vec2 uv = sampleOrigin + sampleAxisX * qt_TexCoord0.x + sampleAxisY * qt_TexCoord0.y;
    vec2 offset = sampleAxisX * bend.x + sampleAxisY * bend.y;
    vec3 c = sampleBackdrop(uv + offset);
    c.r = mix(c.r, sampleBackdrop(uv + offset * 1.045).r, edge);
    c.b = mix(c.b, sampleBackdrop(uv + offset * 0.955).b, edge);
    // QColor uniforms are premultiplied.
    c = c * (1.0 - tint.a) + tint.rgb;
    float rim = 1.0 - smoothstep(0.5, 2.0, abs(d));
    float light = 0.5 + 0.5 * dot(normal, normalize(vec2(-0.6, -0.8)));
    c = mix(c, vec3(1.0), rim * (0.12 + 0.28 * light));
    fragColor = vec4(c * coverage, coverage) * qt_Opacity;
}
