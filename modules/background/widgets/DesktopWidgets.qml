pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.modules.background

Item {
    id: root

    required property ShellScreen screen
    required property Item wallpaper
    readonly property Item clockInteractionTarget: clockLoader.interactionTarget
    readonly property Item memoryInteractionTarget: memoryLoader.interactionTarget
    readonly property var editableClockConfig: GlobalConfig.forScreen(screen.name).background.desktopClock
    readonly property var editableMemoryConfig: GlobalConfig.forScreen(screen.name).background.desktopMemory

    function commitClockMove(deltaX: real, deltaY: real): void {
        const padding = Tokens.padding.small;
        const minX = Tokens.sizes.bar.innerWidth + Math.max(padding, Config.border.thickness);
        const maxX = Math.max(minX, width - clockLoader.width - padding);
        const minY = padding;
        const maxY = Math.max(minY, height - clockLoader.height - padding);
        const targetX = Math.max(minX, Math.min(maxX, clockLoader.x + deltaX));
        const targetY = Math.max(minY, Math.min(maxY, clockLoader.y + deltaY));

        editableClockConfig.offsetX = Math.round(editableClockConfig.offsetX + targetX - clockLoader.x);
        editableClockConfig.offsetY = Math.round(editableClockConfig.offsetY + targetY - clockLoader.y);
    }

    function commitMemoryMove(deltaX: real, deltaY: real): void {
        const padding = Tokens.padding.small;
        const minX = Tokens.sizes.bar.innerWidth + Math.max(padding, Config.border.thickness);
        const maxX = Math.max(minX, width - memoryLoader.width - padding);
        const minY = padding;
        const maxY = Math.max(minY, height - memoryLoader.height - padding);
        const targetX = Math.max(minX, Math.min(maxX, memoryLoader.x + deltaX));
        const targetY = Math.max(minY, Math.min(maxY, memoryLoader.y + deltaY));

        editableMemoryConfig.offsetX = Math.round(editableMemoryConfig.offsetX + targetX - memoryLoader.x);
        editableMemoryConfig.offsetY = Math.round(editableMemoryConfig.offsetY + targetY - memoryLoader.y);
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
        onMoveRequested: (deltaX, deltaY) => root.commitClockMove(deltaX, deltaY)

        sourceComponent: DesktopClock {
            wallpaper: root.wallpaper
            absX: clockLoader.x + clockLoader.visualOffsetX
            absY: clockLoader.y + clockLoader.visualOffsetY
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
        onMoveRequested: (deltaX, deltaY) => root.commitMemoryMove(deltaX, deltaY)

        sourceComponent: MemoryWidget {
            wallpaper: root.wallpaper
            absX: memoryLoader.x + memoryLoader.visualOffsetX
            absY: memoryLoader.y + memoryLoader.visualOffsetY
        }
    }
}
