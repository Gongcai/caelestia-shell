import QtQuick
import QtQuick.Templates
import Caelestia.Config
import qs.components
import qs.services

RadioButton {
    id: root

    font: Tokens.font.body.small

    implicitWidth: implicitIndicatorWidth + implicitContentWidth + contentItem.anchors.leftMargin
    implicitHeight: Math.max(implicitIndicatorHeight, implicitContentHeight)

    indicator: StyledRect {
        id: outerCircle

        implicitWidth: 20
        implicitHeight: 20
        radius: Tokens.rounding.full
        color: "transparent"
        border.color: !root.enabled ? Qt.alpha(Colours.palette.m3onSurface, 0.25) : root.checked ? Colours.palette.m3primary : Colours.palette.m3outline
        border.width: 2
        anchors.verticalCenter: parent.verticalCenter

        StateLayer {
            anchors.margins: -Tokens.padding.small
            color: Colours.palette.m3primary
            disabled: !root.enabled
            z: -1
            onClicked: root.click()
        }

        StyledRect {
            anchors.centerIn: parent
            implicitWidth: 8
            implicitHeight: 8

            radius: Tokens.rounding.full
            color: root.checked ? Colours.palette.m3primary : "transparent"
            opacity: root.enabled ? 1 : 0.38
            scale: root.checked ? 1 : 0

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
            Behavior on scale {
                Anim {
                    type: Anim.FastSpatial
                }
            }
        }

        Behavior on border.color {
            CAnim {}
        }
    }

    contentItem: StyledText {
        text: root.text
        font: root.font
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: outerCircle.right
        anchors.leftMargin: Tokens.spacing.medium
    }
}
