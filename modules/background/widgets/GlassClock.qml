pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property DesktopBackdrop desktopBackdrop
    required property Item motionItem
    required property real absX
    required property real absY
    readonly property real widgetScale: Math.max(0.5, Math.min(2, Config.background.desktopClock.scale))
    readonly property bool analog: Config.background.desktopClock.style === "analog"
    readonly property bool showSeconds: Config.background.desktopClock.showSeconds && !GameMode.enabled

    implicitWidth: 280 * widgetScale
    implicitHeight: implicitWidth

    DesktopWidgetSurface {
        id: surface

        anchors.fill: parent
        desktopBackdrop: root.desktopBackdrop
        transformItem: root.motionItem
        sampleX: root.absX
        sampleY: root.absY
        radius: 64 * root.widgetScale
    }

    ClockTicks {
        anchors.fill: parent
        color: surface.foreground
        radius: surface.radius
        circular: root.analog
        second: root.showSeconds ? Time.seconds : -1
    }

    Loader {
        anchors.fill: parent
        sourceComponent: root.analog ? analogFace : digitalFace
    }

    Component {
        id: digitalFace

        Item {
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.24
                text: GlobalConfig.services.useTwelveHourClock ? Time.amPmStr : Time.date.toLocaleDateString(Qt.locale(I18n.language), "dddd")
                color: surface.secondaryForeground
                font: Tokens.font.body.builders.small.scale(root.widgetScale).build()
            }

            StyledText {
                anchors.centerIn: parent
                width: parent.width * 0.76
                horizontalAlignment: Text.AlignHCenter
                text: `${Time.hourStr}:${Time.minuteStr}`
                color: surface.foreground
                font: Tokens.font.clock.size(48 * root.widgetScale).weight(Font.Light).letterSpacing(-2 * root.widgetScale).build()
                fontSizeMode: Text.Fit
                minimumPixelSize: 24 * root.widgetScale
                maximumLineCount: 1
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.67
                text: Time.date.toLocaleDateString(Qt.locale(I18n.language), qsTr("MMM d"))
                color: surface.secondaryForeground
                font: Tokens.font.body.builders.small.scale(root.widgetScale).build()
            }
        }
    }

    Component {
        id: analogFace

        Item {
            id: face

            Repeater {
                model: 12

                StyledText {
                    required property int index

                    x: face.width / 2 + Math.sin(index * Math.PI / 6) * face.width * 0.31 - width / 2
                    y: face.height / 2 - Math.cos(index * Math.PI / 6) * face.height * 0.31 - height / 2
                    text: index || 12
                    color: surface.secondaryForeground
                    font: Tokens.font.body.builders.large.scale(root.widgetScale).build()
                }
            }

            ClockHand {
                length: face.height * 0.22
                thickness: 6 * root.widgetScale
                angle: (Time.hours % 12 + Time.minutes / 60) * 30
            }

            ClockHand {
                length: face.height * 0.32
                thickness: 4 * root.widgetScale
                angle: (Time.minutes + (root.showSeconds ? Time.seconds / 60 : 0)) * 6
            }

            ClockHand {
                visible: root.showSeconds
                length: face.height * 0.36
                thickness: 1.5 * root.widgetScale
                angle: Time.seconds * 6
                color: Colours.palette.m3primary
            }

            Rectangle {
                anchors.centerIn: parent
                width: 10 * root.widgetScale
                height: width
                radius: width / 2
                color: root.showSeconds ? Colours.palette.m3primary : surface.foreground
            }
        }
    }

    component ClockHand: Rectangle {
        id: hand

        required property real length
        required property real thickness
        required property real angle

        x: (parent.width - width) / 2
        y: parent.height / 2 - length
        width: thickness
        height: length + 9 * root.widgetScale
        radius: width / 2
        color: surface.foreground
        antialiasing: true
        transform: Rotation {
            origin.x: hand.width / 2
            origin.y: hand.length
            angle: hand.angle
        }
    }
}
