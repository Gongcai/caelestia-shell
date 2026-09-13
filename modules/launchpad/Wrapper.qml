pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState

    readonly property bool shouldBeActive: screenState.launchpad
    property real reveal: shouldBeActive ? 1 : 0

    function close(): void {
        screenState.launchpad = false;
    }

    function moveCurrent(delta: int): void {
        if (grid.count === 0)
            return;

        grid.currentIndex = Math.max(0, Math.min(grid.count - 1, grid.currentIndex + delta));
        grid.positionViewAtIndex(grid.currentIndex, GridView.Contain);
    }

    function launch(entry: DesktopEntry): void {
        Apps.launch(entry);
        close();
    }

    function launchCurrent(): void {
        const entry = grid.currentItem?.modelData;
        if (entry)
            launch(entry);
    }

    onShouldBeActiveChanged: {
        if (shouldBeActive) {
            search.clear();
            grid.currentIndex = grid.count > 0 ? 0 : -1;
            Qt.callLater(() => search.forceActiveFocus());
        }
    }

    visible: shouldBeActive || reveal > 0
    enabled: shouldBeActive
    opacity: reveal
    z: 100

    Keys.onEscapePressed: close()

    StyledRect {
        anchors.fill: parent
        color: Colours.tPalette.m3surfaceDim

        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(Colours.palette.m3scrim, Colours.light ? 0.12 : 0.2)
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Item {
        id: content

        anchors.fill: parent
        anchors.leftMargin: Math.max(Tokens.padding.extraLarge, root.width * 0.055)
        anchors.rightMargin: anchors.leftMargin
        anchors.topMargin: Math.max(Tokens.padding.extraLargeIncreased, root.height * 0.055)
        anchors.bottomMargin: Math.max(Tokens.padding.large, root.height * 0.035)

        scale: 0.94 + root.reveal * 0.06

        Column {
            id: header

            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(560, parent.width)
            spacing: Tokens.spacing.large

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Applications")
                color: Colours.palette.m3onSurface
                font: Tokens.font.headline.builders.large.weight(Font.DemiBold).build()
            }

            SearchBar {
                id: search

                width: parent.width
                placeholderText: qsTr("Search applications")
                font: Tokens.font.body.medium
                topPadding: Tokens.padding.medium
                bottomPadding: Tokens.padding.medium

                onAccepted: root.launchCurrent()
                Keys.onEscapePressed: root.close()
                Keys.onPressed: event => {
                    const columns = grid.columns;
                    if (event.key === Qt.Key_Left) {
                        root.moveCurrent(-1);
                    } else if (event.key === Qt.Key_Right) {
                        root.moveCurrent(1);
                    } else if (event.key === Qt.Key_Up) {
                        root.moveCurrent(-columns);
                    } else if (event.key === Qt.Key_Down) {
                        root.moveCurrent(columns);
                    } else if (event.key === Qt.Key_Home) {
                        grid.currentIndex = grid.count > 0 ? 0 : -1;
                        grid.positionViewAtBeginning();
                    } else if (event.key === Qt.Key_End) {
                        grid.currentIndex = grid.count - 1;
                        grid.positionViewAtEnd();
                    } else {
                        return;
                    }
                    event.accepted = true;
                }
            }
        }

        GridView {
            id: grid

            readonly property int columns: Math.max(4, Math.min(10, Math.floor(width / 142)))

            anchors.top: header.bottom
            anchors.topMargin: Tokens.spacing.extraLargeIncreased
            anchors.bottom: footer.top
            anchors.bottomMargin: Tokens.spacing.large
            anchors.horizontalCenter: parent.horizontalCenter

            width: Math.min(parent.width, 1460)
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            keyNavigationEnabled: false

            cellWidth: width / columns
            cellHeight: 150
            currentIndex: count > 0 ? 0 : -1

            model: ScriptModel {
                values: Apps.search(search.text)
                onValuesChanged: grid.currentIndex = values.length > 0 ? 0 : -1
            }

            delegate: AppTile {
                view: grid
                onActivated: entry => root.launch(entry)
            }

            add: Transition {
                ParallelAnimation {
                    Anim {
                        property: "opacity"
                        from: 0
                        to: 1
                        type: Anim.DefaultEffects
                    }
                    Anim {
                        property: "scale"
                        from: 0.8
                        to: 1
                        type: Anim.FastSpatial
                    }
                }
            }

            displaced: Transition {
                Anim {
                    properties: "x,y"
                    type: Anim.StandardSmall
                }
            }
        }

        Column {
            anchors.centerIn: grid
            spacing: Tokens.spacing.medium
            opacity: grid.count === 0 ? 1 : 0
            scale: grid.count === 0 ? 1 : 0.9

            MaterialIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "search_off"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).build()
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("No applications found")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.title.medium
            }

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }

            Behavior on scale {
                Anim {}
            }
        }

        Row {
            id: footer

            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Tokens.spacing.large

            StyledText {
                text: qsTr("%1 applications").arg(grid.count)
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.medium
            }

            StyledText {
                text: qsTr("Arrow keys to navigate · Enter to open · Esc to close")
                color: Colours.palette.m3outline
                font: Tokens.font.label.medium
            }
        }

    }

    Behavior on reveal {
        Anim {
            type: Anim.FastSpatial
        }
    }
}
