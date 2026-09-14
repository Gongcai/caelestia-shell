pragma ComponentBehavior: Bound

import QtQuick

// Squircle ray intersections adapted from Liquid Glass KDE's TickRing.qml
// (jaxparrow07/liquidglass-kde-widgets, GPL-3.0). Geometry is cached on resize.
Canvas {
    id: root

    property color color: "white"
    property real radius: 56
    property bool circular
    property int second: -1
    readonly property real unit: Math.min(width, height)
    readonly property var ticks: {
        const result = [];
        for (let i = 0; i < 60; i++) {
            const angle = i * Math.PI / 30;
            const dx = Math.sin(angle);
            const dy = -Math.cos(angle);
            const outer = boundary(dx, dy, unit * 0.075);
            const inner = boundary(dx, dy, unit * (i % 5 === 0 ? 0.13 : 0.105));
            result.push([outer.x, outer.y, inner.x, inner.y]);
        }
        return result;
    }

    function boundary(dx: real, dy: real, inset: real): point {
        if (circular) {
            const distance = unit / 2 - inset;
            return Qt.point(width / 2 + dx * distance, height / 2 + dy * distance);
        }
        const hw = Math.max(1, width / 2 - inset);
        const hh = Math.max(1, height / 2 - inset);
        const r = Math.max(0, Math.min(radius - inset, hw, hh));
        let low = 0;
        let high = Math.min(hw / Math.max(1e-9, Math.abs(dx)), hh / Math.max(1e-9, Math.abs(dy)));
        for (let i = 0; i < 20; i++) {
            const middle = (low + high) / 2;
            const qx = Math.abs(middle * dx) - hw + r;
            const qy = Math.abs(middle * dy) - hh + r;
            const level = Math.min(Math.max(qx, qy), 0) + Math.pow(Math.pow(Math.max(0, qx), 5.5) + Math.pow(Math.max(0, qy), 5.5), 1 / 5.5) - r;
            if (level < 0)
                low = middle;
            else
                high = middle;
        }
        const distance = (low + high) / 2;
        return Qt.point(width / 2 + dx * distance, height / 2 + dy * distance);
    }

    onTicksChanged: requestPaint()
    onColorChanged: requestPaint()
    onSecondChanged: requestPaint()
    Component.onCompleted: requestPaint()

    antialiasing: true
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.strokeStyle = color;
        ctx.lineCap = "round";
        for (let i = 0; i < ticks.length; i++) {
            const tick = ticks[i];
            ctx.globalAlpha = second === i ? 0.95 : (i % 5 === 0 ? 0.52 : 0.2);
            ctx.lineWidth = Math.max(1, unit * (i % 5 === 0 ? 0.009 : 0.006));
            ctx.beginPath();
            ctx.moveTo(tick[0], tick[1]);
            ctx.lineTo(tick[2], tick[3]);
            ctx.stroke();
        }
    }
}
