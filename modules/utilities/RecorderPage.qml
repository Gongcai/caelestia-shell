pragma ComponentBehavior: Bound

import "cards"
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls

ColumnLayout {
    id: root

    required property var props
    required property ScreenState screenState

    signal back

    spacing: Tokens.spacing.medium

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        IconButton {
            type: IconButton.Text
            isRound: true
            icon: "arrow_back"
            onClicked: root.back()
        }

        StyledText {
            Layout.fillWidth: true
            text: qsTr("Screen Recording")
            font: Tokens.font.title.medium
        }
    }

    Record {
        Layout.fillWidth: true
        props: root.props
        screenState: root.screenState
    }
}
