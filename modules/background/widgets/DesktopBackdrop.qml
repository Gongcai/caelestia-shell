pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window

Item {
    id: root

    required property Item wallpaper
    property bool active
    property bool available
    property bool animated
    property string revisionKey
    property bool completed
    property bool refreshing
    property int revision
    readonly property real pixelRatio: Screen.devicePixelRatio
    readonly property bool sampling: active && available && visible && wallpaper.width > 0 && wallpaper.height > 0
    readonly property bool live: sampling && (animated || refreshing)
    readonly property Item texture: capture

    function refresh(): void {
        if (!completed)
            return;
        revision++;
        refreshing = true;
        settleTimer.restart();
        if (sampling)
            capture.scheduleUpdate();
    }

    onSamplingChanged: refresh()
    onWallpaperChanged: refresh()
    onRevisionKeyChanged: refresh()
    onAnimatedChanged: refresh()
    onPixelRatioChanged: refresh()
    onWidthChanged: refresh()
    onHeightChanged: refresh()
    Component.onCompleted: {
        completed = true;
        refresh();
    }

    Timer {
        id: settleTimer

        interval: 350
        onTriggered: root.refreshing = false
    }

    ShaderEffectSource {
        id: capture

        visible: false
        sourceItem: root.sampling ? root.wallpaper : null
        live: root.live
        smooth: true
        mipmap: true
        textureSize: Qt.size(Math.max(1, Math.round(root.wallpaper.width * root.pixelRatio)), Math.max(1, Math.round(root.wallpaper.height * root.pixelRatio)))
    }
}
