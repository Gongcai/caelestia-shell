pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Io
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    required property Item wallpaper
    required property real absX
    required property real absY

    readonly property color accent: Colours.palette.m3tertiary
    readonly property real widgetScale: Config.background.desktopMemory.scale
    readonly property bool bgEnabled: Config.background.desktopMemory.background.enabled
    readonly property bool blurEnabled: bgEnabled && Config.background.desktopMemory.background.blur && !GameMode.enabled

    // Fixed card width so it doesn't shift with process name lengths.
    readonly property real cardWidth: 260

    property list<var> processes: []
    readonly property real maxRss: root.processes.reduce((max, p) => Math.max(max, p.rssKib), 0)
    readonly property var memFmt: UsageFmt.formatKib(Memory.used, Memory.total)

    implicitWidth: root.cardWidth * root.widgetScale
    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2 * root.widgetScale

    ServiceRef {
        service: Memory
    }

    Process {
        id: psProc

        running: true
        command: ["sh", "-c", "ps -eo rss,args --sort=-rss --no-headers | head -5"]
        stdout: StdioCollector {
            onStreamFinished: root.processes = root.parsePs(text)
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: psProc.running = true
    }

    function parsePs(output: string): var {
        const list = [];
        for (const line of output.split("\n")) {
            const m = line.trim().match(/^(\d+)\s+(.+)$/);
            if (!m)
                continue;
            const name = m[2].trim().split(/\s+/)[0].split("/").pop();
            if (!name || name === "ps" || name === "sh")
                continue;
            list.push({
                name,
                rssKib: parseInt(m[1], 10)
            });
            if (list.length >= 5)
                break;
        }
        return list;
    }

    function fmtSize(kib: real): string {
        const gib = kib / 1024 / 1024;
        const mib = kib / 1024;
        if (gib >= 1)
            return gib.toFixed(1) + " GiB";
        if (mib >= 1)
            return mib.toFixed(0) + " MiB";
        return kib.toFixed(0) + " KiB";
    }

    Item {
        id: shadowContainer

        anchors.fill: parent

        layer.enabled: !GameMode.enabled
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Colours.palette.m3shadow
            shadowOpacity: 0.7
            shadowBlur: 0.4
        }

        Loader {
            asynchronous: true
            anchors.fill: parent
            active: root.blurEnabled

            sourceComponent: MultiEffect {
                source: ShaderEffectSource {
                    sourceItem: root.wallpaper
                    sourceRect: Qt.rect(root.absX, root.absY, root.width, root.height)
                }
                maskSource: backgroundPlate
                maskEnabled: true
                blurEnabled: true
                blur: 1
                blurMax: 64
                autoPaddingEnabled: false
            }
        }

        StyledRect {
            id: backgroundPlate

            visible: root.bgEnabled
            anchors.fill: parent
            radius: Tokens.rounding.extraLarge * root.widgetScale
            opacity: Config.background.desktopMemory.background.opacity
            color: Colours.palette.m3surface

            layer.enabled: root.blurEnabled
        }

        ColumnLayout {
            id: layout

            anchors.fill: parent
            anchors.margins: Tokens.padding.large * root.widgetScale
            spacing: Tokens.spacing.small * root.widgetScale

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small * root.widgetScale

                MaterialIcon {
                    text: "memory_alt"
                    fill: 1
                    color: root.accent
                    fontStyle: Tokens.font.icon.builders.medium.weight(Font.DemiBold).scale(root.widgetScale).build() // DemiBold to fix fill issues
                }

                StyledText {
                    text: qsTr("Memory")
                    font: Tokens.font.title.builders.medium.scale(root.widgetScale).build()
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: Math.round(Memory.percentage * 100) + "%"
                    font: Tokens.font.title.builders.medium.scale(root.widgetScale).build()
                    color: root.accent
                }
            }

            StyledProgressBar {
                Layout.fillWidth: true
                implicitHeight: Tokens.padding.small * root.widgetScale
                value: Memory.percentage
                fgColour: root.accent
                bgColour: Colours.palette.m3surfaceContainerHighest
                animate: Config.background.desktopMemory.animate
            }

            StyledText {
                Layout.topMargin: -Tokens.spacing.extraSmall * root.widgetScale
                text: `${+root.memFmt.value.toFixed(1)} / ${+root.memFmt.total.toFixed(1)} ${root.memFmt.unit}`
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.builders.small.scale(root.widgetScale).build()
            }

            StyledRect {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.extraSmall * root.widgetScale
                implicitHeight: Math.max(1, root.widgetScale)
                color: Colours.palette.m3outlineVariant
                opacity: 0.6
            }

            ColumnLayout {
                Layout.topMargin: Tokens.spacing.extraSmall * root.widgetScale
                spacing: Tokens.spacing.extraSmall * root.widgetScale

                Repeater {
                    model: root.processes

                    delegate: ProcessRow {
                        required property int index
                        required property var modelData

                        rank: index + 1
                        name: modelData.name
                        usage: modelData.rssKib
                        maxUsage: root.maxRss
                    }
                }
            }
        }
    }

    component ProcessRow: ColumnLayout {
        id: procRow

        required property int rank
        required property string name
        required property real usage
        required property real maxUsage

        Layout.fillWidth: true
        spacing: Tokens.spacing.extraSmall * root.widgetScale

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small * root.widgetScale

            StyledText {
                text: procRow.rank
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.builders.small.scale(root.widgetScale).build()
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 12 * root.widgetScale
            }

            StyledText {
                Layout.fillWidth: true
                text: procRow.name
                font: Tokens.font.body.builders.small.scale(root.widgetScale).build()
                elide: Text.ElideLeft
            }

            StyledText {
                text: root.fmtSize(procRow.usage)
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.builders.small.scale(root.widgetScale).build()
            }
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: 3 * root.widgetScale
            radius: Tokens.rounding.full
            color: Colours.palette.m3surfaceContainerHighest

            StyledRect {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.max(3 * root.widgetScale, parent.width * (procRow.maxUsage > 0 ? procRow.usage / procRow.maxUsage : 0))
                radius: Tokens.rounding.full
                color: root.accent
                opacity: 0.8

                Behavior on width {
                    enabled: Config.background.desktopMemory.animate
                    Anim {
                        type: Anim.StandardSmall
                    }
                }
            }
        }
    }
}
