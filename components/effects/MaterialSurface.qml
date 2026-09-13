import QtQuick
import Quickshell
import qs.services

Item {
    id: root

    visible: false

    property Item target
    property bool active: true
    property Item registeredTarget
    property var registeredWindow

    readonly property var targetWindow: target ? target.QsWindow.window : null

    function syncRegistration(): void {
        if (registeredTarget && (!active || registeredTarget !== target || registeredWindow !== targetWindow)) {
            MaterialBlur.unregister(registeredTarget);
            registeredTarget = null;
            registeredWindow = null;
        }

        if (active && target && targetWindow && !registeredTarget) {
            MaterialBlur.register(target, targetWindow);
            registeredTarget = target;
            registeredWindow = targetWindow;
        }
    }

    onTargetChanged: syncRegistration()
    onTargetWindowChanged: syncRegistration()
    onActiveChanged: syncRegistration()

    Component.onCompleted: syncRegistration()
    Component.onDestruction: {
        if (registeredTarget)
            MaterialBlur.unregister(registeredTarget);
    }

    Connections {
        target: root.target
        ignoreUnknownSignals: true

        function onVisibleChanged(): void {
            MaterialBlur.notifyChanged();
        }
    }
}
