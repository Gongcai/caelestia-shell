import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var list
    readonly property string query: list.search.text.slice(`${GlobalConfig.launcher.actionPrefix}search `.length).trim()

    function onClicked(): void {
        if (!query)
            return;

        Quickshell.execDetached([
            "microsoft-edge-stable",
            `https://www.bing.com/search?q=${encodeURIComponent(query)}`
        ]);
        root.list.screenState.launcher = false;
    }

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.large
        enabled: root.query.length > 0
        onClicked: root.onClicked()
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: Tokens.padding.medium

        spacing: Tokens.spacing.medium

        MaterialIcon {
            text: "travel_explore"
            color: root.query ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.extraLarge
            Layout.alignment: Qt.AlignVCenter
        }

        StyledText {
            text: root.query ? qsTr("Search Bing for \"%1\"").arg(root.query) : qsTr("Type a web search query")
            color: root.query ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
            elide: Text.ElideRight

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
