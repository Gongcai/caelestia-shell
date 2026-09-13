pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Blobs

ShaderEffect {
    id: root

    required property Item sourceItem
    required property Item transformItem
    property real radius: 24
    property real refraction: 22
    property color tint: Qt.rgba(0.1, 0.1, 0.1, 0.14)

    readonly property vector2d panelSize: Qt.vector2d(width, height)
    readonly property vector2d sourceSize: Qt.vector2d(Math.max(1, sourceItem.width), Math.max(1, sourceItem.height))
    // mapToItem does not notify when an ancestor transforms during lock/unlock.
    readonly property var samplePoints: {
        transformItem.x; transformItem.y;
        transformItem.width; transformItem.height;
        transformItem.rotation; transformItem.scale;
        sourceItem.width; sourceItem.height;
        return [mapToItem(sourceItem, 0, 0), mapToItem(sourceItem, width, 0), mapToItem(sourceItem, 0, height)];
    }
    readonly property vector2d sampleOrigin: Qt.vector2d(samplePoints[0].x / sourceSize.x, samplePoints[0].y / sourceSize.y)
    readonly property vector2d sampleAxisX: Qt.vector2d((samplePoints[1].x - samplePoints[0].x) / sourceSize.x, (samplePoints[1].y - samplePoints[0].y) / sourceSize.y)
    readonly property vector2d sampleAxisY: Qt.vector2d((samplePoints[2].x - samplePoints[0].x) / sourceSize.x, (samplePoints[2].y - samplePoints[0].y) / sourceSize.y)
    readonly property var source: ShaderEffectSource {
        sourceItem: root.sourceItem
        live: root.visible
        visible: false
    }

    fragmentShader: "qrc:/shaders/backdropglass.frag.qsb"
}
