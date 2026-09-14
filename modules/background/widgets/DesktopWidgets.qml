pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.services
import qs.modules.background

Item {
    id: root

    required property ShellScreen screen
    required property Item wallpaper
    property bool wallpaperAvailable
    property bool wallpaperAnimated
    property string wallpaperKey
    readonly property Item clockInteractionTarget: clockLoader.interactionTarget
    readonly property Item calendarInteractionTarget: calendarLoader.interactionTarget
    readonly property Item weatherInteractionTarget: weatherLoader.interactionTarget
    readonly property Item musicInteractionTarget: musicLoader.interactionTarget
    readonly property Item worldClockInteractionTarget: worldClockLoader.interactionTarget
    readonly property Item timerInteractionTarget: timerLoader.interactionTarget
    readonly property Item memoryInteractionTarget: memoryLoader.interactionTarget
    readonly property Item visualiserInteractionTarget: visualiserLoader.interactionTarget
    readonly property var editableClockConfig: GlobalConfig.forScreen(screen.name).background.desktopClock
    readonly property var editableCalendarConfig: GlobalConfig.forScreen(screen.name).background.desktopCalendar
    readonly property var editableWeatherConfig: GlobalConfig.forScreen(screen.name).background.desktopWeather
    readonly property var editableMusicConfig: GlobalConfig.forScreen(screen.name).background.desktopMusic
    readonly property var editableWorldClockConfig: GlobalConfig.forScreen(screen.name).background.desktopWorldClock
    readonly property var editableTimerConfig: GlobalConfig.forScreen(screen.name).background.desktopTimer
    readonly property var editableMemoryConfig: GlobalConfig.forScreen(screen.name).background.desktopMemory
    readonly property var editableVisualiserConfig: GlobalConfig.forScreen(screen.name).background.desktopVisualiser

    function commitMove(widget: Item, config: var, deltaX: real, deltaY: real): void {
        if (width <= 0 || height <= 0 || widget.width <= 0 || widget.height <= 0)
            return;
        const padding = Tokens.padding.small;
        const minX = Tokens.sizes.bar.innerWidth + Math.max(padding, Config.border.thickness);
        const maxX = Math.max(minX, width - widget.width - padding);
        const minY = padding;
        const maxY = Math.max(minY, height - widget.height - padding);
        const targetX = Math.max(minX, Math.min(maxX, widget.x + deltaX));
        const targetY = Math.max(minY, Math.min(maxY, widget.y + deltaY));

        config.offsetX = Math.round(config.offsetX + targetX - widget.x);
        config.offsetY = Math.round(config.offsetY + targetY - widget.y);
    }

    DesktopBackdrop {
        id: backdrop

        anchors.fill: parent
        wallpaper: root.wallpaper
        available: root.wallpaperAvailable
        animated: root.wallpaperAnimated
        revisionKey: root.wallpaperKey
        active: (Config.background.desktopCalendar.enabled || Config.background.desktopWeather.enabled || Config.background.desktopMusic.enabled || Config.background.desktopWorldClock.enabled || Config.background.desktopTimer.enabled || (Config.background.desktopClock.enabled && ["digital", "analog"].includes(Config.background.desktopClock.style))) && Colours.transparency.enabled && !GameMode.enabled
    }

    // Each desktop widget gets its own loader so future widget types can share
    // positioning without becoming coupled to the background window.
    WidgetLoader {
        id: clockLoader

        asynchronous: true
        active: Config.background.desktopClock.enabled
        position: Config.background.desktopClock.position
        horizontalOffset: Config.background.desktopClock.offsetX
        verticalOffset: Config.background.desktopClock.offsetY
        edgeMargin: Tokens.padding.extraLargeIncreased
        leftEdgeMargin: Tokens.padding.extraLargeIncreased + Tokens.sizes.bar.innerWidth + Math.max(Tokens.padding.small, Config.border.thickness)
        onMoveRequested: (deltaX, deltaY) => root.commitMove(clockLoader, root.editableClockConfig, deltaX, deltaY)
        onContentSizeChanged: root.commitMove(clockLoader, root.editableClockConfig, 0, 0)

        sourceComponent: ["digital", "analog"].includes(Config.background.desktopClock.style) ? glassClock : classicClock
    }

    Component {
        id: classicClock

        DesktopClock {
            wallpaper: root.wallpaper
            absX: clockLoader.x + clockLoader.visualOffsetX
            absY: clockLoader.y + clockLoader.visualOffsetY
        }
    }

    Component {
        id: glassClock

        GlassClock {
            desktopBackdrop: backdrop
            motionItem: clockLoader.interactionTarget
            absX: clockLoader.x + clockLoader.visualOffsetX
            absY: clockLoader.y + clockLoader.visualOffsetY
        }
    }

    WidgetLoader {
        id: calendarLoader

        asynchronous: true
        active: Config.background.desktopCalendar.enabled
        position: Config.background.desktopCalendar.position
        horizontalOffset: Config.background.desktopCalendar.offsetX
        verticalOffset: Config.background.desktopCalendar.offsetY
        edgeMargin: Tokens.padding.extraLargeIncreased
        leftEdgeMargin: Tokens.padding.extraLargeIncreased + Tokens.sizes.bar.innerWidth + Math.max(Tokens.padding.small, Config.border.thickness)
        onMoveRequested: (deltaX, deltaY) => root.commitMove(calendarLoader, root.editableCalendarConfig, deltaX, deltaY)
        onContentSizeChanged: root.commitMove(calendarLoader, root.editableCalendarConfig, 0, 0)

        sourceComponent: GlassCalendar {
            desktopBackdrop: backdrop
            motionItem: calendarLoader.interactionTarget
            absX: calendarLoader.x + calendarLoader.visualOffsetX
            absY: calendarLoader.y + calendarLoader.visualOffsetY
        }
    }

    WidgetLoader {
        id: weatherLoader

        asynchronous: true
        active: Config.background.desktopWeather.enabled
        position: Config.background.desktopWeather.position
        horizontalOffset: Config.background.desktopWeather.offsetX
        verticalOffset: Config.background.desktopWeather.offsetY
        edgeMargin: Tokens.padding.extraLargeIncreased
        leftEdgeMargin: Tokens.padding.extraLargeIncreased + Tokens.sizes.bar.innerWidth + Math.max(Tokens.padding.small, Config.border.thickness)
        onMoveRequested: (deltaX, deltaY) => root.commitMove(weatherLoader, root.editableWeatherConfig, deltaX, deltaY)
        onContentSizeChanged: root.commitMove(weatherLoader, root.editableWeatherConfig, 0, 0)

        sourceComponent: GlassWeather {
            desktopBackdrop: backdrop
            motionItem: weatherLoader.interactionTarget
            absX: weatherLoader.x + weatherLoader.visualOffsetX
            absY: weatherLoader.y + weatherLoader.visualOffsetY
        }
    }

    WidgetLoader {
        id: musicLoader

        asynchronous: true
        active: Config.background.desktopMusic.enabled
        position: Config.background.desktopMusic.position
        horizontalOffset: Config.background.desktopMusic.offsetX
        verticalOffset: Config.background.desktopMusic.offsetY
        edgeMargin: Tokens.padding.extraLargeIncreased
        leftEdgeMargin: Tokens.padding.extraLargeIncreased + Tokens.sizes.bar.innerWidth + Math.max(Tokens.padding.small, Config.border.thickness)
        onMoveRequested: (deltaX, deltaY) => root.commitMove(musicLoader, root.editableMusicConfig, deltaX, deltaY)
        onContentSizeChanged: root.commitMove(musicLoader, root.editableMusicConfig, 0, 0)

        sourceComponent: GlassMusic {
            desktopBackdrop: backdrop
            motionItem: musicLoader.interactionTarget
            absX: musicLoader.x + musicLoader.visualOffsetX
            absY: musicLoader.y + musicLoader.visualOffsetY
        }
    }

    WidgetLoader {
        id: worldClockLoader

        asynchronous: true
        active: Config.background.desktopWorldClock.enabled
        position: Config.background.desktopWorldClock.position
        horizontalOffset: Config.background.desktopWorldClock.offsetX
        verticalOffset: Config.background.desktopWorldClock.offsetY
        edgeMargin: Tokens.padding.extraLargeIncreased
        leftEdgeMargin: Tokens.padding.extraLargeIncreased + Tokens.sizes.bar.innerWidth + Math.max(Tokens.padding.small, Config.border.thickness)
        onMoveRequested: (deltaX, deltaY) => root.commitMove(worldClockLoader, root.editableWorldClockConfig, deltaX, deltaY)
        onContentSizeChanged: root.commitMove(worldClockLoader, root.editableWorldClockConfig, 0, 0)

        sourceComponent: GlassWorldClock {
            desktopBackdrop: backdrop
            motionItem: worldClockLoader.interactionTarget
            absX: worldClockLoader.x + worldClockLoader.visualOffsetX
            absY: worldClockLoader.y + worldClockLoader.visualOffsetY
        }
    }

    WidgetLoader {
        id: timerLoader

        asynchronous: true
        active: Config.background.desktopTimer.enabled
        position: Config.background.desktopTimer.position
        horizontalOffset: Config.background.desktopTimer.offsetX
        verticalOffset: Config.background.desktopTimer.offsetY
        edgeMargin: Tokens.padding.extraLargeIncreased
        leftEdgeMargin: Tokens.padding.extraLargeIncreased + Tokens.sizes.bar.innerWidth + Math.max(Tokens.padding.small, Config.border.thickness)
        onMoveRequested: (deltaX, deltaY) => root.commitMove(timerLoader, root.editableTimerConfig, deltaX, deltaY)
        onContentSizeChanged: root.commitMove(timerLoader, root.editableTimerConfig, 0, 0)

        sourceComponent: GlassTimer {
            desktopBackdrop: backdrop
            motionItem: timerLoader.interactionTarget
            absX: timerLoader.x + timerLoader.visualOffsetX
            absY: timerLoader.y + timerLoader.visualOffsetY
            screenName: root.screen.name
        }
    }

    WidgetLoader {
        id: memoryLoader

        asynchronous: true
        active: Config.background.desktopMemory.enabled
        position: Config.background.desktopMemory.position
        horizontalOffset: Config.background.desktopMemory.offsetX
        verticalOffset: Config.background.desktopMemory.offsetY
        edgeMargin: Tokens.padding.extraLargeIncreased
        leftEdgeMargin: Tokens.padding.extraLargeIncreased + Tokens.sizes.bar.innerWidth + Math.max(Tokens.padding.small, Config.border.thickness)
        onMoveRequested: (deltaX, deltaY) => root.commitMove(memoryLoader, root.editableMemoryConfig, deltaX, deltaY)
        onContentSizeChanged: root.commitMove(memoryLoader, root.editableMemoryConfig, 0, 0)

        sourceComponent: MemoryWidget {
            wallpaper: root.wallpaper
            absX: memoryLoader.x + memoryLoader.visualOffsetX
            absY: memoryLoader.y + memoryLoader.visualOffsetY
        }
    }

    WidgetLoader {
        id: visualiserLoader

        asynchronous: true
        active: Config.background.desktopVisualiser.enabled
        position: Config.background.desktopVisualiser.position
        horizontalOffset: Config.background.desktopVisualiser.offsetX
        verticalOffset: Config.background.desktopVisualiser.offsetY
        edgeMargin: Tokens.padding.extraLargeIncreased
        leftEdgeMargin: Tokens.padding.extraLargeIncreased + Tokens.sizes.bar.innerWidth + Math.max(Tokens.padding.small, Config.border.thickness)
        onMoveRequested: (deltaX, deltaY) => root.commitMove(visualiserLoader, root.editableVisualiserConfig, deltaX, deltaY)
        onContentSizeChanged: root.commitMove(visualiserLoader, root.editableVisualiserConfig, 0, 0)

        sourceComponent: MusicVisualiserWidget {
            wallpaper: root.wallpaper
            absX: visualiserLoader.x + visualiserLoader.visualOffsetX
            absY: visualiserLoader.y + visualiserLoader.visualOffsetY
        }
    }
}
