pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates
import Caelestia
import Caelestia.Components
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services

Slider {
    id: root

    property bool wavy
    property bool animateWave
    property real waveFrequency: 6
    property int waveDuration: 1000
    property int radius: Tokens.rounding.full
    // Sequoia uses a substantial pill track with a small white thumb.
    property int trackHeight: 12
    property bool interactionOnMove: true
    readonly property bool dragging: mouse.pressed

    property color fgColour: enabled ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3onSurface, 0.38)
    property color bgColour: enabled ? Colours.palette.m3secondaryContainer : Qt.alpha(Colours.palette.m3onSurface, 0.1)

    property real pos: visualPosition
    // Keep the fill endpoint aligned with the thumb center.
    property real filledWidth: handle.x + handle.width / 2

    signal interaction(v: real)

    implicitWidth: 200
    // Reserve the thumb diameter so compact rows cannot overlap the slider.
    implicitHeight: Math.max(trackHeight, 18)

    contentItem: Item {
        anchors.fill: parent

        StyledRect {
            id: track

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            implicitHeight: Math.min(parent.height, root.trackHeight)
            opacity: 1

            radius: root.radius
            color: Qt.alpha(root.bgColour, 0.92)
        }

        StyledRect {
            id: handle

            anchors.verticalCenter: parent.verticalCenter
            x: root.visualPosition * (root.width - width)
            z: 1

            implicitWidth: mouse.pressed ? 19 : 17
            implicitHeight: mouse.pressed ? 19 : 17

            radius: Tokens.rounding.full
            color: Colours.light ? "#FFFFFF" : "#F5F5F7"

            Elevation {
                anchors.fill: parent
                radius: parent.radius
                level: mouse.pressed ? 2 : 1
            }

            Behavior on implicitHeight {
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

        Loader {
            id: filled

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, root.filledWidth)
            height: Math.min(parent.height, root.trackHeight)
            asynchronous: true

            sourceComponent: root.wavy ? waveComp : lineComp
        }

        Component {
            id: lineComp

            StyledRect {
                anchors.fill: parent

                radius: root.radius
                color: root.fgColour
            }
        }

        Component {
            id: waveComp

            WavyLine {
                lineWidth: root.height * 0.7
                frequency: root.waveFrequency
                startX: x
                fullLength: root.width
                color: root.fgColour

                width: root.filledWidth
                height: lineWidth * amplitudeMultiplier * 2 + lineWidth

                Anim on waveProgress {
                    running: true
                    paused: !root.animateWave
                    from: 0
                    to: 1
                    duration: root.waveDuration
                    easing.type: Easing.Linear
                    loops: Animation.Infinite
                }

                Behavior on color {
                    CAnim {}
                }
            }
        }
    }

    Binding {
        id: posBinding

        target: root
        property: "pos"
        value: CUtils.clamp(mouse.pressStartPos + mouse.dragMovement, 0, 1)
        when: mouse.pressed
    }

    MouseArea {
        id: mouse

        property real pressStartX
        property real pressStartPos
        property real dragMovement

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        preventStealing: true
        implicitHeight: handle.implicitHeight

        onPressed: e => {
            widthBehavior.enabled = false;
            pressStartX = e.x;
            pressStartPos = root.visualPosition;
        }
        onPositionChanged: e => {
            dragMovement = (e.x - pressStartX) / width;
            if (root.interactionOnMove)
                root.interaction(posBinding.value);
        }
        onReleased: e => {
            const clickPos = e.x / width;
            const finalPos = mouse.dragMovement !== 0 ? posBinding.value : CUtils.clamp(clickPos, 0, 1);
            root.interaction(finalPos);
            widthBehavior.enabled = true;
            dragMovement = 0;
        }
    }

    Behavior on filledWidth {
        id: widthBehavior

        Anim {}
    }
}
