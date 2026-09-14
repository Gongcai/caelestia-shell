import QtQuick
import Caelestia.Config
import qs.components.controls

IconButton {
    property real widgetScale: 1
    required property color foreground

    implicitWidth: 36 * widgetScale
    implicitHeight: implicitWidth
    font: Tokens.font.icon.size(22 * widgetScale).build()
    type: IconButton.Text
    isRound: true
    inactiveOnColour: foreground
}
