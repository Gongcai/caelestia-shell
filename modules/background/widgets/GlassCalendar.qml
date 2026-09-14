pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    required property DesktopBackdrop desktopBackdrop
    required property Item motionItem
    required property real absX
    required property real absY
    property bool followingCurrentMonth: true
    property date browsedMonth: new Date()
    readonly property int todayYear: Time.date.getFullYear()
    readonly property int todayMonth: Time.date.getMonth()
    readonly property int todayDay: Time.date.getDate()
    readonly property var calendarLocale: Qt.locale(I18n.language)
    readonly property date displayedMonth: followingCurrentMonth ? new Date(todayYear, todayMonth, 1) : browsedMonth
    readonly property real widgetScale: Math.max(0.5, Math.min(2, Config.background.desktopCalendar.scale))

    function changeMonth(delta: int): void {
        const next = new Date(displayedMonth.getFullYear(), displayedMonth.getMonth() + delta, 1);
        if (next.getFullYear() < 1 || next.getFullYear() > 9999)
            return;
        browsedMonth = next;
        followingCurrentMonth = next.getFullYear() === todayYear && next.getMonth() === todayMonth;
    }

    function goToToday(): void {
        followingCurrentMonth = true;
    }

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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24 * root.widgetScale
        spacing: 8 * root.widgetScale

        RowLayout {
            Layout.fillWidth: true
            spacing: 2 * root.widgetScale

            Item {
                Layout.fillWidth: true
                implicitHeight: monthLabel.implicitHeight

                StyledText {
                    id: monthLabel

                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    text: root.displayedMonth.toLocaleDateString(root.calendarLocale, qsTr("MMM yyyy"))
                    color: surface.foreground
                    font: Tokens.font.title.builders.small.weight(Font.DemiBold).scale(root.widgetScale).build()
                    elide: Text.ElideRight
                }

                StateLayer {
                    objectName: "calendarToday"
                    radius: 6 * root.widgetScale
                    color: surface.foreground
                    Accessible.role: Accessible.Button
                    Accessible.name: qsTr("Go to today")
                    onClicked: root.goToToday()
                }
            }

            CalendarButton {
                objectName: "calendarPrevious"
                icon: "chevron_left"
                Accessible.name: qsTr("Previous month")
                onClicked: root.changeMonth(-1)
            }

            CalendarButton {
                objectName: "calendarNext"
                icon: "chevron_right"
                Accessible.name: qsTr("Next month")
                onClicked: root.changeMonth(1)
            }
        }

        DayOfWeekRow {
            Layout.fillWidth: true
            Layout.preferredHeight: 18 * root.widgetScale
            topPadding: 0
            bottomPadding: 0
            locale: grid.locale

            delegate: StyledText {
                required property var model

                horizontalAlignment: Text.AlignHCenter
                text: model.shortName
                color: surface.secondaryForeground
                font: Tokens.font.label.builders.small.scale(root.widgetScale).build()
            }
        }

        MonthGrid {
            id: grid

            Layout.fillWidth: true
            Layout.fillHeight: true
            month: root.displayedMonth.getMonth()
            year: root.displayedMonth.getFullYear()
            locale: root.calendarLocale
            spacing: 2 * root.widgetScale

            delegate: Item {
                id: day

                required property var model
                readonly property bool today: model.year === root.todayYear && model.month === root.todayMonth && model.day === root.todayDay

                implicitWidth: 26 * root.widgetScale
                implicitHeight: implicitWidth
                // Async loading can create cells after MonthGrid's sizing pass.
                width: Math.max(0, (grid.availableWidth - grid.spacing * 6) / 7)
                height: Math.max(0, (grid.availableHeight - grid.spacing * 5) / 6)

                Rectangle {
                    anchors.centerIn: parent
                    width: 26 * root.widgetScale
                    height: width
                    radius: width / 2
                    visible: day.today
                    color: surface.foreground
                }

                StyledText {
                    anchors.centerIn: parent
                    text: grid.locale.toString(day.model.day)
                    color: day.today ? surface.solidColor : surface.foreground
                    opacity: day.today || day.model.month === grid.month ? 1 : 0.25
                    font: Tokens.font.body.builders.small.weight(day.today ? Font.DemiBold : Font.Normal).scale(root.widgetScale).build()
                }
            }
        }
    }

    component CalendarButton: IconButton {
        implicitWidth: 26 * root.widgetScale
        implicitHeight: implicitWidth
        font: Tokens.font.icon.builders.small.scale(root.widgetScale).build()
        type: IconButton.Text
        isRound: true
        inactiveOnColour: surface.foreground
    }
}
