#version 440

// SPDX-License-Identifier: GPL-3.0-only
// Adapted from jaxparrow07/liquidglass-kde-widgets, commit ff196b4.
// See docs/liquidglass-widgets-assessment.md for provenance and changes.

// Crop shader: maps widget-local UV to wallpaper UV and samples.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;
    float qt_Opacity;
    vec2  uvOffset;
    vec2  uvAxisX;
    vec2  uvAxisY;
};

layout(binding = 1) uniform sampler2D source;

void main() {
    vec2 wpUV = clamp(uvOffset + qt_TexCoord0.x * uvAxisX + qt_TexCoord0.y * uvAxisY, vec2(0.0), vec2(1.0));
    fragColor = texture(source, wpUV) * qt_Opacity;
}
