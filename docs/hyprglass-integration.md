# Local Hyprglass Integration

The current shell renders each monitor's dashboard, sidebars, control center,
screen frame, and popouts in one full-output `caelestia-drawers` layer. Its
alpha mask is used as a contour field, so adjacent panel shapes merge into one
continuous liquid-glass boundary while controls remain in the same native
surface as their background. Launchpad remains a separate Gaussian-blurred
surface by design.

The namespace list below describes the earlier individually mapped panel
surfaces. It remains useful when checking older revisions, but new drawer work
must target `caelestia-drawers`.

## Backdrop Selection

The active compositor effect is selected in `~/.config/hypr/hyprglass.lua`:

```lua
local backend = "liquid" -- "liquid" or "hyprland"
```

`liquid` enables Hyprglass refraction, contour merging and glass grain. It also
turns off Hyprland's native blur rules for the Caelestia surfaces. `hyprland`
disables Hyprglass layer processing and enables native Gaussian blur for the
panel, drawer and frame namespaces. Reload Hyprland after changing the value.
The launchpad remains Gaussian blurred in both modes.

Game mode temporarily disables both Hyprland blur and Hyprglass processing.
It turns off `plugin:hyprglass:enabled` and `plugin:hyprglass:layers:enabled`,
and adds a temporary `hyprglass_disabled` window rule so explicit opt-ins such
as Nexus also stop rendering glass. The rule covers windows opened while game
mode is active. Hyprland config reloads reapply these overrides until game mode
is disabled; exiting reloads the configured backend, removes the rule and
cleans up its lingering dynamic tags while preserving existing window opt-outs.

Within the shell, game mode uses opaque panel backgrounds without changing the
saved transparency settings. Desktop glass capture, material blur regions,
lock-screen refraction and blur, visualiser blur, workspace/logo blur, and Qt
shadows/glows are suspended. Hidden lock glass releases its source capture,
and material regions stop tracking per-frame geometry until effects resume.

The following namespaces use the local glass preset:

| Namespace suffix (after `caelestia-`) | Content |
| --- | --- |
| `control-center` | Control center and recorder page |
| `dashboard` | Dashboard tabs |
| `launcher` | Search launcher |
| `quickpanel` | Clipboard |
| `sidebar` | Notification history |
| `session` | Session actions |
| `osd` | Volume and brightness |
| `notifications` | Popup notification stack |
| `lyrics` | Compact and expanded lyrics |
| `popout` | Bar popouts and detached settings/window information |
| `bar` | Vertical bar, including workspace and tray controls |
| `toast` | One independent surface per toast |

Launchpad intentionally keeps Gaussian blur in its separate
`caelestia-launchpad` surface, which is excluded from Hyprglass. The thin
monitor frame belongs to the unified `caelestia-drawers` contour.
The bar hides on an output while that output's Launchpad is open.

Launchpad creates its application grid only when its own layer window is
visible and has a nonzero size. Closing releases the content after the fade;
visibility changes are deferred to avoid re-entering the binding during
teardown. The wrapper owns the reveal animation, so late desktop-entry
discovery and search updates cannot leave individual tiles in an interrupted
opacity/scale transition. Selection uses `Colours.selectedSurface`, and
delegates tolerate entries being removed during a model update.

Standalone Nexus windows opt in using both `^org.quickshell$` class and
`^Nexus .*` title rules. They receive `hyprglass_enabled` and
`hyprglass_preset_caelestia` tags; global application glass stays disabled.
Nexus uses a 0.55 surface tint and toasts use 0.6 to keep text readable. Other
native panels retain the existing 0.14 tint. Disabling transparency restores
opaque backgrounds.

Wrappers remain as layout placeholders for panel coordination and hover
triggers. Their QML content renders inside the new windows. Loader-backed
windows wait for loaded content before mapping. The notification stack maps
when popup data arrives, allowing its virtualized list to calculate its height.

The old blob backgrounds and input regions for migrated panels were removed.
The focus grab includes their new windows; keyboard input belongs to each
interactive panel. Hover exit waits 120 ms to allow crossing from the bar or
screen edge into a panel. The old wrapper offset animation only reserves layout
space; it no longer moves the rendered content separately from the glass.
The bar routes hover, drag and wheel events inside its own surface. Hover
updates and window visibility are deferred to the end of the event turn so
mapping and layout changes cannot recursively change visibility. Toasts retain
their existing model locks, timeout, click dismissal and stacking behavior.

## Lock Screen

The lock surface is still `WlSessionLockSurface`, with the existing PAM flow.
It is not a layer-shell window and cannot use hyprglass's layer hook.
`BackdropGlass.qml` instead samples the existing lock wallpaper or cached
pre-lock screencopy inside the lock surface. Its compiled Qt shader uses a
rounded-rectangle SDF normal for edge refraction, subtle chromatic separation
and a highlight. Sample coordinates follow the lock panel's rotation and scale.
The surrounding lock background retains its Gaussian blur. This does not
create a live view of unlocked applications or a separate backdrop window.

The shader belongs to the `Caelestia.Blobs` resource library. After a source
update, rebuild and install that module before restarting the shell:

```sh
cmake --build build --target caelestia-blobsplugin -j2
qs -c caelestia kill
cmake --install build/plugin/src/Caelestia/Blobs
shell-switch caelestia
```

Shader errors fall back to the opaque lock background. Turning transparency
off also restores the original opaque panel.

## Why the Previous Region Approach Failed

Hyprglass v0.8.0 uses protocol regions only to clip the shader. Its signed distance
field and refraction direction still use the entire layer surface dimensions.
A fullscreen surface therefore cannot provide independent panel edges this way.
Rounded regions also exceed the plugin's 16-rectangle limit, at which point it
replaces them with their bounding rectangle. Animated QML geometry and protocol
regions can consequently expose a displaced rectangular effect.

The replacement uses the panel-sized surface's alpha mask and an explicit
corner radius. It does not publish control-center cards as fullscreen blur
regions. Internal cards are ordinary translucent controls, not separate glass
surfaces. Notifications currently share one glass surface for their popup stack;
individual notification cards are not separate refracting surfaces.

## Unified Surface Contour

The current implementation replaces the panel-sized assumption above for
drawer content. It builds a half-resolution jump-flood contour from the alpha
mask of `caelestia-drawers`; a signed distance gradient drives refraction at
each visible boundary, including joins between dashboard, sidebar, and the
frame. The effect does not use CPU pixel readback or extra Wayland surfaces.

The reproducible plugin patch is
[patches/hyprglass-unified-contour.patch](patches/hyprglass-unified-contour.patch).
It supersedes the older rounding-only patch when applied to the pinned upstream
source.

The local preset retains these values:

```lua
refraction_strength = 2.2
chromatic_aberration = 0.65
-- candidate plugin: noise_strength = 0.016
edge_thickness = 0.08
-- compiled contour width: 20 logical pixels
```

The previous contour implementation produced narrow vertical stripes inside
the bar and diagonal creases at drawer corners. It bilinearly interpolated
nearest-boundary vectors before taking their length. Where different edges
were equally close, those vectors canceled and created false zero-distance
edges. Normalizing the resulting gradient amplified small direction changes.
Treating pixels beyond the output as transparent added another, artificial
edge along screen-attached bars. The old exponential shoulder also retained
refraction beyond the useful range of its bounded distance field.

The smooth-contour patch addresses those causes together:

- Each jump-flood texel retains its nearest-boundary vector for propagation
  and stores a signed scalar distance in physical pixels in the fourth
  channel. Filtering that distance cannot cancel opposing vectors. The sign
  belongs to the destination pixel, including pixels outside the glass, so
  the normal stencil remains continuous across the actual boundary.
- Seeding skips samples outside the output and interpolates the alpha
  threshold crossing using half-field-texel probes, approximately one native
  pixel apart. This improves subpixel motion without increasing buffer size.
  Grid dimensions and pixel spacing are explicit, including odd-sized buffers
  at fractional output scales.
- A Sobel stencil smooths the gradient. Its magnitude is only capped, never
  amplified back to unit length where opposing edges cancel. Flat interiors
  skip the stencil entirely.
- Refraction retains the original linear strength response and exponential
  falloff: `strength * contourWidth * 0.95 * exp(-depth / contourWidth)`.
  Chromatic spread remains `chromatic_aberration * 0.35`. The local preset
  therefore retains its nominal 41.8-logical-pixel edge displacement. An
  earlier correction capped it near 6.5 pixels despite unchanged Lua values;
  that cap has been removed.
- The original falloff is unchanged through 40 logical pixels. A quintic
  taper ends it smoothly between 40 and 60 pixels, before the distance field
  runs out. The normal stencil is skipped beyond that range.
- The jump range covers the falloff and normal stencil at the output scale.
  It retains two half-resolution buffers, descending power-of-two steps and
  an additional unit step; higher scales add only the steps they need.

The window and separate rounded-panel paths retain their existing optics.
Semantic card blur and premultiplied foreground compositing remain separate
from the outer contour calculation.

`noise_strength` adds a subtle, stable blue-noise-style grain to the sampled
glass backdrop. It is generated from physical pixel coordinates in the fragment
shader, so it does not shimmer during panel animations, and it is composited
before the layer surface content so text and icons remain clean. The value is
clamped to `0..0.08`; `0` disables the effect. This is a procedural
blue-noise-style pattern rather than a sampled blue-noise texture.

Grain remains disabled in the local Lua preset; it is independent of the
contour correction. `noise_strength = 0.016` can be enabled after starting a
session with the new library if the grain is desired.

The width is scaled by the output scale before rendering. Keep the source patch
and `~/.config/hypr/hyprglass.lua` values together when comparing revisions.

## Installed Files

### Internal Card Blur

Control Center cards and the main Dashboard cards opt into a stronger Gaussian
background sample through `MaterialSurface` (`StyledRect.materialBlur` for
rectangle controls). `MaterialBlurRegions` publishes their window-local bounds
through `BackgroundEffect.blurRegion`. Hyprglass retains `mask_mode = "alpha"`
for the unified outer contour and uses these protocol regions only to select
the material sample. The rendered surface alpha gates that sample at rounded
card edges. This samples wallpaper/application content in the compositor;
it does not blur the control's text or icons with a Qt effect.

The additional options for `hg.layer("caelestia-drawers", {...})` are:

```lua
material_blur_strength = 0.85,
material_blur_iterations = 1,
material_alpha_threshold = 0.15,
```

The threshold must exceed the unified drawer background's 0.14 opacity
(`ContentWindow.qml`), which the layer buffer quantizes to 36/255. The former
0.06 value also selected that background outside each card's rounded corners,
exposing the rectangular protocol region as a square blur patch. At 0.15 only
the additional card coverage selects the stronger sample; fully covered card
pixels retain their existing blur. Keep this threshold above the base opacity
if the shared drawer background is changed. This is a Lua preset correction
and takes effect with `hyprctl reload`; it does not need a new plugin library.

`Region.item` observes the target's own geometry but does not observe ancestor
movement or transforms. Publishing it directly left card regions at their
opening-animation coordinates until a later layout update. The shell now maps
card bounds to the window in `QQuickWindow.afterAnimating`, before polish and
commit. Integer region properties change only when those bounds change; there
is no idle animation timer or per-frame region allocation. Hidden cards publish
empty bounds, and registration includes cards before their first layout.

The unified contour patch includes the material sampler. Runtime validation of
the material implementation confirmed successful QML reload; the visible
delay fix was confirmed on the Dashboard. The current material shader supports
up to 32 region rectangles.

### Paths

- Base checkout: `~/.local/src/hyprglass`, upstream commit
  `77636c5711ed572ca199a84d06146ccac0951786` (v0.8.0). Apply the current patch to
  a clean checkout or worktree of this commit; the base checkout's local edits
  do not include every change in the current integration patch.
- Current source patch: [patches/hyprglass-unified-contour.patch](patches/hyprglass-unified-contour.patch).
- The patch also carries the procedural `noise_strength` preset parameter and
  shader grain stage described above.
- Historical rounding-only patch: [patches/hyprglass-layer-rounding.patch](patches/hyprglass-layer-rounding.patch).
- Built library: `~/.local/lib/hyprland/hyprglass.so`.
- Installed contour/optics library:
  `~/.local/lib/hyprland/hyprglass-contour-optics-623a1d337811.so`.
  The startup symlink points to this file, and the current Hyprland session
  has it mapped after a normal login. Future library replacements likewise
  require a normal compositor restart; restarting Quickshell or reloading
  Lua alone does not replace the shader. The previous libraries are retained.
- Effect settings: `~/.config/hypr/hyprglass.lua`, included by `hyprland.lua`.
- Startup loader: `~/.local/bin/caelestia-hyprglass`.

The patch adds a per-namespace `rounding` option to `hyprglass.layer`. It accepts
a finite, non-negative logical radius and scales it for the output. The local
configuration uses 24, matching `Tokens.rounding.extraLarge`. Keep these values
in sync if the shell radius changes.

The plugin is restricted to `caelestia-drawers`, the panel namespaces above,
and the tagged Nexus windows; other application windows are excluded.
Configuration reload reapplies the custom preset and namespace options. Live
sampling has no 30 FPS cap. The rules in `hyprland.lua` select top, bottom,
right, or left entry animations by panel.

## Build and Recovery

This build targets the installed Hyprland 0.56.2 headers and ABI. Rebuild against
matching headers after updating Hyprland. Do not bypass the plugin ABI check.
Apply the unified contour patch to a clean copy of the pinned upstream source,
then build with `make -j2`. Install to a new, uniquely named library and
atomically point the startup symlink at it for the next Hyprland session.
Replacing a symlink does not modify the old library inode or the current
process's mappings. Keep that old library until the session has exited.

The local build is linked with `-Wl,-z,nodelete`. Hyprland may retain a window
decoration's type-erased deleter until a closing window finishes its update;
keeping the plugin mapping resident prevents that deferred callback from
landing in an unloaded or subsequently replaced library. Do not overwrite the
installed `.so` while it is loaded. Build to a temporary path and activate the
new library on a normal compositor restart. The previous compositor crash occurred after repeated hot
reloads had left such a callback pointing at a reused plugin mapping.

For immediate fallback to ordinary Hyprland blur:

```sh
hyprctl plugin unload "$HOME/.local/lib/hyprland/hyprglass.so"
```

`shell-switch caelestia` starts a missing instance but does not restart an
existing instance. For a shell restart, run `qs -c caelestia kill`, wait for it
to exit, then run `shell-switch caelestia`.

## Verification

The smooth-contour update compiles against the installed Hyprland 0.56.2 ABI.
The regenerated patch applies cleanly to the pinned upstream commit and
reproduces all 13 compiled source files exactly. The live desktop was not
restarted or used to hot-load the candidate.

The standalone GPU regression renders the actual embedded GLSL through
surfaceless EGL, using the same half-resolution floating-point contour buffers
and jump sequence. It requires Python, NumPy and PyOpenGL; saving comparison
images also requires Pillow:

```sh
python3 scripts/check-hyprglass-contour.py /path/to/patched/hyprglass/src/Shaders.hpp \
  --output-dir /tmp/hyprglass-contour-check
```

Use `--baseline /path/to/previous/Shaders.hpp` to render a previous version
alongside it. Images and `report.json` are written below the output directory.
This test does not alter a running compositor.

On the NVIDIA RTX 4060, all 28 geometry/scale cases passed: attached bars,
detached and thin strips, rounded panels, joined drawers and frames, and
empty/full masks at 1x, 1.6x, 2x and 3x, including odd buffer sizes. Checks
cover false contours, flat interiors, finite output, transparent masks and
the original refraction/dispersion response on straight edges. The response
errors are below 0.5% across the tested scales. Additional checks passed for
material-region compositing, opaque foregrounds, zero refraction and linear
strength scaling. With the restored optical strength, the largest offset
step during a 0.125-logical-pixel edge movement at 1.6x is 0.430 logical
pixels. The previous capped version fails the new parameter-compatibility
checks. These are isolated rendering checks. The installed contour/optics
library has subsequently been activated through a normal Hyprland login.

The material clipping regression additionally composites rounded cards above
a 0.14-alpha drawer background, including 8-bit alpha quantization. Nine cases
cover 12-, 24- and 48-pixel radii at 1x, 1.6x and 2x. All nine expose corner
leakage at the former 0.06 threshold and pass at 0.15, with zero measured change
outside the rounded card and the original material sample inside it.

The following checks describe the earlier live panel/material integration:

The plugin compiled and loaded against the installed ABI. The modified shell
loaded successfully in a fresh process. Runtime screenshots and user feedback
confirmed visible liquid-glass refraction on the control center.

The additional panels were opened and checked with compositor geometry and
screenshots. Launcher and session Escape handling passed. The bar network
popout and OSD stayed open when the pointer crossed into their windows and
closed after leaving. A test notification mapped on both monitors and its
surfaces disappeared after expiration. Dashboard and sidebar were also checked
on the 1.6-scale eDP output. Hyprland reported no configuration errors.

The third batch was checked in a fresh process on both outputs: bar surfaces
are 60x1080 and 60x900 logical pixels, and individual toasts are 406x77. Toast
click dismissal removes both output copies, and timeout removes their surfaces.
Bar-to-network-popout hover, continued hover within the popout, and exit passed.
Native mouse input verified toast dismissal and bar wheel volume adjustment;
the original volume was restored after the check.
Nexus window tags and rendered refraction were checked. Launchpad retains its
Gaussian background, hides its output's bar and restores it after Escape.

The lock shader was captured with refraction enabled and disabled, with a
rotated/scaled panel, and at a smaller window size. Grid distortion stays at
the panel edge while the interior sample stays aligned to the background. A
real lock/unlock cycle through the existing IPC also passed and was captured;
the password authentication flow was not exercised.

The launchpad startup correction passes QML lint without warnings for all four
changed QML files. An isolated Wayland fixture exercised first opening, late
desktop-entry discovery, search clearing and interrupted close/reopen, hovering
20 tiles in each case and checking that every visited tile remains visible.
Escape also closed the window and released the grid. After restarting only
Quickshell, a cursor sweep across 50 visible tiles retained all icons and
labels in the live capture, with no launchpad errors or binding loops in the
new log. This does not reproduce the user's original first-login GPU state;
the complete cold-login scenario still needs confirmation on a normal login.

Earlier full-shell QML lint completed with metadata warnings, including the
native window margins group and existing property typing warnings. Dashboard
GitHub teardown warnings remain. Rotated monitors, nested tray menus,
bar drag gestures, detached settings input, and the full recording
workflow still need interactive regression coverage.

The fourth pass reduces panel corner radii and removes the one-pixel QML border
from shared glass surfaces. This lets the compositor sample the shared frame
behind adjoining panels, so dashboard, sidebar and control-center edges read as
one continuous material while outer corners remain rounded.
