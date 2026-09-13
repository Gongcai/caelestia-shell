pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia
import Caelestia.Components
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.components.filedialog
import qs.services

Item {
    id: root

    required property FileDialog filePicker
    property string selectedDeviceId

    function deviceIcon(iconName, deviceType) {
        if (iconName.startsWith("smartphone") || deviceType === "phone")
            return "smartphone";
        if (iconName.startsWith("computer") || deviceType === "desktop" || deviceType === "laptop")
            return "computer";
        return "devices_other";
    }

    Connections {
        target: root.filePicker

        function onAccepted(path: string): void {
            if (root.selectedDeviceId)
                KdeConnect.sendFile(root.selectedDeviceId, path);
        }
    }

    implicitWidth: 840
    implicitHeight: content.implicitHeight

    ColumnLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Tokens.spacing.medium

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.large
            Layout.rightMargin: Tokens.padding.large

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    text: qsTr("KDE Connect")
                    font: Tokens.font.title.medium
                    color: Colours.palette.m3onSurface
                }

                StyledText {
                    text: KdeConnect.available
                        ? qsTr("%1 device(s), %2 connected").arg(KdeConnect.deviceCount).arg(KdeConnect.connectedCount)
                        : qsTr("KDE Connect is not running")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            IconButton {
                type: IconButton.Tonal
                icon: "refresh"
                isRound: true
                onClicked: KdeConnect.refresh()
            }
        }

        StyledRect {
            Layout.fillWidth: true
            visible: !KdeConnect.available || KdeConnect.deviceCount === 0
            implicitHeight: emptyColumn.implicitHeight + Tokens.padding.extraLarge * 2
            radius: Tokens.rounding.extraLarge
            color: Colours.tPalette.m3surfaceContainer
            materialBlur: true

            ColumnLayout {
                id: emptyColumn

                anchors.centerIn: parent
                spacing: Tokens.spacing.small

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: KdeConnect.available ? "devices_other" : "cloud_off"
                    fontStyle: Tokens.font.icon.builders.extraLarge.scale(1.5).build()
                    color: Colours.palette.m3secondary
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: KdeConnect.available ? qsTr("No paired devices") : qsTr("KDE Connect is unavailable")
                    font: Tokens.font.title.small
                    color: Colours.palette.m3onSurface
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: KdeConnect.available ? qsTr("Pair a phone with KDE Connect to use these controls") : qsTr("Start kdeconnectd to connect your devices")
                    font: Tokens.font.body.small
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }

        Repeater {
            model: KdeConnect

            delegate: StyledRect {
                id: deviceCard

                required property string deviceId
                required property string name
                required property string deviceType
                required property string iconName
                required property bool reachable
                required property bool paired
                required property bool pairRequested
                required property bool pairRequestedByPeer
                required property int batteryCharge
                required property bool batteryCharging
                required property list<string> plugins

                Layout.fillWidth: true
                implicitHeight: deviceColumn.implicitHeight + Tokens.padding.large * 2
                radius: Tokens.rounding.extraLarge
                color: Colours.tPalette.m3surfaceContainer
                materialBlur: true

                ColumnLayout {
                    id: deviceColumn

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Tokens.padding.large
                    spacing: Tokens.spacing.medium

                    RowLayout {
                        Layout.fillWidth: true

                        MaterialIcon {
                            text: root.deviceIcon(deviceCard.iconName, deviceCard.deviceType)
                            fontStyle: Tokens.font.icon.builders.extraLarge.scale(1.4).build()
                            color: deviceCard.reachable ? Colours.palette.m3primary : Colours.palette.m3outline
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                Layout.fillWidth: true
                                text: deviceCard.name
                                font: Tokens.font.title.small
                                color: Colours.palette.m3onSurface
                                elide: Text.ElideRight
                            }

                            StyledText {
                                text: deviceCard.reachable ? qsTr("Connected") : deviceCard.paired ? qsTr("Paired, offline") : qsTr("Not paired")
                                font: Tokens.font.body.small
                                color: deviceCard.reachable ? Colours.palette.m3tertiary : Colours.palette.m3onSurfaceVariant
                            }
                        }

                        StyledText {
                            visible: deviceCard.batteryCharge >= 0
                            text: deviceCard.batteryCharge + "%"
                            font: Tokens.font.body.builders.medium.weight(Font.DemiBold).build()
                            color: Colours.palette.m3secondary
                        }
                    }

                    StyledProgressBar {
                        Layout.fillWidth: true
                        visible: deviceCard.batteryCharge >= 0
                        value: deviceCard.batteryCharge / 100
                        indeterminate: false
                    }

                    ButtonRow {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.extraSmall

                        IconTextButton {
                            visible: !deviceCard.paired && !deviceCard.pairRequested
                            icon: "link"
                            text: qsTr("Pair")
                            type: IconTextButton.Tonal
                            onClicked: KdeConnect.requestPairing(deviceCard.deviceId)
                        }

                        IconTextButton {
                            visible: deviceCard.pairRequestedByPeer
                            icon: "check"
                            text: qsTr("Accept")
                            type: IconTextButton.Filled
                            onClicked: KdeConnect.acceptPairing(deviceCard.deviceId)
                        }

                        IconTextButton {
                            visible: deviceCard.pairRequested
                            icon: "close"
                            text: qsTr("Cancel")
                            type: IconTextButton.Tonal
                            onClicked: KdeConnect.cancelPairing(deviceCard.deviceId)
                        }

                        IconTextButton {
                            visible: deviceCard.paired
                            icon: "link_off"
                            text: qsTr("Unpair")
                            type: IconTextButton.Tonal
                            onClicked: KdeConnect.unpair(deviceCard.deviceId)
                        }

                        IconTextButton {
                            visible: deviceCard.reachable && deviceCard.paired
                            icon: "notifications_active"
                            text: qsTr("Ping")
                            type: IconTextButton.Tonal
                            onClicked: KdeConnect.ping(deviceCard.deviceId)
                        }

                        IconTextButton {
                            visible: deviceCard.reachable && deviceCard.paired && deviceCard.plugins.includes("kdeconnect_findmyphone")
                            icon: "ring_volume"
                            text: qsTr("Ring")
                            type: IconTextButton.Tonal
                            onClicked: KdeConnect.ring(deviceCard.deviceId)
                        }
                    }

                    ButtonRow {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.extraSmall

                        IconTextButton {
                            visible: deviceCard.reachable && deviceCard.paired && deviceCard.plugins.includes("kdeconnect_clipboard")
                            icon: "content_paste"
                            text: qsTr("Send clipboard")
                            type: IconTextButton.Tonal
                            onClicked: KdeConnect.sendClipboard(deviceCard.deviceId)
                        }

                        IconTextButton {
                            visible: deviceCard.reachable && deviceCard.paired && deviceCard.plugins.includes("kdeconnect_share")
                            icon: "upload_file"
                            text: qsTr("Send file")
                            type: IconTextButton.Tonal
                            onClicked: {
                                root.selectedDeviceId = deviceCard.deviceId;
                                root.filePicker.open();
                            }
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: KdeConnect

        function onOperationFinished(success: bool, message: string): void {
            Toaster.toast(success ? qsTr("KDE Connect") : qsTr("KDE Connect error"), message, success ? "devices_other" : "error");
        }
    }
}
