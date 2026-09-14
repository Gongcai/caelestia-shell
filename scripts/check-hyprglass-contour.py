#!/usr/bin/env python3
"""Render the actual Hyprglass GLSL through surfaceless EGL.

Requires Python packages numpy and PyOpenGL; Pillow is needed for --output-dir.
Pass src/Shaders.hpp from a checkout with the integration patch applied.
No running compositor is modified. --baseline renders an older header too.
"""

import argparse
import ctypes
import json
import os
from pathlib import Path
import re

os.environ.setdefault("PYOPENGL_PLATFORM", "egl")
os.environ.setdefault("EGL_PLATFORM", "surfaceless")

import numpy as np
from OpenGL import EGL, GL
from OpenGL.GL.shaders import compileProgram, compileShader


VERTEX = """#version 300 es
precision highp float;
out vec2 v_texcoord;
void main() {
    vec2 p = vec2(float(gl_VertexID & 1), float(gl_VertexID >> 1));
    v_texcoord = p;
    gl_Position = vec4(p * 2.0 - 1.0, 0.0, 1.0);
}
"""


class Context:
    def __enter__(self):
        self.display = EGL.eglGetDisplay(EGL.EGL_DEFAULT_DISPLAY)
        major, minor = ctypes.c_int(), ctypes.c_int()
        EGL.eglInitialize(self.display, major, minor)
        EGL.eglBindAPI(EGL.EGL_OPENGL_ES_API)
        attributes = (ctypes.c_int * 13)(
            EGL.EGL_SURFACE_TYPE, EGL.EGL_PBUFFER_BIT,
            EGL.EGL_RENDERABLE_TYPE, EGL.EGL_OPENGL_ES3_BIT,
            EGL.EGL_RED_SIZE, 8, EGL.EGL_GREEN_SIZE, 8,
            EGL.EGL_BLUE_SIZE, 8, EGL.EGL_ALPHA_SIZE, 8, EGL.EGL_NONE,
        )
        config, count = EGL.EGLConfig(), ctypes.c_int()
        EGL.eglChooseConfig(self.display, attributes, config, 1, count)
        if not count.value:
            raise RuntimeError("No EGL ES3 configuration")
        attributes = (ctypes.c_int * 3)(EGL.EGL_CONTEXT_CLIENT_VERSION, 3, EGL.EGL_NONE)
        self.context = EGL.eglCreateContext(self.display, config, EGL.EGL_NO_CONTEXT, attributes)
        EGL.eglMakeCurrent(self.display, EGL.EGL_NO_SURFACE, EGL.EGL_NO_SURFACE, self.context)
        self.vao = GL.glGenVertexArrays(1)
        GL.glBindVertexArray(self.vao)
        GL.glDisable(GL.GL_BLEND)
        GL.glDisable(GL.GL_DITHER)
        print("Renderer:", GL.glGetString(GL.GL_RENDERER).decode())
        return self

    def __exit__(self, *args):
        GL.glDeleteVertexArrays(1, [self.vao])
        EGL.eglMakeCurrent(self.display, EGL.EGL_NO_SURFACE, EGL.EGL_NO_SURFACE, EGL.EGL_NO_CONTEXT)
        EGL.eglDestroyContext(self.display, self.context)
        EGL.eglTerminate(self.display)


def uniform(program, name, value):
    location = GL.glGetUniformLocation(program, name)
    if location < 0:
        return
    if isinstance(value, int):
        GL.glUniform1i(location, value)
    elif isinstance(value, tuple):
        getattr(GL, f"glUniform{len(value)}f")(location, *value)
    else:
        GL.glUniform1f(location, value)


class Renderer:
    def __init__(self, path):
        sources = dict(re.findall(r'\{"([^"\n]+)", R"GLSL\((.*?)\)GLSL"\}', path.read_text(), re.S))
        glass = sources["liquidglass.frag"]
        marker = "vec2 baseOffset = inwardDir * refractionMag / fullSize;"
        if glass.count(marker) != 1:
            raise RuntimeError("Cannot instrument refraction output")
        diagnostic = glass.replace(marker, marker + "\nfragColor = vec4(baseOffset * fullSize, -cornerSdf, 1.0); return;")
        chroma_marker = "vec2 offsetB = baseOffset * (1.0 + chromaSpread);"
        if glass.count(chroma_marker) != 1:
            raise RuntimeError("Cannot instrument chromatic displacement")
        dispersion = glass.replace(chroma_marker, chroma_marker + "\nfragColor = vec4(offsetR * fullSize, offsetB * fullSize); return;")
        self.programs = {}
        for name, source in {"contour": sources["contour.frag"], "glass": glass,
                             "diagnostic": diagnostic, "dispersion": dispersion}.items():
            self.programs[name] = compileProgram(
                compileShader(VERTEX, GL.GL_VERTEX_SHADER),
                compileShader(source, GL.GL_FRAGMENT_SHADER),
            )
        self.scalar = GL.glGetUniformLocation(self.programs["contour"], "distanceLimit") >= 0

    def close(self):
        for program in self.programs.values():
            GL.glDeleteProgram(program)

    def render(self, mask, background, scale, *, material=False, contour=True, strength=2.2,
               material_threshold=0.15):
        height, width = mask.shape[:2]
        fw, fh = max(1, width // 2), max(1, height // 2)
        textures, framebuffers = [], []

        def texture(w, h, data=None, framebuffer=False):
            tid = GL.glGenTextures(1)
            textures.append(tid)
            GL.glBindTexture(GL.GL_TEXTURE_2D, tid)
            for parameter in (GL.GL_TEXTURE_MIN_FILTER, GL.GL_TEXTURE_MAG_FILTER):
                GL.glTexParameteri(GL.GL_TEXTURE_2D, parameter, GL.GL_LINEAR)
            for parameter in (GL.GL_TEXTURE_WRAP_S, GL.GL_TEXTURE_WRAP_T):
                GL.glTexParameteri(GL.GL_TEXTURE_2D, parameter, GL.GL_CLAMP_TO_EDGE)
            GL.glTexImage2D(GL.GL_TEXTURE_2D, 0, GL.GL_RGBA16F, w, h, 0, GL.GL_RGBA, GL.GL_FLOAT, data)
            if not framebuffer:
                return tid
            fid = GL.glGenFramebuffers(1)
            framebuffers.append(fid)
            GL.glBindFramebuffer(GL.GL_FRAMEBUFFER, fid)
            GL.glFramebufferTexture2D(GL.GL_FRAMEBUFFER, GL.GL_COLOR_ATTACHMENT0, GL.GL_TEXTURE_2D, tid, 0)
            if GL.glCheckFramebufferStatus(GL.GL_FRAMEBUFFER) != GL.GL_FRAMEBUFFER_COMPLETE:
                raise RuntimeError("Incomplete RGBA16F framebuffer")
            return tid, fid

        def bind(unit, tid):
            GL.glActiveTexture(GL.GL_TEXTURE0 + unit)
            GL.glBindTexture(GL.GL_TEXTURE_2D, tid)

        try:
            mask_texture = texture(width, height, mask)
            background_texture = texture(width, height, background)
            material_texture = texture(1, 1, np.array([[[0.25, 0.45, 0.65, 1.0]]], np.float32))
            fields = [texture(fw, fh, framebuffer=True) for _ in range(2)]
            _, target = texture(width, height, framebuffer=True)
            program = self.programs["contour"]
            GL.glUseProgram(program)
            limit = 20.0 * scale * 3.5 + 4.0
            for name, value in {
                "tex": 0, "threshold": 0.025, "fieldSize": (fw, fh),
                "fieldPixelSize": (width / fw, height / fh), "distanceLimit": limit,
            }.items():
                uniform(program, name, value)
            first_step = 16
            if self.scalar:
                first_step = 1
                while 2 * first_step * min(width / fw, height / fh) < limit:
                    first_step *= 2
            steps = [0]
            while first_step >= 1:
                steps.append(first_step)
                first_step //= 2
            steps.append(1)
            GL.glViewport(0, 0, fw, fh)
            current = mask_texture
            for i, step in enumerate(steps):
                tid, fid = fields[i % 2]
                GL.glBindFramebuffer(GL.GL_FRAMEBUFFER, fid)
                bind(0, current)
                uniform(program, "jumpStep", step)
                GL.glDrawArrays(GL.GL_TRIANGLE_STRIP, 0, 4)
                current = tid

            GL.glViewport(0, 0, width, height)
            GL.glBindFramebuffer(GL.GL_FRAMEBUFFER, target)
            for unit, tid in enumerate((background_texture, mask_texture, current, material_texture)):
                bind(unit, tid)
            values = {
                "tex": 0, "maskTex": 1, "contourTex": 2, "materialTex": 3,
                "fullSize": (width, height), "radius": 24.0 * scale, "roundingPower": 2.0,
                "maskUVOffset": (0, 0), "maskUVScale": (1, 1), "uvPadding": (0, 0),
                "useMask": 1, "useContour": int(contour), "maskMode": 0, "maskAlphaThreshold": 0.025,
                "contourWidth": 20.0 * scale, "refractionStrength": strength, "chromaticAberration": 0.65,
                "edgeThickness": 0.08, "glassOpacity": 1.0, "brightness": 1.0, "contrast": 1.0,
                "saturation": 1.0, "useMaterial": int(material), "materialRegionRectCount": 1,
                "materialAlphaThreshold": material_threshold, "materialAlphaFeather": 0.015,
                "materialRegionRects[0]": (100 * scale, 140 * scale, 340 * scale, 220 * scale),
            }
            results = {}
            for name in ("diagnostic", "dispersion", "glass"):
                program = self.programs[name]
                GL.glUseProgram(program)
                for key, value in values.items():
                    uniform(program, key, value)
                GL.glClearColor(0, 0, 0, 0)
                GL.glClear(GL.GL_COLOR_BUFFER_BIT)
                GL.glDrawArrays(GL.GL_TRIANGLE_STRIP, 0, 4)
                pixels = GL.glReadPixels(0, 0, width, height, GL.GL_RGBA, GL.GL_FLOAT)
                results[name] = np.frombuffer(pixels, np.float32).reshape(height, width, 4).copy()
            return results
        finally:
            GL.glDeleteFramebuffers(len(framebuffers), framebuffers)
            GL.glDeleteTextures(textures)


def scene(kind, scale, odd=False):
    width, height = round(640 * scale) + int(odd), round(480 * scale) + int(odd)
    y, x = np.mgrid[:height, :width].astype(np.float32)
    x, y = (x + 0.5) / scale, (y + 0.5) / scale

    def rounded_box(left, top, w, h, radius):
        dx, dy = np.abs(x - left - w / 2) - w / 2 + radius, np.abs(y - top - h / 2) - h / 2 + radius
        return np.hypot(np.maximum(dx, 0), np.maximum(dy, 0)) + np.minimum(np.maximum(dx, dy), 0) - radius

    if kind == "bar":
        sdf = x - 60
    elif kind == "strip":
        sdf = np.maximum(100 - x, x - 160)
    elif kind == "thin":
        sdf = np.maximum(100 - x, x - 110)
    elif kind == "rounded":
        sdf = rounded_box(100, 100, 300, 260, 24)
    elif kind == "joined":
        sdf = np.minimum(x - 60, rounded_box(55, 85, 435, 310, 24))
        sdf = np.minimum(sdf, np.minimum.reduce([y - 10, height / scale - 10 - y, width / scale - 10 - x]))
    elif kind == "full":
        sdf = np.full_like(x, -1000)
    elif kind == "empty":
        sdf = np.full_like(x, 1000)
    else:
        raise ValueError(kind)
    alpha = np.clip(0.5 - sdf * scale, 0, 1) * 0.14
    mask = np.empty((height, width, 4), np.float32)
    mask[:, :, :3] = alpha[:, :, None] * np.array([0.12, 0.14, 0.18], np.float32)
    mask[:, :, 3] = alpha
    background = np.ones_like(mask)
    background[:, :, 0] = 0.25 + 0.22 * np.sin(x / 45 + y / 100)
    background[:, :, 1] = 0.4 + 0.27 * np.sin(x / 100 - y / 70)
    background[:, :, 2] = 0.55 + 0.24 * np.sin(x / 80 + y / 110)
    grid = (np.mod(x, 24) < 1) | (np.mod(y, 24) < 1)
    background[grid, :3] *= 0.6
    return mask, background, x, y, sdf


def check(renderer, output_dir=None):
    metrics = []
    failures = []
    for scale, odd in ((1.0, False), (1.6, True), (2.0, False), (3.0, True)):
        for kind in ("bar", "strip", "thin", "rounded", "joined", "full", "empty"):
            mask, background, x, y, sdf = scene(kind, scale, odd)
            result = renderer.render(mask, background, scale)
            diagnostic = result["diagnostic"]
            offset = np.linalg.norm(diagnostic[:, :, :2], axis=2) / scale
            inside = sdf < -1
            flat = sdf < -62
            name = f"{kind}@{scale:g}"
            flat_max = float(offset[flat].max(initial=0))
            max_offset = float(offset.max())
            if flat_max > 0.03:
                failures.append(f"{name}: interior bends by {flat_max:.3f} logical pixels")
            if max_offset > 2.2 * 20 * 0.95 + 0.03:
                failures.append(f"{name}: unbounded refraction {max_offset:.3f}")
            if not np.isfinite(diagnostic).all() or not np.isfinite(result["glass"]).all():
                failures.append(f"{name}: non-finite output")
            if kind in ("bar", "strip", "rounded"):
                depth = diagnostic[:, :, 2] / scale
                near = inside & (sdf > -18)
                error = float(np.abs(depth[near] + sdf[near]).max(initial=0))
                if error > 2.5:
                    failures.append(f"{name}: false contour, distance error {error:.3f}")
            else:
                error = 0.0
            response_error, chroma_error = 0.0, 0.0
            if kind == "bar":
                row = round(240 * scale)
                depth = diagnostic[row, :, 2] / scale
                band = (x[row] > 30) & (x[row] < 54)
                # Compatibility contract: preserve the original 2.2 / 0.65
                # preset's displacement and color separation on a straight
                # edge. Seam removal must not silently weaken these controls.
                expected = 2.2 * 20 * 0.95 * np.exp(-depth[band] / 20)
                response_error = float(np.max(np.abs(offset[row, band] / expected - 1)))
                channels = result["dispersion"][row, band] / scale
                spread = np.linalg.norm(channels[:, 2:] - channels[:, :2], axis=1)
                chroma_error = float(np.max(np.abs(spread / (expected * 2 * 0.65 * 0.35) - 1)))
                if response_error > 0.05 or chroma_error > 0.05:
                    failures.append(f"{name}: preset response changed (refraction {response_error:.3f}, dispersion {chroma_error:.3f})")
            if kind in ("strip", "thin"):
                center = 130 if kind == "strip" else 105
                medial = (np.abs(x - center) < 1) & (y > 100) & (y < 300)
                distance_error = np.abs(diagnostic[:, :, 2] / scale + sdf)
                if distance_error[medial].max() > 1.5:
                    failures.append(f"{name}: opposing edges created a false center contour")
            if kind == "empty" and np.any(result["glass"]):
                failures.append(f"{name}: glass outside mask")
            metrics.append({"scene": name, "interior_offset": round(flat_max, 4),
                            "max_offset": round(max_offset, 4), "distance_error": round(error, 4),
                            "refraction_response_error": round(response_error, 4),
                            "dispersion_response_error": round(chroma_error, 4)})
            if output_dir and scale == 1:
                from PIL import Image
                output_dir.mkdir(parents=True, exist_ok=True)
                color = result["glass"]
                image = color[:, :, :3] + background[:, :, :3] * (1 - color[:, :, 3:4])
                Image.fromarray(np.uint8(np.clip(image, 0, 1) * 255)).save(output_dir / f"{kind}.png")
    return metrics, failures


def check_compositing(renderer):
    failures = []
    mask, background, x, y, _ = scene("full", 1.0)
    # Material belongs to a card above the drawer's 0.14-alpha background.
    mask *= 3
    material = renderer.render(mask, background, 1.0, material=True)["glass"]
    expected = mask[240, 240, :3] + np.array([0.25, 0.45, 0.65]) * (1 - mask[240, 240, 3])
    if np.max(np.abs(material[240, 240, :3] - expected)) > 0.002:
        failures.append("material: Gaussian sample was not composited under the surface")
    if np.max(np.abs(material[240, 500, :3] - material[240, 240, :3])) < 0.05:
        failures.append("material: sample escaped its requested region")
    mask[:, :, :] = [0.9, 0.3, 0.12, 1.0]
    opaque = renderer.render(mask, background, 1.0, material=True)["glass"]
    if np.max(np.abs(opaque - mask)) > 0.002:
        failures.append("opaque: glass changed opaque foreground content")
    mask, background, x, y, _ = scene("bar", 1.0)
    disabled = renderer.render(mask, background, 1.0, strength=0.0)["diagnostic"]
    if np.any(disabled[:, :, :2]):
        failures.append("disabled: zero strength still refracts")
    low = renderer.render(mask, background, 1.0, strength=1.1)["diagnostic"]
    high = renderer.render(mask, background, 1.0, strength=2.2)["diagnostic"]
    if np.max(np.abs(high[:, :, :2] - low[:, :, :2] * 2)) > 0.02:
        failures.append("preset strength: doubling the configured value no longer doubles displacement")

    # A moving edge must not snap as it crosses the half-resolution seed grid.
    scale = 1.6
    mask, background, x, y, _ = scene("bar", scale, odd=True)
    region = (x > 40) & (x < 59) & (y > 50) & (y < 430)
    previous = None
    max_change = 0.0
    for shift in np.linspace(0, 2, 17):
        mask[:, :, 3] = np.clip(0.5 - (x - 60 - shift) * scale, 0, 1) * 0.14
        mask[:, :, :3] = mask[:, :, 3:4] * np.array([0.12, 0.14, 0.18])
        offset = renderer.render(mask, background, scale)["diagnostic"][:, :, :2] / scale
        if previous is not None:
            max_change = max(max_change, float(np.linalg.norm(offset[region] - previous[region], axis=1).max()))
        previous = offset
    if max_change > 0.5:
        failures.append(f"animation: subpixel movement snaps by {max_change:.3f} logical pixels")
    return {"animation_max_step": round(max_change, 4)}, failures


def check_material_clipping(renderer, threshold=0.15):
    failures = []
    max_leak = 0.0
    for scale in (1.0, 1.6, 2.0):
        for radius in (12.0, 24.0, 48.0):
            mask, background, x, y, _ = scene("full", scale)
            dx, dy = np.abs(x - 270) - 170 + radius, np.abs(y - 250) - 110 + radius
            sdf = np.hypot(np.maximum(dx, 0), np.maximum(dy, 0)) + np.minimum(np.maximum(dx, dy), 0) - radius
            card_alpha = np.clip(0.5 - sdf * scale, 0, 1) * 0.32
            mask[:, :, :3] = mask[:, :, :3] * (1 - card_alpha[:, :, None]) + card_alpha[:, :, None] * np.array([0.6, 0.62, 0.65])
            mask[:, :, 3] += card_alpha * (1 - mask[:, :, 3])
            # The real layer buffer quantizes the drawer alpha to 36/255.
            mask = np.round(mask * 255) / 255
            plain = renderer.render(mask, background, scale)["glass"]
            material = renderer.render(mask, background, scale, material=True,
                                       material_threshold=threshold)["glass"]
            outside_card = sdf > 1 / scale
            leak = float(np.max(np.abs(material[outside_card] - plain[outside_card])))
            max_leak = max(max_leak, leak)
            if leak > 0.002:
                failures.append(f"material@{scale:g}/r{radius:g}: blur escaped the rounded card ({leak:.4f})")
            interior = sdf < -1 / scale
            expected = mask[:, :, :3] + np.array([0.25, 0.45, 0.65]) * (1 - mask[:, :, 3:4])
            if np.max(np.abs(material[interior, :3] - expected[interior])) > 0.002:
                failures.append(f"material@{scale:g}/r{radius:g}: clipping changed the card's interior blur")
    return {"rounded_card_cases": 9, "max_outside_card_leak": round(max_leak, 5)}, failures


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("shader_header", type=Path)
    parser.add_argument("--baseline", type=Path)
    parser.add_argument("--output-dir", type=Path)
    args = parser.parse_args()
    report = {}
    with Context():
        for label, path in (("baseline", args.baseline), ("candidate", args.shader_header)):
            if path is None:
                continue
            renderer = Renderer(path)
            try:
                output = args.output_dir / label if args.output_dir else None
                metrics, failures = check(renderer, output)
                compositing, extra_failures = check_compositing(renderer)
                failures.extend(extra_failures)
                clipping, clipping_failures = check_material_clipping(renderer)
                failures.extend(clipping_failures)
                compositing.update(clipping)
                report[label] = {"metrics": metrics, "compositing": compositing, "failures": failures}
                print(f"{label}: {len(metrics)} scenes, {len(failures)} failures")
                for failure in failures:
                    print(" ", failure)
            finally:
                renderer.close()
    if args.output_dir:
        args.output_dir.mkdir(parents=True, exist_ok=True)
        (args.output_dir / "report.json").write_text(json.dumps(report, indent=2) + "\n")
    if report["candidate"]["failures"]:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
