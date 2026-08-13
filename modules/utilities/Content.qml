pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.components
import qs.modules.bar.popouts as BarPopouts

Item {
    id: root

    required property ShellScreen screen
    required property var props
    required property ScreenState screenState
    required property BarPopouts.Wrapper popouts
    required property matrix4x4 deformMatrix

    readonly property real nonAnimHeight: page.implicitHeight

    implicitWidth: page.implicitWidth
    implicitHeight: page.implicitHeight

    Loader {
        id: page

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        sourceComponent: root.props.controlCenterPage === "recorder" ? recorderPage : mainPage
    }

    Component {
        id: mainPage

        ControlCenter {
            screen: root.screen
            screenState: root.screenState
            popouts: root.popouts
            onOpenRecorder: root.props.controlCenterPage = "recorder"
        }
    }

    Component {
        id: recorderPage

        RecorderPage {
            props: root.props
            screenState: root.screenState
            onBack: root.props.controlCenterPage = "main"
        }
    }

    RecordingDeleteModal {
        props: root.props
        deformMatrix: root.deformMatrix
    }
}
