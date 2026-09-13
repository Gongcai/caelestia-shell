pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    required property int index
    required property DesktopEntry modelData
    required property GridView view

    signal activated(DesktopEntry entry)

    readonly property bool selected: GridView.isCurrentItem
    readonly property bool favourite: Strings.testRegexList(GlobalConfig.launcher.favouriteApps, modelData.id)

    implicitWidth: view.cellWidth
    implicitHeight: view.cellHeight

    scale: stateLayer.pressed ? 0.94 : 1

    StyledRect {
        id: tile

        anchors.centerIn: parent
        implicitWidth: Math.min(root.width - Tokens.spacing.small, 142)
        implicitHeight: Math.min(root.height - Tokens.spacing.small, 140)

        radius: Tokens.rounding.extraLarge
        color: root.selected ? Colours.accentContainer : Qt.alpha(Colours.palette.m3onSurface, 0.025)
        border.width: root.selected ? 1 : 0
        border.color: Qt.alpha(Colours.accent, 0.45)

        StateLayer {
            id: stateLayer

            radius: tile.radius
            onEntered: root.view.currentIndex = root.index
            onClicked: root.activated(root.modelData)
        }

        Item {
            id: iconWrapper

            anchors.top: parent.top
            anchors.topMargin: Tokens.padding.medium
            anchors.horizontalCenter: parent.horizontalCenter

            implicitWidth: Math.min(82, tile.width * 0.58)
            implicitHeight: implicitWidth

            IconImage {
                anchors.fill: parent
                asynchronous: true
                source: Quickshell.iconPath(root.modelData.icon, "image-missing")
            }

            Loader {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                active: root.favourite

                sourceComponent: StyledRect {
                    implicitWidth: favouriteIcon.implicitWidth + Tokens.padding.small
                    implicitHeight: implicitWidth
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3primary

                    MaterialIcon {
                        id: favouriteIcon

                        anchors.centerIn: parent
                        text: "favorite"
                        fill: 1
                        color: Colours.palette.m3onPrimary
                        fontStyle: Tokens.font.icon.small
                    }
                }
            }
        }

        StyledText {
            anchors.top: iconWrapper.bottom
            anchors.topMargin: Tokens.spacing.medium
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Tokens.padding.small
            anchors.rightMargin: Tokens.padding.small

            text: root.modelData.name
            color: Colours.palette.m3onSurface
            font: Tokens.font.label.medium
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 1
        }
    }

    Behavior on scale {
        Anim {
            type: Anim.FastSpatial
        }
    }
}
