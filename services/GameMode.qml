pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.services

Singleton {
    id: root

    property alias enabled: props.enabled
    property bool glassRestoreReady

    function setDynamicConfs(): void {
        Hypr.extras.applyOptions({
            "animations:enabled": false,
            "decoration:shadow:enabled": false,
            "decoration:blur:enabled": false,
            "general:gaps_in": 0,
            "general:gaps_out": 0,
            "general:border_size": 1,
            "decoration:rounding": 0,
            "general:allow_tearing": true
        });

        hyprglassProbe.running = true;
    }

    function disableGlass(): void {
        // Window tags override Hyprglass's global switch; the temporary rule
        // also covers windows opened while game mode is active.
        if (Hypr.usingLua) {
            Hypr.extras.message('eval local hg = hl.plugin and hl.plugin.hyprglass; if hg then hg.config({ enabled = false, layers = { enabled = false } }); hl.window_rule({ name = "caelestia-game-mode-no-glass", match = { class = ".*" }, tag = "+hyprglass_disabled" }); end');
        } else {
            Hypr.extras.batchMessage(["keyword plugin:hyprglass:enabled false", "keyword plugin:hyprglass:layers:enabled false", "keyword windowrule tag +hyprglass_disabled, match:class .*"]);
        }
    }

    onEnabledChanged: {
        glassRestoreReady = false;
        if (enabled) {
            setDynamicConfs();
            if (GlobalConfig.utilities.toasts.gameModeChanged)
                Toaster.toast(qsTr("Game mode enabled"), qsTr("Disabled glass, blur, animations, gaps and shadows"), "gamepad");
        } else {
            Hypr.extras.message("reload");
            if (GlobalConfig.utilities.toasts.gameModeChanged)
                Toaster.toast(qsTr("Game mode disabled"), qsTr("Hyprland settings restored"), "gamepad");
        }
    }

    PersistentProperties {
        id: props

        property bool enabled: Hypr.options["animations:enabled"] === 0 || Hypr.options["animations:enabled"] === false // qmllint disable missing-property
        property bool glassOverridden
        property list<string> glassDisabledWindows

        reloadableId: "gameMode"
    }

    Process {
        id: hyprglassProbe

        command: ["hyprctl", "-j", "plugin", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.enabled || !text.trim())
                    return;

                const plugins = JSON.parse(text);
                if (!plugins.some(plugin => plugin.name === "hyprglass"))
                    return;

                if (props.glassOverridden)
                    root.disableGlass();
                else
                    glassWindowsProbe.running = true;
            }
        }
    }

    Process {
        id: glassWindowsProbe

        command: ["hyprctl", "-j", "clients"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text.trim())
                    return;

                const windows = JSON.parse(text);
                if (root.enabled) {
                    if (!props.glassOverridden) {
                        props.glassDisabledWindows = windows.filter(window => window.tags.includes("hyprglass_disabled*")).map(window => window.address);
                        props.glassOverridden = true;
                    }
                    root.disableGlass();
                } else if (props.glassOverridden && root.glassRestoreReady) {
                    // Dynamic tags survive reloads and require the '*' suffix
                    // for removal. Keep any opt-outs that preceded game mode.
                    const commands = windows.filter(window => !props.glassDisabledWindows.includes(window.address)).map(window => Hypr.usingLua ? `eval hl.dispatch(hl.dsp.window.tag({ tag = "-hyprglass_disabled*", window = "address:${window.address}" }))` : `dispatch tagwindow -hyprglass_disabled*,address:${window.address}`);
                    Hypr.extras.batchMessage(commands);
                    props.glassOverridden = false;
                    props.glassDisabledWindows = [];
                    root.glassRestoreReady = false;
                }
            }
        }
    }

    Connections {
        function onConfigReloaded(): void {
            if (props.enabled)
                root.setDynamicConfs();
            else if (props.glassOverridden) {
                root.glassRestoreReady = true;
                glassWindowsProbe.running = true;
            }
        }

        target: Hypr
    }

    IpcHandler {
        function isEnabled(): bool {
            return props.enabled;
        }

        function toggle(): void {
            props.enabled = !props.enabled;
        }

        function enable(): void {
            props.enabled = true;
        }

        function disable(): void {
            props.enabled = false;
        }

        target: "gameMode"
    }
}
