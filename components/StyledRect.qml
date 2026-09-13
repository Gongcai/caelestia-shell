import QtQuick
import qs.components.effects

Rectangle {
    id: root

    color: "transparent"
    property bool materialBlur: false

    MaterialSurface {
        target: root
        active: root.materialBlur
    }

    Behavior on color {
        CAnim {}
    }
}
