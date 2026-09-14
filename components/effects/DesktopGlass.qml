pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Blobs // qmllint disable unused-imports

// Material adapted from jaxparrow07/liquidglass-kde-widgets (GPL-3.0).
// The Blobs import registers the compiled shader resource collection.
// The host owns the shared wallpaper capture; this item only crops and blurs
// its own region. Affine sampling includes the host's drag and scale animation.
Item {
    id: root

    required property Item sourceItem
    required property Item transformItem
    property Item sourceTexture
    property int sourceRevision
    property real sampleX
    property real sampleY
    property real pixelRatio: 1
    property bool live
    property bool glassEnabled: true
    property bool blur: true
    property real radius: 56
    property real roundness: 5.5
    property real refraction: 1
    property color tint: "#20242a"
    property color solidColor: tint
    property real tintOpacity: 0.3
    property bool completed
    property bool refreshing
    property real hoverAmount: hover.hovered ? 1 : 0

    readonly property bool sampling: glassEnabled && sourceTexture !== null && sourceItem !== null && sourceItem.width > 0 && sourceItem.height > 0 && width > 0 && height > 0
    readonly property bool updateTextures: sampling && visible && (live || refreshing)
    readonly property size textureSize: Qt.size(Math.max(1, Math.round(width * pixelRatio)), Math.max(1, Math.round(height * pixelRatio)))
    readonly property var samplePoints: {
        sampleX;
        sampleY;
        if (!sourceItem || !transformItem)
            return [Qt.point(0, 0), Qt.point(1, 0), Qt.point(0, 1)];
        transformItem.x;
        transformItem.y;
        transformItem.width;
        transformItem.height;
        transformItem.scale;
        transformItem.rotation;
        sourceItem.width;
        sourceItem.height;
        return [mapToItem(sourceItem, 0, 0), mapToItem(sourceItem, width, 0), mapToItem(sourceItem, 0, height)];
    }
    readonly property vector2d uvOffset: Qt.vector2d(samplePoints[0].x / Math.max(1, sourceItem?.width ?? 1), samplePoints[0].y / Math.max(1, sourceItem?.height ?? 1))
    readonly property vector2d uvAxisX: Qt.vector2d((samplePoints[1].x - samplePoints[0].x) / Math.max(1, sourceItem?.width ?? 1), (samplePoints[1].y - samplePoints[0].y) / Math.max(1, sourceItem?.height ?? 1))
    readonly property vector2d uvAxisY: Qt.vector2d((samplePoints[2].x - samplePoints[0].x) / Math.max(1, sourceItem?.width ?? 1), (samplePoints[2].y - samplePoints[0].y) / Math.max(1, sourceItem?.height ?? 1))

    function refresh(): void {
        if (!completed)
            return;
        refreshing = true;
        settleTimer.restart();
    }

    onUvOffsetChanged: refresh()
    onUvAxisXChanged: refresh()
    onUvAxisYChanged: refresh()
    onTextureSizeChanged: refresh()
    onSourceRevisionChanged: refresh()
    onSourceTextureChanged: refresh()
    onSamplingChanged: refresh()
    onBlurChanged: refresh()
    onLiveChanged: refresh()
    onVisibleChanged: refresh()
    Component.onCompleted: {
        completed = true;
        refresh();
    }

    Timer {
        id: settleTimer

        interval: 350
        onTriggered: root.refreshing = false
    }

    HoverHandler {
        id: hover
    }

    ShaderEffect {
        id: crop

        readonly property Item source: root.sourceTexture
        readonly property vector2d uvOffset: root.uvOffset
        readonly property vector2d uvAxisX: root.uvAxisX
        readonly property vector2d uvAxisY: root.uvAxisY

        anchors.fill: parent
        visible: false
        fragmentShader: "qrc:/shaders/desktopglasscrop.frag.qsb"
    }

    ShaderEffectSource {
        id: croppedTexture

        anchors.fill: parent
        visible: false
        sourceItem: root.sampling ? crop : null
        textureSize: root.textureSize
        live: root.updateTextures
        hideSource: true
        smooth: true
    }

    KawaseBlur {
        id: frosted

        anchors.fill: parent
        source: croppedTexture
        textureSize: root.textureSize
        active: root.sampling && root.blur
        live: root.updateTextures
    }

    ShaderEffect {
        id: glassShader

        readonly property Item backdrop: root.blur ? frosted.texture : croppedTexture
        readonly property size size: Qt.size(root.width, root.height)
        readonly property real radius: root.radius
        readonly property real roundness: root.roundness
        readonly property real refractThickness: Math.min(root.width, root.height) * 0.11
        readonly property real refractIOR: 1.5
        readonly property real refractScale: 32 * Math.min(root.width, root.height) / 256 * Math.max(0, Math.min(2, root.refraction))
        readonly property real chromaStrength: 0.1 * Math.max(0, Math.min(2, root.refraction))
        readonly property vector4d tint: Qt.vector4d(root.tint.r, root.tint.g, root.tint.b, Math.max(0, Math.min(1, root.tintOpacity)))
        readonly property vector4d tintBottom: Qt.vector4d(0, 0, 0, 0)
        readonly property vector2d uvOffset: Qt.vector2d(0, 0)
        readonly property vector2d uvScale: Qt.vector2d(1, 1)
        readonly property vector2d mousePos: hover.hovered ? Qt.vector2d(hover.point.position.x / Math.max(1, root.width), hover.point.position.y / Math.max(1, root.height)) : Qt.vector2d(-1, -1)
        readonly property real mouseFade: root.hoverAmount
        readonly property real specStrength: 0.55
        readonly property vector4d overlayDarken: Qt.vector4d(0, 0, 0, 0)

        anchors.fill: parent
        visible: root.sampling
        fragmentShader: "qrc:/shaders/desktopglass.frag.qsb"
    }

    Rectangle {
        anchors.fill: parent
        visible: !root.sampling || glassShader.status === ShaderEffect.Error
        color: root.solidColor
        radius: root.radius
    }

    Behavior on hoverAmount {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutQuad
        }
    }
}
