import QtQuick
import QtQuick.Templates
import Caelestia.Config
import qs.components
import qs.services

Switch {
    id: root

    property int cLayer: 1
    property bool disabled

    enabled: !disabled

    implicitWidth: implicitIndicatorWidth
    implicitHeight: implicitIndicatorHeight

    indicator: StyledRect {
        radius: Tokens.rounding.full
        color: {
            if (root.disabled)
                return root.checked ? Qt.alpha(Colours.palette.m3onSurface, 0.12) : Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.38);
            return root.checked ? Colours.palette.m3primary : Colours.layer(Colours.palette.m3surfaceContainerHighest, root.cLayer);
        }

        implicitWidth: implicitHeight * 1.7
        implicitHeight: Tokens.font.body.medium.pointSize + Tokens.padding.small * 2

        Behavior on color {
            CAnim {}
        }

        StyledRect {
            readonly property real nonAnimWidth: root.pressed ? implicitHeight * 1.2 : implicitHeight

            radius: Tokens.rounding.full
            color: {
                if (root.disabled)
                    return root.checked ? Colours.palette.m3surface : Qt.alpha(Colours.palette.m3onSurface, 0.12);
                return root.checked ? Colours.palette.m3onPrimary : Colours.layer(Colours.palette.m3outline, root.cLayer + 1);
            }

            x: root.checked ? parent.implicitWidth - nonAnimWidth - Tokens.padding.extraSmall / 2 : Tokens.padding.extraSmall / 2
            implicitWidth: nonAnimWidth
            implicitHeight: parent.implicitHeight - Tokens.padding.extraSmall
            anchors.verticalCenter: parent.verticalCenter

            border.width: root.checked ? 0 : 1
            border.color: root.disabled ? Qt.alpha(Colours.palette.m3onSurface, 0.1) : Colours.panelBorder

            Behavior on color {
                CAnim {}
            }

            StyledRect {
                anchors.fill: parent
                radius: parent.radius

                color: root.checked ? Colours.palette.m3primary : Colours.palette.m3onSurface
                opacity: root.pressed ? Colours.pressedStateOpacity : root.hovered ? Colours.hoverStateOpacity : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
            }

            Behavior on x {
                Anim {
                    type: Anim.FastSpatial
                }
            }

            Behavior on implicitWidth {
                Anim {
                    type: Anim.FastSpatial
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        enabled: false
    }
}
