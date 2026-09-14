pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.services

Item {
    id: root

    required property DesktopBackdrop desktopBackdrop
    required property Item motionItem
    required property real absX
    required property real absY
    readonly property real widgetScale: Math.max(0.5, Math.min(2, Config.background.desktopWorldClock.scale))
    readonly property var zones: Config.background.desktopWorldClock.timeZones.length ? Config.background.desktopWorldClock.timeZones.slice(0, 4) : ["local"]

    function offsetText(reading: var): string {
        if (!reading.valid)
            return qsTr("Unknown time zone");
        const offset = reading.offsetMinutes;
        const hours = Math.abs(offset) / 60;
        const difference = offset === 0 ? qsTr("Same time") : (offset > 0 ? "+" : "−") + hours + qsTr(" h");
        if (reading.dayDifference > 0)
            return qsTr("Tomorrow · %1").arg(difference);
        if (reading.dayDifference < 0)
            return qsTr("Yesterday · %1").arg(difference);
        return difference;
    }

    implicitWidth: (zones.length === 1 ? 280 : 560) * widgetScale
    implicitHeight: 280 * widgetScale

    DesktopWidgetSurface {
        id: surface

        anchors.fill: parent
        desktopBackdrop: root.desktopBackdrop
        transformItem: root.motionItem
        sampleX: root.absX
        sampleY: root.absY
        radius: 44 * root.widgetScale
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 24 * root.widgetScale
        spacing: 16 * root.widgetScale

        Repeater {
            model: root.zones

            ColumnLayout {
                id: city

                required property string modelData
                readonly property var reading: TimeZones.at(modelData, Time.date, I18n.language, GlobalConfig.services.useTwelveHourClock)

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                spacing: 8 * root.widgetScale

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: WorldCities.nameFor(city.modelData)
                    color: surface.foreground
                    font: Tokens.font.title.builders.small.scale(root.widgetScale).build()
                    elide: Text.ElideRight
                }

                WorldClockFace {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Math.min(city.width, 164 * root.widgetScale)
                    Layout.preferredHeight: Layout.preferredWidth
                    reading: city.reading
                    style: Config.background.desktopWorldClock.style
                    showSeconds: Config.background.desktopWorldClock.showSeconds && !GameMode.enabled
                }

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    visible: root.zones.length > 1 && Config.background.desktopWorldClock.style !== "digital"
                    text: city.reading.time ?? "--:--"
                    color: surface.foreground
                    font: Tokens.font.body.builders.medium.weight(Font.DemiBold).scale(root.widgetScale).build()
                }

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: root.offsetText(city.reading)
                    color: surface.secondaryForeground
                    font: Tokens.font.label.builders.small.scale(root.widgetScale).build()
                    elide: Text.ElideRight
                }
            }
        }
    }
}
