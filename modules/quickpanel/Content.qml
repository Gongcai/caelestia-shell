pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components

Item {
    id: root

    required property ScreenState screenState

    readonly property real nonAnimHeight: placeholder.implicitHeight + padding * 2

    readonly property int padding: Tokens.padding.large

    implicitWidth: placeholder.implicitWidth + padding * 2
    implicitHeight: nonAnimHeight

    Item {
        id: placeholder

        anchors.fill: parent
        anchors.margins: root.padding

        implicitWidth: 360
        implicitHeight: 200

        StyledText {
            anchors.centerIn: parent
            text: qsTr("Quickpanel")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.title.large
        }
    }
}
