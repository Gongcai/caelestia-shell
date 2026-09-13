pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property var entries: []

    signal itemsChanged

    function register(item: Item, window: var): void {
        if (!item || !window)
            return;

        for (const entry of entries) {
            if (entry.item === item && entry.window === window)
                return;
        }

        entries = entries.concat([{ "item": item, "window": window }]);
        itemsChanged();
    }

    function unregister(item: Item): void {
        const next = entries.filter(entry => entry.item !== item);
        if (next.length === entries.length)
            return;

        entries = next;
        itemsChanged();
    }

    function notifyChanged(): void {
        itemsChanged();
    }

    function itemsFor(window: var): var {
        return entries.filter(entry => entry.window === window && entry.item);
    }
}
