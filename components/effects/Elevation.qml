import QtQuick
import QtQuick.Effects
import qs.components
import qs.services

RectangularShadow {
    property int level
    property real dp: [0, 1, 2, 4, 6, 8][level]

    color: Qt.alpha(Colours.palette.m3shadow, Colours.shadowOpacity)
    blur: Math.max(1, dp * 4)
    spread: -dp * 0.2
    offset.y: dp / 3

    Behavior on dp {
        Anim {
            type: Anim.SlowEffects
        }
    }
}
