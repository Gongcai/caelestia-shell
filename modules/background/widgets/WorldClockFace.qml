pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property var reading
    property string style: "numbered"
    property bool showSeconds
    readonly property real unit: width / 200
    readonly property bool valid: reading.valid === true
    readonly property bool daylight: reading.daylight ?? false
    readonly property color faceColour: daylight === Colours.light ? Colours.palette.m3surface : Colours.palette.m3onSurface
    readonly property color ink: daylight === Colours.light ? Colours.palette.m3onSurface : Colours.palette.m3surface

    implicitWidth: 200
    implicitHeight: implicitWidth

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Qt.alpha(root.faceColour, 0.92)
    }

    ClockTicks {
        anchors.fill: parent
        visible: root.valid && root.style !== "digital"
        circular: true
        radius: width / 2
        color: root.ink
    }

    Repeater {
        model: 12

        StyledText {
            required property int index

            visible: root.valid && (root.style === "numbered" || (root.style === "quarters" && index % 3 === 0))
            x: root.width / 2 + Math.sin(index * Math.PI / 6) * root.width * 0.34 - width / 2
            y: root.height / 2 - Math.cos(index * Math.PI / 6) * root.height * 0.34 - height / 2
            text: index || 12
            color: root.ink
            font: Tokens.font.body.builders.small.size(15 * root.unit).build()
        }
    }

    Hand {
        length: root.height * 0.23
        thickness: 5 * root.unit
        angle: ((root.reading.hours ?? 0) % 12 + (root.reading.minutes ?? 0) / 60) * 30
    }

    Hand {
        length: root.height * 0.34
        thickness: 3.5 * root.unit
        angle: ((root.reading.minutes ?? 0) + (root.showSeconds ? (root.reading.seconds ?? 0) / 60 : 0)) * 6
    }

    Hand {
        visible: root.valid && root.showSeconds && root.style !== "digital"
        length: root.height * 0.39
        thickness: 1.5 * root.unit
        angle: (root.reading.seconds ?? 0) * 6
        color: Colours.palette.m3primary
    }

    Rectangle {
        anchors.centerIn: parent
        visible: root.valid && root.style !== "digital"
        width: 8 * root.unit
        height: width
        radius: width / 2
        color: root.ink
    }

    StyledText {
        anchors.centerIn: parent
        width: parent.width * 0.9
        visible: !root.valid || root.style === "digital"
        horizontalAlignment: Text.AlignHCenter
        text: root.reading.time ?? "--:--"
        color: root.ink
        font: Tokens.font.clock.size(42 * root.unit).weight(Font.Light).build()
        fontSizeMode: Text.Fit
        minimumPixelSize: 20 * root.unit
    }

    component Hand: Rectangle {
        id: hand

        required property real length
        required property real thickness
        required property real angle

        visible: root.valid && root.style !== "digital"
        x: (root.width - width) / 2
        y: root.height / 2 - length
        width: thickness
        height: length + 7 * root.unit
        radius: width / 2
        color: root.ink
        antialiasing: true
        transform: Rotation {
            origin.x: hand.width / 2
            origin.y: hand.length
            angle: hand.angle
        }
    }
}
