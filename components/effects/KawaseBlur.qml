pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    required property Item source
    required property size textureSize
    property bool active: true
    property bool live: true
    readonly property Item texture: up1

    function levelSize(level: int): size {
        const divisor = Math.pow(2, level);
        return Qt.size(Math.max(1, Math.round(textureSize.width / divisor)), Math.max(1, Math.round(textureSize.height / divisor)));
    }

    BlurPass {
        id: down1

        input: root.source
        inputSize: root.textureSize
        textureSize: root.levelSize(1)
    }

    BlurPass {
        id: down2

        input: down1
        inputSize: down1.textureSize
        textureSize: root.levelSize(2)
    }

    BlurPass {
        id: down3

        input: down2
        inputSize: down2.textureSize
        textureSize: root.levelSize(3)
    }

    BlurPass {
        id: up3

        input: down3
        inputSize: down3.textureSize
        textureSize: root.levelSize(2)
        upsample: true
    }

    BlurPass {
        id: up2

        input: up3
        inputSize: up3.textureSize
        textureSize: root.levelSize(1)
        upsample: true
    }

    BlurPass {
        id: up1

        input: up2
        inputSize: up2.textureSize
        textureSize: root.textureSize
        upsample: true
    }

    component BlurPass: ShaderEffectSource {
        id: pass

        required property Item input
        required property size inputSize
        property bool upsample

        anchors.fill: parent
        visible: false
        sourceItem: root.active ? effect : null
        live: root.active && root.live
        hideSource: true
        smooth: true

        ShaderEffect {
            id: effect

            readonly property Item source: pass.input
            readonly property vector2d halfpixel: Qt.vector2d(0.5 / Math.max(1, pass.inputSize.width), 0.5 / Math.max(1, pass.inputSize.height))

            anchors.fill: parent
            visible: false
            fragmentShader: pass.upsample ? "qrc:/shaders/kawase_up.frag.qsb" : "qrc:/shaders/kawase_down.frag.qsb"
        }
    }
}
