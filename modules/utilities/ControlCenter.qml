pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.modules.bar.popouts as BarPopouts
import qs.modules.nexus
import qs.services
import qs.utils

ColumnLayout {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts

    readonly property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
    readonly property var connectedBluetoothDevices: [...Bluetooth.devices.values].filter(device => device.connected) // qmllint disable missing-property

    signal openRecorder

    function openSettings(page: string): void {
        screenState.utilities = false;
        popouts.detach(page);
    }

    spacing: Tokens.spacing.medium

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        StyledText {
            Layout.fillWidth: true
            text: qsTr("Control Centre")
            font: Tokens.font.title.medium
        }

        IconButton {
            type: IconButton.Text
            isRound: true
            icon: "settings"
            onClicked: {
                root.screenState.utilities = false;
                WindowFactory.create();
            }
        }
    }

    StyledRect {
        Layout.fillWidth: true
        implicitHeight: connections.implicitHeight + Tokens.padding.large * 2
        radius: Tokens.rounding.large
        color: Colours.tPalette.m3surfaceContainer

        ColumnLayout {
            id: connections

            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.medium

            ConnectionRow {
                icon: Nmcli.activeEthernet ? "lan" : "wifi"
                title: Nmcli.activeEthernet ? qsTr("Ethernet") : qsTr("Wi-Fi")
                subtitle: Nmcli.activeEthernet ? (Nmcli.activeConnection || qsTr("Connected")) : Nmcli.active ? Nmcli.active.ssid : Nmcli.wifiEnabled ? qsTr("Not connected") : qsTr("Off")
                checked: Nmcli.wifiEnabled || !!Nmcli.activeEthernet
                toggleEnabled: !Nmcli.activeEthernet
                onToggle: Nmcli.toggleWifi()
                onOpen: root.openSettings("network")
            }

            ConnectionRow {
                icon: "bluetooth"
                title: qsTr("Bluetooth")
                subtitle: {
                    if (!(Bluetooth.defaultAdapter?.enabled ?? false)) // qmllint disable missing-property
                        return qsTr("Off");
                    if (root.connectedBluetoothDevices.length === 1)
                        return root.connectedBluetoothDevices[0].name;
                    if (root.connectedBluetoothDevices.length > 1)
                        return qsTr("%1 connected").arg(root.connectedBluetoothDevices.length);
                    return qsTr("Not connected");
                }
                checked: Bluetooth.defaultAdapter?.enabled ?? false // qmllint disable missing-property
                onToggle: {
                    const adapter = Bluetooth.defaultAdapter; // qmllint disable missing-property
                    if (adapter)
                        adapter.enabled = !adapter.enabled;
                }
                onOpen: root.openSettings("bluetooth")
            }

            ConnectionRow {
                visible: GlobalConfig.utilities.vpn.selectedProvider.length > 0
                Layout.preferredHeight: visible ? implicitHeight : 0
                icon: "vpn_key"
                title: qsTr("VPN")
                subtitle: VPN.connecting ? qsTr("Connecting...") : VPN.connected ? (VPN.status.server || qsTr("Connected")) : qsTr("Not connected")
                checked: VPN.connected
                toggleEnabled: !VPN.connecting && !VPN.disconnecting
                onToggle: VPN.toggle()
                onOpen: root.openSettings("network")
            }
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: Tokens.spacing.medium
        rowSpacing: Tokens.spacing.medium

        StatusTile {
            icon: "notifications_off"
            title: qsTr("Do Not Disturb")
            subtitle: Notifs.dnd ? qsTr("On") : qsTr("Off")
            checked: Notifs.dnd
            onClicked: Notifs.dnd = !Notifs.dnd
        }

        StatusTile {
            icon: "gamepad"
            title: qsTr("Game Mode")
            subtitle: GameMode.enabled ? qsTr("On") : qsTr("Off")
            checked: GameMode.enabled
            onClicked: GameMode.enabled = !GameMode.enabled
        }

        StatusTile {
            visible: Config.utilities.cards.keepAwake
            icon: "coffee"
            title: qsTr("Keep Awake")
            subtitle: IdleInhibitor.enabled ? qsTr("On") : qsTr("Off")
            checked: IdleInhibitor.enabled
            onClicked: IdleInhibitor.enabled = !IdleInhibitor.enabled
        }

        StatusTile {
            icon: "mic"
            title: qsTr("Microphone")
            subtitle: Audio.sourceMuted ? qsTr("Muted") : qsTr("On")
            checked: !Audio.sourceMuted
            onClicked: {
                const source = Audio.source?.audio;
                if (source)
                    source.muted = !source.muted;
            }
        }
    }

    SliderCard {
        icon: "brightness_6"
        title: qsTr("Display")
        value: root.brightnessMonitor?.brightness ?? 0
        disabled: !root.brightnessMonitor
        onMoved: value => root.brightnessMonitor?.setBrightness(value)
    }

    SliderCard {
        icon: Audio.muted ? "volume_off" : Audio.volume < 0.5 ? "volume_down" : "volume_up"
        title: qsTr("Sound")
        value: Audio.volume
        disabled: !Audio.sink
        showDetails: true
        onIconClicked: {
            const sink = Audio.sink?.audio;
            if (sink)
                sink.muted = !sink.muted;
        }
        onMoved: value => Audio.setVolume(value)
        onOpen: root.openSettings("audio")
    }

    StyledRect {
        Layout.fillWidth: true
        visible: Config.utilities.cards.recorder
        implicitHeight: visible ? recorderRow.implicitHeight + Tokens.padding.large * 2 : 0
        radius: Tokens.rounding.large
        color: Colours.tPalette.m3surfaceContainer

        StateLayer {
            onClicked: root.openRecorder()
        }

        RowLayout {
            id: recorderRow

            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.medium

            StyledRect {
                implicitWidth: 46
                implicitHeight: 46
                radius: Tokens.rounding.full
                color: Recorder.running ? Colours.palette.m3error : Colours.palette.m3secondaryContainer

                MaterialIcon {
                    anchors.centerIn: parent
                    text: Recorder.running ? "stop_circle" : "screen_record"
                    color: Recorder.running ? Colours.palette.m3onError : Colours.palette.m3onSecondaryContainer
                    fontStyle: Tokens.font.icon.large
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: qsTr("Screen Recording")
                    font: Tokens.font.body.medium
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Recorder.paused ? qsTr("Paused") : Recorder.running ? qsTr("Recording for %1").arg(root.elapsedText(Recorder.elapsed)) : qsTr("Modes and recordings")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }
            }

            MaterialIcon {
                text: "chevron_right"
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }

    function elapsedText(elapsed: real): string {
        const hours = Math.floor(elapsed / 3600);
        const mins = Math.floor((elapsed % 3600) / 60);
        const secs = Math.floor(elapsed % 60).toString().padStart(2, "0");
        return hours > 0 ? `${hours}:${mins.toString().padStart(2, "0")}:${secs}` : `${mins}:${secs}`;
    }

    component ConnectionRow: RowLayout {
        id: connection

        required property string icon
        required property string title
        required property string subtitle
        required property bool checked
        property bool toggleEnabled: true

        signal toggle
        signal open

        Layout.fillWidth: true
        spacing: Tokens.spacing.medium

        IconButton {
            type: IconButton.Tonal
            isToggle: true
            isRound: true
            checked: connection.checked
            disabled: !connection.toggleEnabled
            icon: connection.icon
            font: Tokens.font.icon.large
            onClicked: connection.toggle()
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: connection.title
                font: Tokens.font.body.medium
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: connection.subtitle
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }
        }

        IconButton {
            type: IconButton.Text
            isRound: true
            icon: "chevron_right"
            onClicked: connection.open()
        }
    }

    component StatusTile: StyledRect {
        id: tile

        required property string icon
        required property string title
        required property string subtitle
        required property bool checked

        signal clicked

        Layout.fillWidth: true
        Layout.preferredWidth: 1
        implicitHeight: 76
        radius: Tokens.rounding.large
        color: checked ? Colours.palette.m3secondaryContainer : Colours.tPalette.m3surfaceContainer

        StateLayer {
            color: tile.checked ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
            onClicked: tile.clicked()
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: tile.icon
                fill: tile.checked ? 1 : 0
                color: tile.checked ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: tile.title
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                StyledText {
                    text: tile.subtitle
                    color: tile.checked ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.small
                }
            }
        }
    }

    component SliderCard: StyledRect {
        id: sliderCard

        required property string icon
        required property string title
        required property real value
        property bool disabled
        property bool showDetails

        signal moved(real value)
        signal iconClicked
        signal open

        Layout.fillWidth: true
        implicitHeight: sliderLayout.implicitHeight + Tokens.padding.large * 2
        radius: Tokens.rounding.large
        color: Colours.tPalette.m3surfaceContainer

        RowLayout {
            id: sliderLayout

            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.medium

            IconButton {
                type: IconButton.Text
                isRound: true
                icon: sliderCard.icon
                disabled: sliderCard.disabled
                onClicked: sliderCard.iconClicked()
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall

                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        Layout.fillWidth: true
                        text: sliderCard.title
                        font: Tokens.font.body.small
                    }

                    StyledText {
                        text: `${Math.round(sliderCard.value * 100)}%`
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.label.small
                    }
                }

                StyledSlider {
                    Layout.fillWidth: true
                    implicitHeight: 12
                    enabled: !sliderCard.disabled
                    value: sliderCard.value
                    onInteraction: value => sliderCard.moved(value)
                }
            }

            IconButton {
                visible: sliderCard.showDetails
                Layout.preferredWidth: visible ? implicitWidth : 0
                type: IconButton.Text
                isRound: true
                icon: "chevron_right"
                onClicked: sliderCard.open()
            }
        }
    }
}
