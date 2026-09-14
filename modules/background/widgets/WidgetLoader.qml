pragma ComponentBehavior: Bound

import QtQuick
import qs.components

Item {
    id: root

    property string position: "bottom-right"
    property real horizontalOffset
    property real verticalOffset
    property real edgeMargin
    property real leftEdgeMargin: edgeMargin
    property alias active: widgetLoader.active
    property alias asynchronous: widgetLoader.asynchronous
    property alias sourceComponent: widgetLoader.sourceComponent
    readonly property alias item: widgetLoader.item
    readonly property Item interactionTarget: dragContent
    readonly property real visualOffsetX: dragContent.x
    readonly property real visualOffsetY: dragContent.y
    readonly property bool dragging: dragArea.dragging

    signal moveRequested(deltaX: real, deltaY: real)
    signal contentSizeChanged

    onWidthChanged: Qt.callLater(contentSizeChanged)
    onHeightChanged: Qt.callLater(contentSizeChanged)

    implicitWidth: widgetLoader.implicitWidth
    implicitHeight: widgetLoader.implicitHeight

    anchors.leftMargin: leftEdgeMargin + horizontalOffset
    anchors.rightMargin: edgeMargin - horizontalOffset
    anchors.horizontalCenterOffset: horizontalOffset
    anchors.topMargin: edgeMargin + verticalOffset
    anchors.bottomMargin: edgeMargin - verticalOffset
    anchors.verticalCenterOffset: verticalOffset

    state: position
    states: [
        State {
            name: "top-left"

            AnchorChanges {
                target: root
                anchors.top: parent.top
                anchors.left: parent.left
            }
        },
        State {
            name: "top-center"

            AnchorChanges {
                target: root
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
            }
        },
        State {
            name: "top-right"

            AnchorChanges {
                target: root
                anchors.top: parent.top
                anchors.right: parent.right
            }
        },
        State {
            name: "middle-left"

            AnchorChanges {
                target: root
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
            }
        },
        State {
            name: "middle-center"

            AnchorChanges {
                target: root
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
            }
        },
        State {
            name: "middle-right"

            AnchorChanges {
                target: root
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
            }
        },
        State {
            name: "bottom-left"

            AnchorChanges {
                target: root
                anchors.bottom: parent.bottom
                anchors.left: parent.left
            }
        },
        State {
            name: "bottom-center"

            AnchorChanges {
                target: root
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
            }
        },
        State {
            name: "bottom-right"

            AnchorChanges {
                target: root
                anchors.bottom: parent.bottom
                anchors.right: parent.right
            }
        }
    ]

    transitions: Transition {
        AnchorAnim {}
    }

    Item {
        id: dragContent

        width: root.width
        height: root.height
        transformOrigin: Item.Center
        scale: root.dragging ? 1.03 : 1

        Loader {
            id: widgetLoader

            anchors.fill: parent
        }

        MouseArea {
            id: dragArea

            property bool dragging

            anchors.fill: parent
            // Stay below the widget so its buttons receive ordinary clicks.
            // Empty parts of the card still support press-and-hold dragging.
            z: -1
            acceptedButtons: Qt.LeftButton
            hoverEnabled: true
            preventStealing: true
            pressAndHoldInterval: 500
            cursorShape: dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor

            drag.target: dragContent
            drag.threshold: dragging ? 0 : 100000

            onPressed: {
                dragContent.x = 0;
                dragContent.y = 0;
            }
            onPressAndHold: dragging = true
            onReleased: {
                const deltaX = dragContent.x;
                const deltaY = dragContent.y;
                dragging = false;
                root.moveRequested(deltaX, deltaY);
                dragContent.x = 0;
                dragContent.y = 0;
            }
            onCanceled: {
                dragging = false;
                dragContent.x = 0;
                dragContent.y = 0;
            }
        }

        Behavior on scale {
            Anim {
                type: Anim.FastEffects
            }
        }
    }
}
