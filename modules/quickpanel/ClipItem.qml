pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.images
import qs.services

Item {
    id: root

    required property var modelData
    required property ScreenState screenState

    readonly property bool image: modelData.isImage
    readonly property bool hasThumb: image && !!Clipboard.readyThumbs[modelData.id]

    readonly property int thumbSize: 40

    implicitHeight: 56

    anchors.left: parent?.left
    anchors.right: parent?.right

    Component.onCompleted: Clipboard.requestThumb(root.modelData)

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: Clipboard.copy(root.modelData, root.screenState)
    }

    StyledClippingRect {
        id: thumb

        anchors.left: parent.left
        anchors.leftMargin: Tokens.padding.medium
        anchors.verticalCenter: parent.verticalCenter

        width: thumbSize
        height: thumbSize
        radius: Tokens.rounding.medium

        color: Colours.tPalette.m3surfaceContainerHigh

        Loader {
            anchors.fill: parent

            active: root.hasThumb

            sourceComponent: CachingImage {
                path: Clipboard.thumbPath(root.modelData)
                fillMode: Image.PreserveAspectFit
            }
        }

        MaterialIcon {
            anchors.centerIn: parent

            visible: !root.hasThumb
            text: root.image ? "image" : "content_paste"
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.builders.medium.build()
        }
    }

    Column {
        anchors.left: thumb.right
        anchors.right: remove.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.spacing.medium

        spacing: 2

        StyledText {
            width: parent.width

            text: root.image ? qsTr("Image") : root.modelData.preview
            font: Tokens.font.body.medium
            color: Colours.palette.m3onSurface

            elide: Text.ElideRight
        }

        StyledText {
            width: parent.width

            text: root.image ? `${root.modelData.dimensions} · ${root.modelData.size} ${root.modelData.format.toUpperCase()}` : qsTr("Text")
            font: Tokens.font.body.small
            color: Colours.palette.m3outline

            elide: Text.ElideRight
        }
    }

    IconButton {
        id: remove

        anchors.right: parent.right
        anchors.rightMargin: Tokens.padding.extraSmall
        anchors.verticalCenter: parent.verticalCenter

        icon: "close"
        type: IconButton.Text
        onClicked: Clipboard.remove(root.modelData)
    }
}
