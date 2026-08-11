pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    required property var bar
    required property Brightness.Monitor monitor
    property color colour: Colours.palette.m3primary

    readonly property string windowTitle: {
        const title = Hypr.activeToplevel?.title;
        if (!title)
            return qsTr("Desktop");
        if (Config.bar.activeWindow.compact) {
            // " - " (standard hyphen), " — " (em dash), " – " (en dash)
            const parts = title.split(/\s+[\-\u2013\u2014]\s+/);
            if (parts.length > 1)
                return parts[parts.length - 1].trim();
        }
        return title;
    }

    readonly property int maxHeight: {
        const otherModules = bar.children.filter(c => c.entryId && c.item !== this && c.entryId !== "spacer");
        const otherHeight = otherModules.reduce((acc, curr) => acc + (curr.item.nonAnimHeight ?? curr.height), 0);
        // Length - 2 cause repeater counts as a child
        return bar.height - otherHeight - bar.spacing * (bar.children.length - 1) - bar.vPadding * 2;
    }
    readonly property real titleLineHeight: titleFontMetrics.height * 0.85
    readonly property int maxCharacters: Math.max(1, Math.floor((maxHeight - icon.implicitHeight - Tokens.spacing.small) / titleLineHeight))
    readonly property string verticalTitle: {
        const characters = Array.from(windowTitle);
        if (characters.length <= maxCharacters)
            return characters.join("\n");
        return [...characters.slice(0, Math.max(0, maxCharacters - 1)), "…"].join("\n");
    }
    property Title current: text1

    clip: true
    implicitWidth: Math.max(icon.implicitWidth, current.implicitWidth)
    implicitHeight: icon.implicitHeight + current.implicitHeight + current.anchors.topMargin

    onVerticalTitleChanged: {
        const next = current === text1 ? text2 : text1;
        next.text = verticalTitle;
        current = next;
    }

    Component.onCompleted: current.text = verticalTitle

    Loader {
        asynchronous: true
        anchors.fill: parent
        active: !Config.bar.activeWindow.showOnHover

        sourceComponent: MouseArea {
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onPositionChanged: {
                const popouts = root.bar.popouts;
                if (popouts.hasCurrent && popouts.currentName !== "activewindow")
                    popouts.hasCurrent = false;
            }
            onClicked: {
                const popouts = root.bar.popouts;
                if (popouts.hasCurrent) {
                    popouts.hasCurrent = false;
                } else {
                    popouts.currentName = "activewindow";
                    popouts.currentCenter = root.mapToItem(root.bar, 0, root.implicitHeight / 2).y;
                    popouts.hasCurrent = true;
                }
            }
        }
    }

    MaterialIcon {
        id: icon

        anchors.horizontalCenter: parent.horizontalCenter

        animate: true
        text: Icons.getAppCategoryIcon(Hypr.activeToplevel?.lastIpcObject.class, "desktop_windows")
        color: root.colour
    }

    Title {
        id: text1
    }

    Title {
        id: text2
    }

    FontMetrics {
        id: titleFontMetrics
        font: root.Tokens.font.body.builders.small.letterSpacing(1.4).build()
    }

    Behavior on implicitHeight {
        Anim {}
    }

    component Title: StyledText {
        id: text

        anchors.horizontalCenter: icon.horizontalCenter
        anchors.top: icon.bottom
        anchors.topMargin: Tokens.spacing.small

        font: titleFontMetrics.font
        color: root.colour
        opacity: root.current === this ? 1 : 0
        horizontalAlignment: Text.AlignHCenter
        lineHeight: root.titleLineHeight
        lineHeightMode: Text.FixedHeight

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
