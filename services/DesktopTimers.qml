pragma Singleton

import QtQuick
import Quickshell
import Caelestia

Singleton {
    id: root

    property double now: Date.now()
    readonly property var timers: JSON.parse(state.timersJson)
    readonly property bool running: Object.values(timers).some(timer => timer.status === "running")

    function forScreen(screen: string): var {
        return timers[screen] ?? {
            status: "idle",
            remaining: 0,
            duration: 0,
            deadline: 0
        };
    }

    function remaining(screen: string): real {
        const timer = forScreen(screen);
        return timer.status === "running" ? Math.max(0, timer.deadline - now) : timer.remaining;
    }

    function store(screen: string, timer: var): void {
        state.timersJson = JSON.stringify(Object.assign({}, timers, {
            [screen]: timer
        }));
    }

    function start(screen: string, seconds: real): void {
        if (!Number.isFinite(seconds) || seconds <= 0)
            return;
        const duration = Math.min(5999, Math.floor(seconds)) * 1000;
        now = Date.now();
        store(screen, {
            status: "running",
            remaining: duration,
            duration: duration,
            deadline: now + duration
        });
    }

    function pause(screen: string): void {
        const timer = forScreen(screen);
        if (timer.status !== "running")
            return;
        now = Date.now();
        update();
        if (forScreen(screen).status === "running")
            store(screen, Object.assign({}, timer, {
                status: "paused",
                remaining: Math.max(0, timer.deadline - now)
            }));
    }

    function resume(screen: string): void {
        const timer = forScreen(screen);
        if (timer.status !== "paused")
            return;
        now = Date.now();
        store(screen, Object.assign({}, timer, {
            status: "running",
            deadline: now + timer.remaining
        }));
    }

    function cancel(screen: string): void {
        const next = Object.assign({}, timers);
        delete next[screen];
        state.timersJson = JSON.stringify(next);
    }

    function update(): void {
        now = Date.now();
        for (const [screen, timer] of Object.entries(timers)) {
            if (timer.status === "running" && timer.deadline <= now) {
                store(screen, Object.assign({}, timer, {
                    status: "finished",
                    remaining: 0
                }));
                Toaster.toast(qsTr("Time’s up"), qsTr("Your desktop timer has finished."), "timer");
            }
        }
    }

    Component.onCompleted: update()

    PersistentProperties {
        id: state

        // Plain strings can cross QML engines during a hot reload; JS objects cannot.
        property string timersJson: "{}"

        reloadableId: "desktop-timers"
    }

    Timer {
        interval: 100
        running: root.running
        repeat: true
        onTriggered: root.update()
    }
}
