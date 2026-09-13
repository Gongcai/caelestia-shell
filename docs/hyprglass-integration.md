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

Launchpad intentionally keeps Gaussian blur, as requested. It and the thin
monitor frame remain in `caelestia-drawers`, which is excluded from hyprglass.
The bar hides on an output while that output's Launchpad is open.

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
mask of `caelestia-drawers`; the contour normal drives refraction at every
outer boundary, including joins between dashboard, sidebar, and the frame.
The effect does not use CPU pixel readback or extra Wayland surfaces.

The reproducible plugin patch is
[patches/hyprglass-unified-contour.patch](patches/hyprglass-unified-contour.patch).
It supersedes the older rounding-only patch when applied to the pinned upstream
source.

The current visual tune is intentionally strong enough to make a changing
wallpaper visibly bend at panel edges:

```lua
refraction_strength = 2.2
chromatic_aberration = 0.65
edge_thickness = 0.08
-- compiled contour width: 20 logical pixels
-- compiled contour refraction multiplier: 0.95
```

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
material_alpha_threshold = 0.06,
```

`Region.item` observes the target's own geometry but does not observe ancestor
movement or transforms. Publishing it directly left card regions at their
opening-animation coordinates until a later layout update. The shell now maps
card bounds to the window in `QQuickWindow.afterAnimating`, before polish and
commit. Integer region properties change only when those bounds change; there
is no idle animation timer or per-frame region allocation. Hidden cards publish
empty bounds, and registration includes cards before their first layout.

The unified contour patch includes the material sampler. The current installed
`hyprglass.so` symlink targets `hyprglass-material-blur.so`. Runtime validation
confirmed successful QML reload; the visible delay fix was confirmed on the
Dashboard. The current material shader supports up to 32 region rectangles.

### Paths

- Source: `~/.local/src/hyprglass`, upstream commit
  `77636c5711ed572ca199a84d06146ccac0951786` (v0.8.0).
- Current source patch: [patches/hyprglass-unified-contour.patch](patches/hyprglass-unified-contour.patch).
- Historical rounding-only patch: [patches/hyprglass-layer-rounding.patch](patches/hyprglass-layer-rounding.patch).
- Built library: `~/.local/lib/hyprland/hyprglass.so`.
- Effect settings: `~/.config/hypr/hyprglass.lua`, included by `hyprland.lua`.
- Startup loader: `~/.local/bin/caelestia-hyprglass`.

The patch adds a per-namespace `rounding` option to `hyprglass.layer`. It accepts
a finite, non-negative logical radius and scales it for the output. The local
configuration uses 24, matching `Tokens.rounding.extraLarge`. Keep these values
in sync if the shell radius changes.

The plugin is restricted to the namespaces above and the tagged Nexus windows;
other application windows and `caelestia-drawers` are excluded. Configuration reload reapplies the custom
preset and namespace options. Live sampling has no 30 FPS cap. The rules in
`hyprland.lua` select top, bottom, right, or left entry animations by panel.

## Build and Recovery

This build targets the installed Hyprland 0.56.2 headers and ABI. Rebuild against
matching headers after updating Hyprland. Do not bypass the plugin ABI check.
Apply the unified contour patch to the pinned upstream source, then build with
`make -j2`.
Unload the plugin before replacing its installed library, then run the startup
loader to load it and reload the configuration.

The local build is linked with `-Wl,-z,nodelete`. Hyprland may retain a window
decoration's type-erased deleter until a closing window finishes its update;
keeping the plugin mapping resident prevents that deferred callback from
landing in an unloaded or subsequently replaced library. Do not overwrite the
installed `.so` while it is loaded. Build to a temporary path, unload only when
the compositor is intentionally being stopped, then replace it before the next
Hyprland start. The previous compositor crash occurred after repeated hot
reloads had left such a callback pointing at a reused plugin mapping.

For immediate fallback to ordinary Hyprland blur:

```sh
hyprctl plugin unload "$HOME/.local/lib/hyprland/hyprglass.so"
```

`shell-switch caelestia` starts a missing instance but does not restart an
existing instance. For a shell restart, run `qs -c caelestia kill`, wait for it
to exit, then run `shell-switch caelestia`.

## Verification

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

QML lint completed with metadata warnings, including the native window margins
group and existing property typing warnings. Existing launchpad color and
Dashboard GitHub teardown warnings remain. Rotated monitors, nested tray menus,
bar drag gestures, detached settings input, and the full recording
workflow still need interactive regression coverage.

The fourth pass reduces panel corner radii and removes the one-pixel QML border
from shared glass surfaces. This lets the compositor sample the shared frame
behind adjoining panels, so dashboard, sidebar and control-center edges read as
one continuous material while outer corners remain rounded.
