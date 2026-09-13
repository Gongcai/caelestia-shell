import QtQuick
import Caelestia.Config
import qs.services

MouseArea {
    id: root

    property bool disabled
    property bool showHoverBackground: true
    property bool manualPressOverride
    property bool manualHoverOverride
    readonly property alias rect: base

    property bool shapeMorph
    property real pressFeedback
    property real stateOpacity: {
        if (pressed || manualPressOverride || pressFeedback > 0)
            return Colours.pressedStateOpacity;
        if (showHoverBackground && (containsMouse || manualHoverOverride))
            return Colours.hoverStateOpacity;
        return 0;
    }

    property real pressX: width / 2
    property real pressY: height / 2

    property alias color: base.color
    property alias radius: base.radius
    property alias topLeftRadius: base.topLeftRadius
    property alias topRightRadius: base.topRightRadius
    property alias bottomLeftRadius: base.bottomLeftRadius
    property alias bottomRightRadius: base.bottomRightRadius

    function press(x: real, y: real): void {
        pressX = x;
        pressY = y;
        pressFeedback = 1;
        pressFeedbackAnim.restart();
    }

    anchors.fill: parent
    enabled: !disabled
    cursorShape: disabled ? undefined : Qt.PointingHandCursor
    hoverEnabled: true

    onPressed: e => press(e.x, e.y)

    Anim {
        id: pressFeedbackAnim

        target: root
        property: "pressFeedback"
        to: 0
        type: Anim.FastEffects
    }

    StyledRect {
        id: base

        anchors.fill: parent
        opacity: root.stateOpacity
        color: Colours.palette.m3onSurface
        // Pick up radius from parent if it has one (parent can be anything with radius props)
        // qmllint disable missing-property
        radius: root.parent?.radius ?? 0
        topLeftRadius: root.parent?.topLeftRadius ?? radius ?? 0
        topRightRadius: root.parent?.topRightRadius ?? radius ?? 0
        bottomLeftRadius: root.parent?.bottomLeftRadius ?? radius ?? 0
        bottomRightRadius: root.parent?.bottomRightRadius ?? radius ?? 0
        // qmllint enable missing-property
    }

    Behavior on stateOpacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }
}
