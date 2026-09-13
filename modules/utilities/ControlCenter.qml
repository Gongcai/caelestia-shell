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

ColumnLayout {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts

    readonly property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
    readonly property var connectedBluetoothDevices: [...Bluetooth.devices.values].filter(device => device.connected) // qmllint disable missing-property
    readonly property bool twoColumns: width >= 360

    signal openRecorder

    function openSettings(page: string): void {
        screenState.utilities = false;
        popouts.detach(page);
    }

    spacing: Tokens.spacing.medium

    RowLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: Tokens.spacing.extraSmall

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

    GridLayout {
        Layout.fillWidth: true
        columns: root.twoColumns ? 2 : 1
        columnSpacing: Tokens.spacing.medium
        rowSpacing: Tokens.spacing.medium

        ConnectivityCard {
            Layout.fillWidth: true
            Layout.preferredWidth: root.twoColumns ? 3 : 1
        }

        FocusCard {
            Layout.fillWidth: true
            Layout.preferredWidth: 2
        }

        SliderCard {
            Layout.columnSpan: root.twoColumns ? 2 : 1
            Layout.fillWidth: true
            icon: "brightness_6"
            title: qsTr("Display")
            value: root.brightnessMonitor?.brightness ?? 0
            disabled: !root.brightnessMonitor
            onMoved: value => root.brightnessMonitor?.setBrightness(value)
        }

        SliderCard {
            Layout.columnSpan: root.twoColumns ? 2 : 1
            Layout.fillWidth: true
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
    }

    MediaCard {
        Layout.fillWidth: true
    }

    PanelCard {
        Layout.fillWidth: true
        visible: Config.utilities.cards.recorder
        implicitHeight: visible ? recorderRow.implicitHeight + Tokens.padding.medium * 2 : 0
        radius: Tokens.rounding.large
        color: Colours.tPalette.m3surfaceContainer
        border.width: 1
        border.color: Colours.panelBorder

        StateLayer {
            onClicked: root.openRecorder()
        }

        RowLayout {
            id: recorderRow

            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            spacing: Tokens.spacing.medium

            StyledRect {
                implicitWidth: 38
                implicitHeight: 38
                radius: Tokens.rounding.medium
                color: Recorder.running ? Colours.palette.m3error : Colours.controlFillStrong

                MaterialIcon {
                    anchors.centerIn: parent
                    text: Recorder.running ? "stop" : "screen_record"
                    color: Recorder.running ? Colours.palette.m3onError : Colours.palette.m3onSurface
                    fontStyle: Tokens.font.icon.medium
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

    component PanelCard: StyledRect {
        radius: Tokens.rounding.large
        color: Colours.tPalette.m3surfaceContainer
        materialBlur: true
        border.width: 1
        border.color: Colours.panelBorder
    }

    component ConnectivityCard: PanelCard {
        implicitHeight: connections.implicitHeight + Tokens.padding.medium * 2

        ColumnLayout {
            id: connections

            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            spacing: Tokens.spacing.small

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

    component FocusCard: PanelCard {
        implicitHeight: focusLayout.implicitHeight + Tokens.padding.medium * 2

        ColumnLayout {
            id: focusLayout

            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            spacing: Tokens.spacing.small

            FocusRow {
                Layout.fillWidth: true
                icon: "do_not_disturb_on"
                title: qsTr("Focus")
                subtitle: Notifs.dnd ? qsTr("Do Not Disturb") : qsTr("Off")
                checked: Notifs.dnd
                onClicked: Notifs.dnd = !Notifs.dnd
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 3
                columnSpacing: Tokens.spacing.extraSmall

                QuickAction {
                    Layout.fillWidth: true
                    icon: "gamepad"
                    checked: GameMode.enabled
                    onClicked: GameMode.enabled = !GameMode.enabled
                }

                QuickAction {
                    Layout.fillWidth: true
                    icon: "mic"
                    checked: !Audio.sourceMuted
                    onClicked: {
                        const source = Audio.source?.audio;
                        if (source)
                            source.muted = !source.muted;
                    }
                }

                QuickAction {
                    Layout.fillWidth: true
                    visible: Config.utilities.cards.keepAwake
                    Layout.preferredWidth: visible ? 1 : 0
                    icon: "coffee"
                    checked: IdleInhibitor.enabled
                    onClicked: IdleInhibitor.enabled = !IdleInhibitor.enabled
                }
            }
        }
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
        implicitHeight: 40
        spacing: Tokens.spacing.small

        IconButton {
            type: IconButton.Tonal
            isToggle: true
            isRound: true
            checked: connection.checked
            disabled: !connection.toggleEnabled
            icon: connection.icon
            onClicked: connection.toggle()
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: connection.title
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: connection.subtitle
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.small
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

    component FocusRow: StyledRect {
        id: focusRow

        required property string icon
        required property string title
        required property string subtitle
        required property bool checked

        signal clicked

        implicitHeight: 50
        radius: Tokens.rounding.medium
        color: checked ? Colours.selectedSurface : Colours.controlFill

        StateLayer {
            color: focusRow.checked ? Colours.selectedOnSurface : Colours.palette.m3onSurface
            onClicked: focusRow.clicked()
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Tokens.padding.small
            anchors.rightMargin: Tokens.padding.medium
            spacing: Tokens.spacing.small

            StyledRect {
                implicitWidth: 30
                implicitHeight: 30
                radius: Tokens.rounding.full
                color: focusRow.checked ? Colours.accent : Colours.controlFillStrong

                MaterialIcon {
                    anchors.centerIn: parent
                    text: focusRow.icon
                    fill: focusRow.checked ? 1 : 0
                    color: focusRow.checked ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                    fontStyle: Tokens.font.icon.small
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: focusRow.title
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: focusRow.subtitle
                    color: focusRow.checked ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.small
                    elide: Text.ElideRight
                }
            }

            MaterialIcon {
                text: "chevron_right"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.small
            }
        }
    }

    component QuickAction: StyledRect {
        id: action

        required property string icon
        required property bool checked

        signal clicked

        implicitHeight: 38
        radius: Tokens.rounding.medium
        color: checked ? Colours.selectedSurface : Colours.controlFill

        StateLayer {
            color: action.checked ? Colours.selectedOnSurface : Colours.palette.m3onSurface
            onClicked: action.clicked()
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: action.icon
            fill: action.checked ? 1 : 0
            color: action.checked ? Colours.selectedOnSurface : Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.small
        }
    }

    component SliderCard: PanelCard {
        id: sliderCard

        required property string icon
        required property string title
        required property real value
        property bool disabled
        property bool showDetails

        signal moved(real value)
        signal iconClicked
        signal open

        implicitHeight: sliderLayout.implicitHeight + Tokens.padding.medium * 2

        ColumnLayout {
            id: sliderLayout

            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            spacing: Tokens.spacing.extraSmall

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                IconButton {
                    type: IconButton.Text
                    isRound: true
                    icon: sliderCard.icon
                    disabled: sliderCard.disabled
                    onClicked: sliderCard.iconClicked()
                }

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

                IconButton {
                    visible: sliderCard.showDetails
                    Layout.preferredWidth: visible ? implicitWidth : 0
                    type: IconButton.Text
                    isRound: true
                    icon: "chevron_right"
                    onClicked: sliderCard.open()
                }
            }

            StyledSlider {
                Layout.fillWidth: true
                Layout.preferredHeight: 18
                trackHeight: 14
                enabled: !sliderCard.disabled
                value: sliderCard.value
                onInteraction: value => sliderCard.moved(value)
            }
        }
    }

    component MediaCard: PanelCard {
        implicitHeight: mediaLayout.implicitHeight + Tokens.padding.medium * 2

        RowLayout {
            id: mediaLayout

            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            spacing: Tokens.spacing.medium

            StyledRect {
                implicitWidth: 42
                implicitHeight: 42
                radius: Tokens.rounding.medium
                color: Players.active ? Colours.accentContainer : Colours.controlFill

                MaterialIcon {
                    anchors.centerIn: parent
                    text: Players.active ? "music_note" : "music_off"
                    color: Players.active ? Colours.selectedOnSurface : Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.medium
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: Players.active?.trackTitle || qsTr("No media playing")
                    font: Tokens.font.body.medium
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.fillWidth: true
                    text: Players.active ? (Players.active.trackArtist || Players.getIdentity(Players.active)) : qsTr("Choose an app to start playback")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.small
                    elide: Text.ElideRight
                }
            }

            IconButton {
                type: IconButton.Text
                isRound: true
                icon: Players.active?.isPlaying ? "pause" : "play_arrow"
                disabled: !Players.active?.canTogglePlaying
                onClicked: Players.active?.togglePlaying()
            }

            IconButton {
                type: IconButton.Text
                isRound: true
                icon: "skip_next"
                disabled: !Players.active?.canGoNext
                onClicked: Players.active?.next()
            }
        }
    }
}
