import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    required property ScreenState screenState

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.bottomMargin: -Tokens.spacing.medium
            spacing: Tokens.spacing.medium
            z: 1

            MaterialIcon {
                Layout.topMargin: Math.round(fontInfo.pointSize * 0.12)
                text: "lyrics"
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                Layout.fillWidth: true
                text: qsTr("Lyrics")
                font: Tokens.font.title.medium
            }

            IconButton {
                type: IconButton.Text
                isToggle: true
                isRound: true
                checked: root.screenState.dashboardLyrics
                icon: "view_sidebar"
                ToolTip.visible: hovered
                ToolTip.text: checked ? qsTr("Hide lyrics drawer") : qsTr("Show lyrics drawer")
                onClicked: root.screenState.dashboardLyrics = internalChecked
            }

            IconButton {
                type: IconButton.Text
                isToggle: true
                isRound: true
                checked: root.screenState.dashboardLyricsExpanded
                icon: "view_agenda"
                ToolTip.visible: hovered
                ToolTip.text: checked ? qsTr("Use single-line lyrics") : qsTr("Show full lyrics")
                onClicked: root.screenState.dashboardLyricsExpanded = internalChecked
            }

            IconButton {
                type: IconButton.Text
                isToggle: true
                isRound: true
                checked: root.screenState.dashboardLyricsPinned
                icon: "push_pin"
                ToolTip.visible: hovered
                ToolTip.text: checked ? qsTr("Unpin lyrics") : qsTr("Pin lyrics")
                onClicked: root.screenState.dashboardLyricsPinned = internalChecked
            }

            LyricsInfo {}
        }

        LyricList {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        SplitButton {
            Layout.alignment: Qt.AlignHCenter

            type: SplitButton.Tonal
            disabled: !Players.list.length
            active: menuItems.find(m => m.modelData === Players.active) ?? menuItems[0] ?? null
            menu.onItemSelected: item => Players.manualActive = (item as PlayerItem).modelData

            menuItems: playerList.instances
            fallbackIcon: "music_off"
            fallbackText: qsTr("No players")

            minLeftWidth: layout.width - expandBtn.implicitWidth - spacing
            label.Layout.maximumWidth: minLeftWidth - iconLabel.implicitWidth - textRow.spacing - textRow.anchors.horizontalCenterOffset / 2 - horizontalPadding * 2
            label.elide: Text.ElideRight

            stateLayer.disabled: true
            menuOnTop: true

            Variants {
                id: playerList

                model: Players.list

                PlayerItem {}
            }
        }
    }

    component PlayerItem: MenuItem {
        required property MprisPlayer modelData

        icon: modelData === Players.active ? "check" : ""
        text: Players.getIdentity(modelData)
        activeIcon: "animated_images"
    }
}
