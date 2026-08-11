pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property bool editingGlobalWidgets: nState.selectedWidgetScreen === "*"
    readonly property string widgetScreenName: editingGlobalWidgets ? "" : (nState.selectedWidgetScreen || nState.screen.name)
    readonly property var widgetConfig: editingGlobalWidgets ? GlobalConfig.background.desktopClock : GlobalConfig.forScreen(widgetScreenName).background.desktopClock
    readonly property var widgetScreen: Screens.screens.find(screen => screen.name === (widgetScreenName || nState.screen.name)) ?? nState.screen
    readonly property int widgetOffsetLimitX: Math.max(2000, widgetScreen.width ?? 2000)
    readonly property int widgetOffsetLimitY: Math.max(2000, widgetScreen.height ?? 2000)
    readonly property list<MenuItem> widgetPositionItems: [
        MenuItem {
            readonly property string value: "top-left"
            text: qsTr("Top left")
        },
        MenuItem {
            readonly property string value: "top-center"
            text: qsTr("Top centre")
        },
        MenuItem {
            readonly property string value: "top-right"
            text: qsTr("Top right")
        },
        MenuItem {
            readonly property string value: "middle-left"
            text: qsTr("Middle left")
        },
        MenuItem {
            readonly property string value: "middle-center"
            text: qsTr("Centre")
        },
        MenuItem {
            readonly property string value: "middle-right"
            text: qsTr("Middle right")
        },
        MenuItem {
            readonly property string value: "bottom-left"
            text: qsTr("Bottom left")
        },
        MenuItem {
            readonly property string value: "bottom-center"
            text: qsTr("Bottom centre")
        },
        MenuItem {
            readonly property string value: "bottom-right"
            text: qsTr("Bottom right")
        }
    ]

    title: qsTr("Desktop widgets")
    isSubPage: true

    Component.onCompleted: {
        if (!nState.selectedWidgetScreen)
            nState.selectedWidgetScreen = nState.screen.name;
    }

    function resetWidgetDisplay(): void {
        if (editingGlobalWidgets)
            return;

        const screenConfig = GlobalConfig.forScreen(widgetScreenName);
        screenConfig.background.resetOption("desktopClock");
        screenConfig.save();
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: qsTr("Target display")
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: Tokens.spacing.small
            spacing: Tokens.spacing.small

            IconTextButton {
                Layout.fillWidth: true
                icon: "all_inclusive"
                text: qsTr("All displays")
                font: Tokens.font.body.small
                isRound: true
                shapeMorph: true
                type: root.editingGlobalWidgets ? IconTextButton.Filled : IconTextButton.Tonal
                onClicked: nState.selectedWidgetScreen = "*"
            }

            Repeater {
                model: Screens.screens

                IconTextButton {
                    required property ShellScreen modelData

                    Layout.fillWidth: true
                    icon: "monitor"
                    text: modelData.name
                    font: Tokens.font.body.small
                    isRound: true
                    shapeMorph: true
                    type: modelData.name === root.widgetScreenName ? IconTextButton.Filled : IconTextButton.Tonal
                    onClicked: nState.selectedWidgetScreen = modelData.name
                }
            }
        }

        IconTextButton {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: Tokens.spacing.small
            visible: !root.editingGlobalWidgets
            icon: "restart_alt"
            text: qsTr("Use global widget settings")
            font: Tokens.font.label.large
            isRound: true
            shapeMorph: true
            type: IconTextButton.Text
            onClicked: root.resetWidgetDisplay()
        }

        SectionHeader {
            text: qsTr("Clock")
        }

        ToggleRow {
            first: true
            text: qsTr("Clock")
            subtext: qsTr("Show a clock above the wallpaper")
            checked: root.widgetConfig.enabled
            onToggled: root.widgetConfig.enabled = checked
        }

        SelectRow {
            label: qsTr("Position")
            subtext: qsTr("Clock placement on the desktop")
            menuItems: root.widgetPositionItems
            active: root.widgetPositionItems.find(item => item.value === root.widgetConfig.position) ?? root.widgetPositionItems[8]
            disabled: !root.widgetConfig.enabled
            onSelected: item => root.widgetConfig.position = item.value
        }

        StepperRow {
            label: qsTr("Clock size")
            subtext: qsTr("Scale relative to the default size")
            value: Math.round(root.widgetConfig.scale * 100)
            from: 50
            to: 200
            stepSize: 5
            enabled: root.widgetConfig.enabled
            onMoved: v => root.widgetConfig.scale = v / 100
        }

        StepperRow {
            label: qsTr("Horizontal offset")
            subtext: qsTr("Positive values move the clock right")
            value: root.widgetConfig.offsetX
            from: -root.widgetOffsetLimitX
            to: root.widgetOffsetLimitX
            stepSize: 10
            enabled: root.widgetConfig.enabled
            onMoved: v => root.widgetConfig.offsetX = Math.round(v)
        }

        StepperRow {
            label: qsTr("Vertical offset")
            subtext: qsTr("Positive values move the clock down")
            value: root.widgetConfig.offsetY
            from: -root.widgetOffsetLimitY
            to: root.widgetOffsetLimitY
            stepSize: 10
            enabled: root.widgetConfig.enabled
            onMoved: v => root.widgetConfig.offsetY = Math.round(v)
        }

        ToggleRow {
            text: qsTr("Clock background")
            subtext: qsTr("Add a surface behind the clock")
            checked: root.widgetConfig.background.enabled
            disabled: !root.widgetConfig.enabled
            onToggled: root.widgetConfig.background.enabled = checked
        }

        ToggleRow {
            text: qsTr("Blur behind clock")
            subtext: qsTr("Soften the wallpaper beneath the clock surface")
            checked: root.widgetConfig.background.blur
            disabled: !root.widgetConfig.enabled || !root.widgetConfig.background.enabled
            onToggled: root.widgetConfig.background.blur = checked
        }

        ToggleRow {
            text: qsTr("Clock shadow")
            checked: root.widgetConfig.shadow.enabled
            disabled: !root.widgetConfig.enabled
            onToggled: root.widgetConfig.shadow.enabled = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Invert clock colours")
            subtext: qsTr("Use the contrasting theme colour set")
            checked: root.widgetConfig.invertColors
            disabled: !root.widgetConfig.enabled
            onToggled: root.widgetConfig.invertColors = checked
        }
    }
}
