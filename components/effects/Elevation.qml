import QtQuick
import QtQuick.Effects
import qs.components
import qs.services

Item {
    id: root

    property int level
    property real dp: [0, 1, 2, 4, 6, 8][level]
    property alias radius: shadow.radius
    property alias topLeftRadius: shadow.topLeftRadius
    property alias topRightRadius: shadow.topRightRadius
    property alias bottomLeftRadius: shadow.bottomLeftRadius
    property alias bottomRightRadius: shadow.bottomRightRadius
    property alias color: shadow.color
    property alias blur: shadow.blur
    property alias spread: shadow.spread
    property alias offset: shadow.offset
    property alias cached: shadow.cached
    property alias material: shadow.material

    // Some callers put interactive content inside Elevation (for example Menu).
    // Suspend only the shadow so those children remain visible and usable.
    RectangularShadow {
        id: shadow

        anchors.fill: parent
        z: -1
        visible: !GameMode.enabled
        color: Qt.alpha(Colours.palette.m3shadow, Colours.shadowOpacity)
        blur: Math.max(1, root.dp * 4)
        spread: -root.dp * 0.2
        offset.y: root.dp / 3
    }

    Behavior on dp {
        Anim {
            type: Anim.SlowEffects
        }
    }
}
