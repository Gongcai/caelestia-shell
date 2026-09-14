pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQml.Models
import Quickshell
import Caelestia.Config
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property bool editingGlobalWidgets: nState.selectedWidgetScreen === "*"
    readonly property string widgetScreenName: editingGlobalWidgets ? "" : (nState.selectedWidgetScreen || nState.screen.name)
    readonly property var widgetConfig: editingGlobalWidgets ? GlobalConfig.background.desktopClock : GlobalConfig.forScreen(widgetScreenName).background.desktopClock
    readonly property var calendarConfig: editingGlobalWidgets ? GlobalConfig.background.desktopCalendar : GlobalConfig.forScreen(widgetScreenName).background.desktopCalendar
    property list<WidgetOption> cityItems: []
    readonly property var weatherConfig: editingGlobalWidgets ? GlobalConfig.background.desktopWeather : GlobalConfig.forScreen(widgetScreenName).background.desktopWeather
    readonly property var musicConfig: editingGlobalWidgets ? GlobalConfig.background.desktopMusic : GlobalConfig.forScreen(widgetScreenName).background.desktopMusic
    readonly property var worldClockConfig: editingGlobalWidgets ? GlobalConfig.background.desktopWorldClock : GlobalConfig.forScreen(widgetScreenName).background.desktopWorldClock
    readonly property var timerConfig: editingGlobalWidgets ? GlobalConfig.background.desktopTimer : GlobalConfig.forScreen(widgetScreenName).background.desktopTimer
    readonly property var glassConfig: editingGlobalWidgets ? GlobalConfig.background.desktopGlass : GlobalConfig.forScreen(widgetScreenName).background.desktopGlass
    readonly property bool glassClock: ["digital", "analog"].includes(widgetConfig.style)
    readonly property var memoryConfig: editingGlobalWidgets ? GlobalConfig.background.desktopMemory : GlobalConfig.forScreen(widgetScreenName).background.desktopMemory
    readonly property var visualiserConfig: editingGlobalWidgets ? GlobalConfig.background.desktopVisualiser : GlobalConfig.forScreen(widgetScreenName).background.desktopVisualiser
    readonly property var widgetScreen: Screens.screens.find(screen => screen.name === (widgetScreenName || nState.screen.name)) ?? nState.screen
    readonly property int widgetOffsetLimitX: Math.max(2000, widgetScreen.width ?? 2000)
    readonly property int widgetOffsetLimitY: Math.max(2000, widgetScreen.height ?? 2000)
    readonly property Instantiator cityModel: Instantiator {
        model: WorldCities.entries
        onObjectAdded: Qt.callLater(root.refreshCityItems)
        onObjectRemoved: Qt.callLater(root.refreshCityItems)

        delegate: WidgetOption {
            required property var modelData

            value: modelData.zone
            text: modelData.name
        }
    }

    readonly property list<WidgetOption> clockStyleItems: [
        WidgetOption {
            value: "classic"

            text: qsTr("Classic")
        },
        WidgetOption {
            value: "digital"

            text: qsTr("Glass digital")
        },
        WidgetOption {
            value: "analog"

            text: qsTr("Glass analog")
        }
    ]
    readonly property list<WidgetOption> widgetPositionItems: [
        WidgetOption {
            value: "top-left"

            text: qsTr("Top left")
        },
        WidgetOption {
            value: "top-center"

            text: qsTr("Top centre")
        },
        WidgetOption {
            value: "top-right"

            text: qsTr("Top right")
        },
        WidgetOption {
            value: "middle-left"

            text: qsTr("Middle left")
        },
        WidgetOption {
            value: "middle-center"

            text: qsTr("Centre")
        },
        WidgetOption {
            value: "middle-right"

            text: qsTr("Middle right")
        },
        WidgetOption {
            value: "bottom-left"

            text: qsTr("Bottom left")
        },
        WidgetOption {
            value: "bottom-center"

            text: qsTr("Bottom centre")
        },
        WidgetOption {
            value: "bottom-right"

            text: qsTr("Bottom right")
        }
    ]

    readonly property list<WidgetOption> weatherLayoutItems: [
        WidgetOption {
            value: "compact"

            text: qsTr("Compact")
        },
        WidgetOption {
            value: "wide"

            text: qsTr("Wide")
        },
        WidgetOption {
            value: "forecast"

            text: qsTr("Full forecast")
        }
    ]
    readonly property list<WidgetOption> musicLayoutItems: [
        WidgetOption {
            value: "compact"

            text: qsTr("Compact")
        },
        WidgetOption {
            value: "wide"

            text: qsTr("Wide")
        },
        WidgetOption {
            value: "tall"

            text: qsTr("Tall")
        }
    ]
    readonly property list<WidgetOption> worldClockStyleItems: [
        WidgetOption {
            value: "numbered"

            text: qsTr("Numbered dial")
        },
        WidgetOption {
            value: "minimal"

            text: qsTr("Minimal dial")
        },
        WidgetOption {
            value: "quarters"

            text: qsTr("Quarter marks")
        },
        WidgetOption {
            value: "digital"

            text: qsTr("Digital")
        }
    ]

    function refreshCityItems(): void {
        const items = [];
        for (let index = 0; index < cityModel.count; index++) {
            const item = cityModel.objectAt(index);
            if (item)
                items.push(item);
        }
        cityItems = items;
    }

    function setWorldCity(index: int, zone: string): void {
        const zones = Array.from(worldClockConfig.timeZones);
        zones[index] = zone;
        worldClockConfig.timeZones = zones;
    }

    function setCityCount(count: int): void {
        const defaults = ["Asia/Shanghai", "Europe/London", "America/New_York", "Asia/Tokyo"];
        const zones = Array.from(worldClockConfig.timeZones).slice(0, count);
        while (zones.length < count)
            zones.push(defaults[zones.length]);
        worldClockConfig.timeZones = zones;
    }

    function resetWidgetDisplay(): void {
        if (editingGlobalWidgets)
            return;

        const screenConfig = GlobalConfig.forScreen(widgetScreenName);
        screenConfig.background.resetOption("desktopClock");
        screenConfig.background.resetOption("desktopCalendar");
        screenConfig.background.resetOption("desktopWeather");
        screenConfig.background.resetOption("desktopMusic");
        screenConfig.background.resetOption("desktopWorldClock");
        screenConfig.background.resetOption("desktopTimer");
        screenConfig.background.resetOption("desktopGlass");
        screenConfig.background.resetOption("desktopMemory");
        screenConfig.background.resetOption("desktopVisualiser");
        screenConfig.save();
    }

    title: qsTr("Desktop widgets")
    isSubPage: true

    Component.onCompleted: {
        if (!nState.selectedWidgetScreen)
            nState.selectedWidgetScreen = nState.screen.name;
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
                onClicked: root.nState.selectedWidgetScreen = "*"
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
                    onClicked: root.nState.selectedWidgetScreen = modelData.name
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
            label: qsTr("Clock style")
            menuItems: root.clockStyleItems
            active: root.clockStyleItems.find(item => item.value === root.widgetConfig.style) ?? root.clockStyleItems[0]
            disabled: !root.widgetConfig.enabled
            onSelected: item => root.widgetConfig.style = (item as WidgetOption).value
        }

        SelectRow {
            label: qsTr("Position")
            subtext: qsTr("Clock placement on the desktop")
            menuItems: root.widgetPositionItems
            active: root.widgetPositionItems.find(item => item.value === root.widgetConfig.position) ?? root.widgetPositionItems[8]
            disabled: !root.widgetConfig.enabled
            onSelected: item => root.widgetConfig.position = (item as WidgetOption).value
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
            visible: root.glassClock
            last: true
            text: qsTr("Show seconds")
            subtext: qsTr("Show the second hand or highlight the current second")
            checked: root.widgetConfig.showSeconds
            disabled: !root.widgetConfig.enabled
            onToggled: root.widgetConfig.showSeconds = checked
        }

        ToggleRow {
            visible: !root.glassClock
            text: qsTr("Clock background")
            subtext: qsTr("Add a surface behind the clock")
            checked: root.widgetConfig.background.enabled
            disabled: !root.widgetConfig.enabled
            onToggled: root.widgetConfig.background.enabled = checked
        }

        ToggleRow {
            visible: !root.glassClock
            text: qsTr("Blur behind clock")
            subtext: qsTr("Soften the wallpaper beneath the clock surface")
            checked: root.widgetConfig.background.blur
            disabled: !root.widgetConfig.enabled || !root.widgetConfig.background.enabled
            onToggled: root.widgetConfig.background.blur = checked
        }

        ToggleRow {
            visible: !root.glassClock
            text: qsTr("Clock shadow")
            checked: root.widgetConfig.shadow.enabled
            disabled: !root.widgetConfig.enabled
            onToggled: root.widgetConfig.shadow.enabled = checked
        }

        ToggleRow {
            visible: !root.glassClock
            last: true
            text: qsTr("Invert clock colours")
            subtext: qsTr("Use the contrasting theme colour set")
            checked: root.widgetConfig.invertColors
            disabled: !root.widgetConfig.enabled
            onToggled: root.widgetConfig.invertColors = checked
        }

        SectionHeader {
            text: qsTr("Calendar")
        }

        ToggleRow {
            first: true
            text: qsTr("Calendar")
            subtext: qsTr("Show a glass calendar on the desktop")
            checked: root.calendarConfig.enabled
            onToggled: root.calendarConfig.enabled = checked
        }

        SelectRow {
            label: qsTr("Position")
            subtext: qsTr("Widget placement on the desktop")
            menuItems: root.widgetPositionItems
            active: root.widgetPositionItems.find(item => item.value === root.calendarConfig.position) ?? root.widgetPositionItems[2]
            disabled: !root.calendarConfig.enabled
            onSelected: item => root.calendarConfig.position = (item as WidgetOption).value
        }

        StepperRow {
            label: qsTr("Widget size")
            subtext: qsTr("Scale relative to the default size")
            value: Math.round(root.calendarConfig.scale * 100)
            from: 50
            to: 200
            stepSize: 5
            enabled: root.calendarConfig.enabled
            onMoved: v => root.calendarConfig.scale = v / 100
        }

        StepperRow {
            label: qsTr("Horizontal offset")
            subtext: qsTr("Positive values move the widget right")
            value: root.calendarConfig.offsetX
            from: -root.widgetOffsetLimitX
            to: root.widgetOffsetLimitX
            stepSize: 10
            enabled: root.calendarConfig.enabled
            onMoved: v => root.calendarConfig.offsetX = Math.round(v)
        }

        StepperRow {
            last: true
            label: qsTr("Vertical offset")
            subtext: qsTr("Positive values move the widget down")
            value: root.calendarConfig.offsetY
            from: -root.widgetOffsetLimitY
            to: root.widgetOffsetLimitY
            stepSize: 10
            enabled: root.calendarConfig.enabled
            onMoved: v => root.calendarConfig.offsetY = Math.round(v)
        }

        SectionHeader {
            text: qsTr("Weather")
        }

        ToggleRow {
            first: true
            text: qsTr("Weather")
            subtext: qsTr("Current conditions and forecasts from the shell weather service")
            checked: root.weatherConfig.enabled
            onToggled: root.weatherConfig.enabled = checked
        }

        SelectRow {
            label: qsTr("Layout")
            menuItems: root.weatherLayoutItems
            active: root.weatherLayoutItems.find(item => item.value === root.weatherConfig.layout) ?? root.weatherLayoutItems[0]
            disabled: !root.weatherConfig.enabled
            onSelected: item => root.weatherConfig.layout = (item as WidgetOption).value
        }

        PlacementControls {
            widgetConfig: root.weatherConfig
        }

        SectionHeader {
            text: qsTr("Music")
        }

        ToggleRow {
            first: true
            text: qsTr("Music")
            subtext: qsTr("Album art, playback controls and lyrics")
            checked: root.musicConfig.enabled
            onToggled: root.musicConfig.enabled = checked
        }

        SelectRow {
            label: qsTr("Layout")
            menuItems: root.musicLayoutItems
            active: root.musicLayoutItems.find(item => item.value === root.musicConfig.layout) ?? root.musicLayoutItems[0]
            disabled: !root.musicConfig.enabled
            onSelected: item => root.musicConfig.layout = (item as WidgetOption).value
        }

        PlacementControls {
            widgetConfig: root.musicConfig
        }

        SectionHeader {
            text: qsTr("World clock")
        }

        ToggleRow {
            first: true
            text: qsTr("World clock")
            subtext: qsTr("Follow up to four cities with local day and night faces")
            checked: root.worldClockConfig.enabled
            onToggled: root.worldClockConfig.enabled = checked
        }

        SelectRow {
            label: qsTr("Clock style")
            menuItems: root.worldClockStyleItems
            active: root.worldClockStyleItems.find(item => item.value === root.worldClockConfig.style) ?? root.worldClockStyleItems[0]
            disabled: !root.worldClockConfig.enabled
            onSelected: item => root.worldClockConfig.style = (item as WidgetOption).value
        }

        StepperRow {
            label: qsTr("Number of cities")
            value: Math.max(1, Math.min(4, root.worldClockConfig.timeZones.length))
            from: 1
            to: 4
            stepSize: 1
            enabled: root.worldClockConfig.enabled
            onMoved: value => root.setCityCount(value)
        }

        Repeater {
            model: Math.max(1, Math.min(4, root.worldClockConfig.timeZones.length))

            SelectRow {
                required property int index

                label: qsTr("City %1").arg(index + 1)
                menuItems: root.cityItems
                active: root.cityItems.find(item => item.value === root.worldClockConfig.timeZones[index]) ?? root.cityItems[0]
                disabled: !root.worldClockConfig.enabled
                onSelected: item => root.setWorldCity(index, (item as WidgetOption).value)
            }
        }

        ToggleRow {
            text: qsTr("Show seconds")
            checked: root.worldClockConfig.showSeconds
            disabled: !root.worldClockConfig.enabled || root.worldClockConfig.style === "digital"
            onToggled: root.worldClockConfig.showSeconds = checked
        }

        PlacementControls {
            widgetConfig: root.worldClockConfig
        }

        SectionHeader {
            text: qsTr("Timer")
        }

        ToggleRow {
            first: true
            text: qsTr("Timer")
            subtext: qsTr("A countdown with presets, pause and a completion reminder")
            checked: root.timerConfig.enabled
            onToggled: root.timerConfig.enabled = checked
        }

        ToggleRow {
            text: qsTr("Show presets")
            subtext: qsTr("Use a wide card with quick countdown presets")
            checked: root.timerConfig.wide
            disabled: !root.timerConfig.enabled
            onToggled: root.timerConfig.wide = checked
        }

        StepperRow {
            label: qsTr("Default duration")
            subtext: qsTr("Starting duration in seconds")
            value: root.timerConfig.duration
            from: 1
            to: 5999
            stepSize: 30
            enabled: root.timerConfig.enabled
            onMoved: value => root.timerConfig.duration = Math.round(value)
        }

        PlacementControls {
            widgetConfig: root.timerConfig
        }

        SectionHeader {
            text: qsTr("Glass appearance")
        }

        ToggleRow {
            first: true
            text: qsTr("Frosted glass")
            subtext: qsTr("Soften the wallpaper behind glass widgets")
            checked: root.glassConfig.blur
            onToggled: root.glassConfig.blur = checked
        }

        StepperRow {
            label: qsTr("Glass opacity (%)")
            subtext: qsTr("Increase the tint to make text easier to read")
            value: Math.round(root.glassConfig.opacity * 100)
            from: 0
            to: 100
            stepSize: 5
            onMoved: v => root.glassConfig.opacity = v / 100
        }

        StepperRow {
            last: true
            label: qsTr("Refraction strength (%)")
            subtext: qsTr("How strongly the glass edges bend the wallpaper")
            value: Math.round(root.glassConfig.refraction * 100)
            from: 0
            to: 200
            stepSize: 10
            onMoved: v => root.glassConfig.refraction = v / 100
        }

        SectionHeader {
            text: qsTr("Memory widget")
        }

        ToggleRow {
            first: true
            text: qsTr("Memory widget")
            subtext: qsTr("Show memory usage and the top processes on the desktop")
            checked: root.memoryConfig.enabled
            onToggled: root.memoryConfig.enabled = checked
        }

        SelectRow {
            label: qsTr("Position")
            subtext: qsTr("Widget placement on the desktop")
            menuItems: root.widgetPositionItems
            active: root.widgetPositionItems.find(item => item.value === root.memoryConfig.position) ?? root.widgetPositionItems[8]
            disabled: !root.memoryConfig.enabled
            onSelected: item => root.memoryConfig.position = (item as WidgetOption).value
        }

        StepperRow {
            label: qsTr("Widget size")
            subtext: qsTr("Scale relative to the default size")
            value: Math.round(root.memoryConfig.scale * 100)
            from: 50
            to: 200
            stepSize: 5
            enabled: root.memoryConfig.enabled
            onMoved: v => root.memoryConfig.scale = v / 100
        }

        StepperRow {
            label: qsTr("Horizontal offset")
            subtext: qsTr("Positive values move the widget right")
            value: root.memoryConfig.offsetX
            from: -root.widgetOffsetLimitX
            to: root.widgetOffsetLimitX
            stepSize: 10
            enabled: root.memoryConfig.enabled
            onMoved: v => root.memoryConfig.offsetX = Math.round(v)
        }

        StepperRow {
            label: qsTr("Vertical offset")
            subtext: qsTr("Positive values move the widget down")
            value: root.memoryConfig.offsetY
            from: -root.widgetOffsetLimitY
            to: root.widgetOffsetLimitY
            stepSize: 10
            enabled: root.memoryConfig.enabled
            onMoved: v => root.memoryConfig.offsetY = Math.round(v)
        }

        ToggleRow {
            text: qsTr("Memory widget background")
            subtext: qsTr("Add a surface behind the memory widget")
            checked: root.memoryConfig.background.enabled
            disabled: !root.memoryConfig.enabled
            onToggled: root.memoryConfig.background.enabled = checked
        }

        ToggleRow {
            text: qsTr("Blur behind memory widget")
            subtext: qsTr("Soften the wallpaper beneath the memory widget surface")
            checked: root.memoryConfig.background.blur
            disabled: !root.memoryConfig.enabled || !root.memoryConfig.background.enabled
            onToggled: root.memoryConfig.background.blur = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Animate progress bar")
            subtext: qsTr("Smoothly animate memory usage updates")
            checked: root.memoryConfig.animate
            disabled: !root.memoryConfig.enabled
            onToggled: root.memoryConfig.animate = checked
        }

        SectionHeader {
            text: qsTr("Music visualiser")
        }

        ToggleRow {
            first: true
            text: qsTr("Music visualiser")
            subtext: qsTr("Show a spectrum that moves with the music")
            checked: root.visualiserConfig.enabled
            onToggled: root.visualiserConfig.enabled = checked
        }

        SelectRow {
            label: qsTr("Position")
            subtext: qsTr("Widget placement on the desktop")
            menuItems: root.widgetPositionItems
            active: root.widgetPositionItems.find(item => item.value === root.visualiserConfig.position) ?? root.widgetPositionItems[7]
            disabled: !root.visualiserConfig.enabled
            onSelected: item => root.visualiserConfig.position = (item as WidgetOption).value
        }

        StepperRow {
            label: qsTr("Widget size")
            subtext: qsTr("Scale relative to the default size")
            value: Math.round(root.visualiserConfig.scale * 100)
            from: 50
            to: 200
            stepSize: 5
            enabled: root.visualiserConfig.enabled
            onMoved: v => root.visualiserConfig.scale = v / 100
        }

        StepperRow {
            label: qsTr("Spectrum bars")
            subtext: qsTr("Fewer bars use slightly less rendering time")
            value: root.visualiserConfig.bars
            from: 8
            to: 48
            stepSize: 2
            enabled: root.visualiserConfig.enabled
            onMoved: v => root.visualiserConfig.bars = Math.round(v)
        }

        StepperRow {
            label: qsTr("Horizontal offset")
            subtext: qsTr("Positive values move the widget right")
            value: root.visualiserConfig.offsetX
            from: -root.widgetOffsetLimitX
            to: root.widgetOffsetLimitX
            stepSize: 10
            enabled: root.visualiserConfig.enabled
            onMoved: v => root.visualiserConfig.offsetX = Math.round(v)
        }

        StepperRow {
            label: qsTr("Vertical offset")
            subtext: qsTr("Positive values move the widget down")
            value: root.visualiserConfig.offsetY
            from: -root.widgetOffsetLimitY
            to: root.widgetOffsetLimitY
            stepSize: 10
            enabled: root.visualiserConfig.enabled
            onMoved: v => root.visualiserConfig.offsetY = Math.round(v)
        }

        ToggleRow {
            text: qsTr("Visualiser background")
            subtext: qsTr("Add a surface behind the music visualiser")
            checked: root.visualiserConfig.background.enabled
            disabled: !root.visualiserConfig.enabled
            onToggled: root.visualiserConfig.background.enabled = checked
        }

        ToggleRow {
            last: true
            text: qsTr("Blur behind visualiser")
            subtext: qsTr("Soften the wallpaper beneath the visualiser surface")
            checked: root.visualiserConfig.background.blur
            disabled: !root.visualiserConfig.enabled || !root.visualiserConfig.background.enabled
            onToggled: root.visualiserConfig.background.blur = checked
        }
    }

    component PlacementControls: ColumnLayout {
        id: placement

        required property var widgetConfig

        Layout.fillWidth: true
        spacing: root.Tokens.spacing.extraSmall / 2

        SelectRow {
            label: qsTr("Position")
            menuItems: root.widgetPositionItems
            active: root.widgetPositionItems.find(item => item.value === placement.widgetConfig.position) ?? root.widgetPositionItems[2]
            disabled: !placement.widgetConfig.enabled
            onSelected: item => placement.widgetConfig.position = (item as WidgetOption).value
        }

        StepperRow {
            label: qsTr("Widget size")
            value: Math.round(placement.widgetConfig.scale * 100)
            from: 50
            to: 200
            stepSize: 5
            enabled: placement.widgetConfig.enabled
            onMoved: value => placement.widgetConfig.scale = value / 100
        }

        StepperRow {
            label: qsTr("Horizontal offset")
            value: placement.widgetConfig.offsetX
            from: -root.widgetOffsetLimitX
            to: root.widgetOffsetLimitX
            stepSize: 10
            enabled: placement.widgetConfig.enabled
            onMoved: value => placement.widgetConfig.offsetX = Math.round(value)
        }

        StepperRow {
            last: true
            label: qsTr("Vertical offset")
            value: placement.widgetConfig.offsetY
            from: -root.widgetOffsetLimitY
            to: root.widgetOffsetLimitY
            stepSize: 10
            enabled: placement.widgetConfig.enabled
            onMoved: value => placement.widgetConfig.offsetY = Math.round(value)
        }
    }

    component WidgetOption: MenuItem {
        required property string value
    }
}
