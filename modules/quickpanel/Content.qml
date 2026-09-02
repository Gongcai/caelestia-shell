pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.containers
import qs.services

Item {
    id: root

    required property ScreenState screenState

    readonly property int padding: Tokens.padding.large
    readonly property int panelWidth: 460
    readonly property int maxListHeight: 360
    readonly property int rowHeight: 56
    readonly property int rowSpacing: Tokens.spacing.small

    // Wiping is irreversible, so the button has to be pressed twice.
    property bool wipeArmed: false

    function copyCurrent(): void {
        if (list.currentItem)
            Clipboard.copy(list.currentItem.modelData, root.screenState);
    }

    implicitWidth: panelWidth + padding * 2
    implicitHeight: padding * 2 + header.height + search.height + (list.count > 0
        ? Math.min(maxListHeight, list.count * rowHeight + (list.count - 1) * rowSpacing)
        : empty.implicitHeight) + Tokens.spacing.medium * 2

    Component.onCompleted: {
        Clipboard.reload();

        if (Clipboard.focusOnOpen) {
            Clipboard.focusOnOpen = false;
            search.forceActiveFocus();
        }

    }

    Column {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.padding

        spacing: Tokens.spacing.medium

        Item {
            id: header

            width: parent.width
            height: Math.max(title.implicitHeight, count.implicitHeight, wipe.implicitHeight)

            StyledText {
                id: title

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                text: qsTr("Clipboard")
                font: Tokens.font.title.small
            }

            StyledText {
                id: count

                anchors.left: title.right
                anchors.leftMargin: Tokens.spacing.medium
                anchors.verticalCenter: parent.verticalCenter

                text: Clipboard.list.length
                font: Tokens.font.label.medium
                color: Colours.palette.m3outline
            }

            IconButton {
                id: wipe

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                icon: root.wipeArmed ? "delete_forever" : "delete_sweep"
                type: IconButton.Text
                activeOnColour: root.wipeArmed ? Colours.palette.m3error : Colours.palette.m3primary
                onClicked: {
                    if (root.wipeArmed) {
                        root.wipeArmed = false;
                        Clipboard.wipe();
                    } else {
                        root.wipeArmed = true;
                        armTimer.restart();
                    }
                }
            }
        }

        SearchBar {
            id: search

            width: parent.width

            placeholderText: qsTr("Search clipboard history")

            onAccepted: root.copyCurrent()
            Keys.onUpPressed: list.decrementCurrentIndex()
            Keys.onDownPressed: list.incrementCurrentIndex()
            Keys.onEscapePressed: root.screenState.quickpanel = false
        }

        Item {
            id: listArea

            // ListView contentHeight re-emits when the viewport changes, so deriving the
            // wrapper height from it would loop. Compute the height arithmetically instead;
            // the launcher does the same and all rows have a fixed implicitHeight.
            width: parent.width
            height: list.count > 0
                ? Math.min(root.maxListHeight, list.count * root.rowHeight + (list.count - 1) * root.rowSpacing)
                : empty.implicitHeight

            VerticalFadeListView {
                id: list

                anchors.fill: parent

                spacing: Tokens.spacing.small
                clip: true

                model: ScriptModel {
                    values: Clipboard.query(search.text)
                    onValuesChanged: list.currentIndex = 0
                }

                currentIndex: 0
                visible: list.count > 0

                preferredHighlightBegin: 0
                preferredHighlightEnd: height
                highlightRangeMode: ListView.ApplyRange
                highlightFollowsCurrentItem: false

                highlight: StyledRect {
                    radius: Tokens.rounding.large
                    color: Colours.palette.m3onSurface
                    opacity: 0.08

                    y: list.currentItem?.y ?? 0
                    implicitWidth: list.width
                    implicitHeight: list.currentItem?.implicitHeight ?? 0

                    Behavior on y {
                        Anim {}
                    }
                }

                delegate: ClipItem {
                    screenState: root.screenState
                }

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: list
                }
            }

            Column {
                id: empty

                anchors.centerIn: parent

                visible: list.count === 0
                spacing: Tokens.spacing.small

                MaterialIcon {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: "content_paste_off"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.builders.extraLarge.build()
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter

                    text: search.text ? qsTr("No matches") : qsTr("No clipboard history")
                    font: Tokens.font.body.builders.large.weight(Font.Medium).build()
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }
    }

    Timer {
        id: armTimer

        interval: 3000
        onTriggered: root.wipeArmed = false
    }
}
