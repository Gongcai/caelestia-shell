pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    required property DesktopBackdrop desktopBackdrop
    required property Item motionItem
    required property real absX
    required property real absY
    required property string screenName
    readonly property var widgetConfig: GlobalConfig.forScreen(screenName).background.desktopTimer
    readonly property real widgetScale: Math.max(0.5, Math.min(2, widgetConfig.scale))
    readonly property var timer: DesktopTimers.forScreen(screenName)
    readonly property string status: timer.status
    readonly property int remainingSeconds: Math.ceil(DesktopTimers.remaining(screenName) / 1000)
    readonly property int selectedDuration: Math.max(0, Math.min(5999, widgetConfig.duration))
    readonly property string remainingText: String(Math.floor(remainingSeconds / 60)).padStart(2, "0") + ":" + String(remainingSeconds % 60).padStart(2, "0")

    function setDuration(minutes: int, seconds: int): void {
        widgetConfig.duration = Math.max(0, Math.min(5999, minutes * 60 + seconds));
    }

    function activate(): void {
        if (status === "running")
            DesktopTimers.pause(screenName);
        else if (status === "paused")
            DesktopTimers.resume(screenName);
        else if (status === "finished")
            DesktopTimers.cancel(screenName);
        else
            DesktopTimers.start(screenName, selectedDuration);
    }

    implicitWidth: (widgetConfig.wide ? 560 : 280) * widgetScale
    implicitHeight: 280 * widgetScale

    DesktopWidgetSurface {
        id: surface

        anchors.fill: parent
        desktopBackdrop: root.desktopBackdrop
        transformItem: root.motionItem
        sampleX: root.absX
        sampleY: root.absY
        radius: 44 * root.widgetScale
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 24 * root.widgetScale
        spacing: 24 * root.widgetScale

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 232 * root.widgetScale
            visible: root.widgetConfig.wide
            spacing: 8 * root.widgetScale

            StyledText {
                text: qsTr("Presets")
                color: surface.secondaryForeground
                font: Tokens.font.label.builders.medium.scale(root.widgetScale).build()
            }

            Repeater {
                model: [1, 5, 10, 15, 25]

                Rectangle {
                    id: preset

                    required property int modelData

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitWidth: 180 * root.widgetScale
                    implicitHeight: 32 * root.widgetScale
                    radius: 10 * root.widgetScale
                    color: Qt.alpha(surface.foreground, 0.09)

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 12 * root.widgetScale
                        text: qsTr("%1 min").arg(preset.modelData)
                        color: surface.foreground
                        font: Tokens.font.body.builders.small.scale(root.widgetScale).build()
                    }

                    StateLayer {
                        objectName: "timerPreset" + preset.modelData
                        radius: parent.radius
                        color: surface.foreground
                        onClicked: {
                            root.setDuration(preset.modelData, 0);
                            DesktopTimers.start(root.screenName, preset.modelData * 60);
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.preferredWidth: 232 * root.widgetScale
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8 * root.widgetScale

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.status === "paused" ? qsTr("Paused") : root.status === "finished" ? qsTr("Time’s up") : qsTr("Timer")
                color: surface.secondaryForeground
                font: Tokens.font.label.builders.medium.scale(root.widgetScale).build()
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                RowLayout {
                    anchors.centerIn: parent
                    visible: root.status === "idle"
                    spacing: 4 * root.widgetScale

                    TimeWheel {
                        objectName: "timerMinutes"
                        model: 100
                        currentIndex: Math.floor(root.selectedDuration / 60)
                        onValueSelected: value => root.setDuration(value, root.selectedDuration % 60)
                    }

                    StyledText {
                        text: qsTr("min")
                        color: surface.secondaryForeground
                        font: Tokens.font.label.builders.small.scale(root.widgetScale).build()
                    }

                    TimeWheel {
                        objectName: "timerSeconds"
                        model: 60
                        currentIndex: root.selectedDuration % 60
                        onValueSelected: value => root.setDuration(Math.floor(root.selectedDuration / 60), value)
                    }

                    StyledText {
                        text: qsTr("sec")
                        color: surface.secondaryForeground
                        font: Tokens.font.label.builders.small.scale(root.widgetScale).build()
                    }
                }

                StyledText {
                    anchors.centerIn: parent
                    width: parent.width
                    visible: root.status !== "idle"
                    text: root.remainingText
                    horizontalAlignment: Text.AlignHCenter
                    color: surface.foreground
                    font: Tokens.font.clock.size(52 * root.widgetScale).weight(Font.Light).build()
                    fontSizeMode: Text.Fit
                    minimumPixelSize: 24 * root.widgetScale
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 56 * root.widgetScale

                DesktopWidgetButton {
                    objectName: "timerCancel"
                    visible: root.status !== "idle"
                    implicitWidth: 48 * root.widgetScale
                    widgetScale: root.widgetScale
                    foreground: surface.foreground
                    type: IconButton.Tonal
                    icon: "close"
                    Accessible.name: qsTr("Cancel timer")
                    onClicked: DesktopTimers.cancel(root.screenName)
                }

                DesktopWidgetButton {
                    objectName: "timerActivate"
                    implicitWidth: 48 * root.widgetScale
                    widgetScale: root.widgetScale
                    foreground: surface.foreground
                    type: IconButton.Tonal
                    icon: root.status === "running" ? "pause" : root.status === "finished" ? "check" : "play_arrow"
                    disabled: root.status === "idle" && root.selectedDuration <= 0
                    Accessible.name: root.status === "running" ? qsTr("Pause timer") : root.status === "paused" ? qsTr("Resume timer") : root.status === "finished" ? qsTr("Dismiss timer") : qsTr("Start timer")
                    onClicked: root.activate()
                }
            }
        }
    }

    component TimeWheel: Tumbler {
        property bool ready

        signal valueSelected(value: int)

        function commitSelection(): void {
            if (ready && !moving && currentIndex >= 0)
                valueSelected(currentIndex);
        }

        implicitWidth: 64 * root.widgetScale
        implicitHeight: 140 * root.widgetScale
        visibleItemCount: 5
        wrap: false
        onCurrentIndexChanged: commitSelection()
        onMovingChanged: commitSelection()
        Component.onCompleted: ready = true

        delegate: StyledText {
            required property int index
            required property int modelData

            text: String(modelData).padStart(2, "0")
            color: surface.foreground
            opacity: Math.max(0.15, 1 - Math.abs(Tumbler.displacement) * 0.34)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font: Tokens.font.body.builders.small.size(24 * root.widgetScale).build()
        }
    }
}
