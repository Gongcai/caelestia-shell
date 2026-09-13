import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Wayland
import qs.services

Item {
    id: root

    required property var targetWindow
    property var materialRegion

    Component {
        id: regionComponent

        Region {}
    }

    Component {
        id: itemRegionComponent

        Region {
            required property Item target

            function syncGeometry(): void {
                if (!target || !target.visible || target.width <= 0 || target.height <= 0) {
                    width = 0;
                    height = 0;
                    return;
                }

                const bounds = target.mapToItem(root.targetWindow.contentItem, 0, 0, target.width, target.height);
                const left = Math.max(0, Math.floor(bounds.x));
                const top = Math.max(0, Math.floor(bounds.y));
                const right = Math.min(root.targetWindow.width, Math.ceil(bounds.x + bounds.width));
                const bottom = Math.min(root.targetWindow.height, Math.ceil(bounds.y + bounds.height));
                x = left;
                y = top;
                width = Math.max(0, right - left);
                height = Math.max(0, bottom - top);
            }
        }
    }

    function syncGeometry(): void {
        if (materialRegion)
            for (const region of materialRegion.regions)
                region.syncGeometry();
    }

    function rebuild(): void {
        if (!targetWindow)
            return;

        const itemRegions = [];
        const nextRegion = regionComponent.createObject(root);
        for (const entry of MaterialBlur.itemsFor(targetWindow)) {
            const item = entry.item;
            if (!item)
                continue;

            const itemRegion = itemRegionComponent.createObject(nextRegion, { "target": item });
            if (itemRegion) {
                itemRegion.syncGeometry();
                itemRegions.push(itemRegion);
            }
        }

        if (itemRegions.length === 0) {
            nextRegion.destroy();
            if (materialRegion) {
                targetWindow.BackgroundEffect.blurRegion = null;
                materialRegion.destroy();
                materialRegion = null;
            }
            return;
        }

        nextRegion.regions = itemRegions;
        const previousRegion = materialRegion;
        materialRegion = nextRegion;
        targetWindow.BackgroundEffect.blurRegion = materialRegion;
        if (previousRegion)
            previousRegion.destroy();
    }

    Component.onCompleted: rebuild()
    Component.onDestruction: {
        if (targetWindow)
            targetWindow.BackgroundEffect.blurRegion = null;
    }

    Connections {
        // Region.item does not observe ancestor transforms. Update before the
        // frame is polished/committed, without starting an idle animation timer.
        target: root.targetWindow?.contentItem.Window.window ?? null

        function onAfterAnimating(): void {
            root.syncGeometry();
        }
    }

    Connections {
        target: MaterialBlur

        function onItemsChanged(): void {
            root.rebuild();
        }
    }
}
