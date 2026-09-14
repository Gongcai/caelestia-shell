pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property DesktopBackdrop desktopBackdrop
    required property Item motionItem
    required property real absX
    required property real absY
    property var weather: Weather
    readonly property real widgetScale: Math.max(0.5, Math.min(2, Config.background.desktopWeather.scale))
    readonly property string layout: Config.background.desktopWeather.layout
    readonly property bool detailed: layout === "forecast"
    readonly property bool compact: layout !== "wide" && !detailed
    readonly property bool available: weather.cc !== null && weather.cc !== undefined
    readonly property var days: weather.forecast.slice(0, 5)
    readonly property var hours: weather.hourlyForecast.slice(0, 6)
    readonly property var today: days[0] ?? ({})
    readonly property real low: days.length ? Math.min(...days.map(day => day.minTempC)) : 0
    readonly property real high: days.length ? Math.max(...days.map(day => day.maxTempC)) : 1
    readonly property string condition: {
        const code = Number(weather.cc?.weatherCode);
        if (!available || !Number.isFinite(code))
            return qsTr("Weather unavailable");
        if (code <= 1)
            return qsTr("Clear");
        if (code === 2)
            return qsTr("Partly cloudy");
        if (code === 3)
            return qsTr("Overcast");
        if (code <= 48)
            return qsTr("Fog");
        if (code <= 57)
            return qsTr("Drizzle");
        if (code <= 67)
            return qsTr("Rain");
        if (code <= 77)
            return qsTr("Snow");
        if (code <= 82)
            return qsTr("Rain showers");
        if (code <= 86)
            return qsTr("Snow showers");
        return qsTr("Thunderstorm");
    }

    function temperature(value: var): string {
        if (!Number.isFinite(value))
            return "—";
        return Math.round(GlobalConfig.services.useFahrenheit ? value * 9 / 5 + 32 : value) + "°";
    }

    implicitWidth: (compact ? 280 : detailed ? 360 : 560) * widgetScale
    implicitHeight: (detailed ? 560 : 280) * widgetScale
    Component.onCompleted: {
        if (!available)
            weather.reload();
    }

    DesktopWidgetSurface {
        id: surface

        anchors.fill: parent
        desktopBackdrop: root.desktopBackdrop
        transformItem: root.motionItem
        sampleX: root.absX
        sampleY: root.absY
        radius: 44 * root.widgetScale
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24 * root.widgetScale
        spacing: (root.layout === "wide" ? 6 : 12) * root.widgetScale

        RowLayout {
            Layout.fillWidth: true
            spacing: 4 * root.widgetScale

            StyledText {
                Layout.fillWidth: true
                text: root.weather.city || qsTr("Weather")
                color: surface.foreground
                font: Tokens.font.title.builders.small.weight(Font.DemiBold).scale(root.widgetScale).build()
                elide: Text.ElideRight
            }

            DesktopWidgetButton {
                objectName: "weatherRefresh"
                implicitWidth: 24 * root.widgetScale
                foreground: surface.foreground
                widgetScale: root.widgetScale
                icon: "refresh"
                Accessible.name: qsTr("Refresh weather")
                onClicked: {
                    if (root.weather.loc)
                        root.weather.fetchWeatherData();
                    else
                        root.weather.reload();
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12 * root.widgetScale

            StyledText {
                Layout.fillWidth: true
                text: root.temperature(root.weather.cc?.tempC)
                color: surface.foreground
                font: Tokens.font.clock.size((root.layout === "wide" ? 48 : 60) * root.widgetScale).weight(Font.Light).build()
            }

            ColumnLayout {
                Layout.maximumWidth: root.compact ? 112 * root.widgetScale : 180 * root.widgetScale
                spacing: 2 * root.widgetScale

                MaterialIcon {
                    Layout.alignment: Qt.AlignRight
                    text: root.weather.icon
                    color: surface.foreground
                    fontStyle: Tokens.font.icon.size(34 * root.widgetScale).build()
                }

                StyledText {
                    Layout.alignment: Qt.AlignRight
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: root.condition
                    color: surface.foreground
                    font: Tokens.font.label.builders.medium.scale(root.widgetScale).build()
                    elide: Text.ElideRight
                }

                StyledText {
                    Layout.alignment: Qt.AlignRight
                    text: qsTr("H:%1  L:%2").arg(root.temperature(root.today.maxTempC)).arg(root.temperature(root.today.minTempC))
                    color: surface.secondaryForeground
                    font: Tokens.font.label.builders.small.scale(root.widgetScale).build()
                }
            }
        }

        Item {
            Layout.fillHeight: true
            visible: root.compact
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: root.compact
            spacing: 4 * root.widgetScale

            StyledText {
                text: qsTr("Feels like %1").arg(root.temperature(root.weather.cc?.feelsLikeC))
                color: surface.foreground
                font: Tokens.font.body.builders.small.scale(root.widgetScale).build()
            }

            StyledText {
                Layout.fillWidth: true
                text: root.available ? qsTr("Humidity %1% · Wind %2 km/h").arg(root.weather.humidity).arg(Math.round(root.weather.windSpeed)) : qsTr("Use the weather location in shell settings")
                color: surface.secondaryForeground
                font: Tokens.font.label.builders.small.scale(root.widgetScale).build()
                wrapMode: Text.Wrap
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            visible: !root.compact
            color: Qt.alpha(surface.foreground, 0.16)
        }

        RowLayout {
            objectName: "weatherHours"
            Layout.fillWidth: true
            visible: !root.compact
            spacing: 4 * root.widgetScale

            Repeater {
                model: root.hours

                ColumnLayout {
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.maximumWidth: Infinity
                    spacing: 4 * root.widgetScale

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: GlobalConfig.services.useTwelveHourClock ? (parent.modelData.hour % 12 || 12) + (parent.modelData.hour < 12 ? "a" : "p") : String(parent.modelData.hour).padStart(2, "0")
                        color: surface.secondaryForeground
                        font: Tokens.font.label.builders.small.scale(root.widgetScale).build()
                    }

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: parent.modelData.icon
                        color: surface.foreground
                        fontStyle: Tokens.font.icon.size(20 * root.widgetScale).build()
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.temperature(parent.modelData.tempC)
                        color: surface.foreground
                        font: Tokens.font.label.builders.small.scale(root.widgetScale).build()
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: !root.hours.length
                text: qsTr("Forecast unavailable")
                color: surface.secondaryForeground
                font: Tokens.font.body.builders.small.scale(root.widgetScale).build()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            visible: root.detailed
            color: Qt.alpha(surface.foreground, 0.16)
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.detailed
            spacing: 8 * root.widgetScale

            Repeater {
                model: root.days

                RowLayout {
                    id: forecastDay

                    required property int index
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8 * root.widgetScale

                    StyledText {
                        Layout.preferredWidth: 36 * root.widgetScale
                        text: forecastDay.index === 0 ? qsTr("Today") : new Date(forecastDay.modelData.date).toLocaleDateString(Qt.locale(I18n.language), "ddd")
                        color: surface.foreground
                        font: Tokens.font.label.builders.small.scale(root.widgetScale).build()
                    }

                    MaterialIcon {
                        text: forecastDay.modelData.icon
                        color: surface.foreground
                        fontStyle: Tokens.font.icon.size(22 * root.widgetScale).build()
                    }

                    StyledText {
                        Layout.preferredWidth: 28 * root.widgetScale
                        text: root.temperature(forecastDay.modelData.minTempC)
                        color: surface.secondaryForeground
                        font: Tokens.font.label.builders.small.scale(root.widgetScale).build()
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 4 * root.widgetScale
                        radius: height / 2
                        color: Qt.alpha(surface.foreground, 0.15)

                        Rectangle {
                            x: parent.width * (forecastDay.modelData.minTempC - root.low) / Math.max(1, root.high - root.low)
                            width: Math.max(3 * root.widgetScale, parent.width * (forecastDay.modelData.maxTempC - forecastDay.modelData.minTempC) / Math.max(1, root.high - root.low))
                            height: parent.height
                            radius: height / 2
                            color: Qt.alpha(surface.foreground, 0.7)
                        }
                    }

                    StyledText {
                        Layout.preferredWidth: 28 * root.widgetScale
                        horizontalAlignment: Text.AlignRight
                        text: root.temperature(forecastDay.modelData.maxTempC)
                        color: surface.foreground
                        font: Tokens.font.label.builders.small.scale(root.widgetScale).build()
                    }
                }
            }
        }
    }
}
