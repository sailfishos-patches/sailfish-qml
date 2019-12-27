import QtQuick 2.2
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import org.nemomobile.lipstick 0.1

Item {
    id: wallpaper

    property url source
    property HwcImage background
    property HwcImage _previousBackground
    property bool _transitionPending
    property url _emptyUrl
    property alias transformItem: rotationItem
    property bool isLegacyWallpaper: (background && background.width !== background.height)
                || (_previousBackground && _previousBackground.width !== _previousBackground.height)

    readonly property bool transitioning: backgroundTransition.running || _transitionPending

    property int maxTextureSize
    property size textureSize
    property string effect
    property color overlayColor

    property alias transitionPause: transitionPauseAnimation.duration

    default property alias _data: content.data

    signal backgroundLoaded()
    signal aboutToTransition()
    signal transitionComplete()
    signal rotationComplete()

    onSourceChanged: _reload()
    onEffectChanged: _reload()
    onOverlayColorChanged: _reload()

    function _reload() {
        _transitionPending = !!background
        if (!backgroundTransition.running) {
            // If anything that alters the visual appearance changes trigger a transition animation,
            // but only one.
            reload.requestStateUpdate()
        }
    }

    function _updateBackground() {
        var newBackground = background == background1 ? background0 : background1
        newBackground.source = source
        newBackground.effect = effect
        newBackground.overlayColor = overlayColor
        newBackground.maxTextureSize = maxTextureSize
        newBackground.textureSize = textureSize

        if (newBackground.status == Image.Null) {
            _backgroundStatusChanged(Image.Ready)
        } else if (background) {
            _transitionPending = true
        }
    }

    function _backgroundStatusChanged(status) {
        if ((status === Image.Ready || status == Image.Error)
                && (_transitionPending || !background)) {
            _previousBackground = background
            background = background == background1
                    ? background0
                    : background1

            // Break the binding so the next ambience change doesn't change the overlay color of
            // this background.
            background.overlayColor = background.overlayColor

            if (visible && _previousBackground) {
                backgroundTransition.restart()
            } else {
                background.opacity = 1.0
                if (_previousBackground) {
                    _resetPreviousBackground()
                }
                transitionComplete()
            }

            _transitionPending = false

            backgroundLoaded()

            if (!visible) {
                aboutToTransition()
            }

            if (status == Image.Error) {
                console.warn("Error loading ambience wallpaper", source)
                source = ""
            }
        }
    }

    function _resetPreviousBackground() {
        _previousBackground.source = ""
        _previousBackground.opacity = 0.0
        _previousBackground = null
    }

    ItemStateUpdateBatcher {
        id: reload

        onStateUpdate: {
            if (!backgroundTransition.running) {
                _updateBackground()
            }
        }
    }

    Item {
        id: rotationItem

        anchors.centerIn: parent

        rotation: wallpaper.isLegacyWallpaper ? 0 : Lipstick.compositor.topmostWindowAngle
        Behavior on rotation {
            SequentialAnimation {
                RotationAnimator {
                    direction: RotationAnimation.Shortest
                    duration: 200
                    easing.type: Easing.InOutQuad
                }
                ScriptAction {
                    script: wallpaper.rotationComplete()
                }
            }
        }

        HwcImage {
            id: background0
            anchors.centerIn: parent
            z: wallpaper.background == background0 ? 0 : -1
            opacity: 0

            onStatusChanged: wallpaper._backgroundStatusChanged(status)

            asynchronous: true

            pixelRatio: Theme.pixelRatio
            rotationHandler: rotationItem
        }

        HwcImage {
            id: background1

            anchors.centerIn: parent
            z: wallpaper.background == background1 ? 0 : -1
            opacity: 0

            onStatusChanged: wallpaper._backgroundStatusChanged(status)

            asynchronous: true

            pixelRatio: background0.pixelRatio
            rotationHandler: rotationItem
        }

        Item {
            id: content

            anchors.centerIn: parent

            width: rotationItem.rotation % 180 == 0
                        ? Lipstick.compositor.width
                        : Lipstick.compositor.height
            height: rotationItem.rotation % 180 == 0
                        ? Lipstick.compositor.height
                        : Lipstick.compositor.width
        }
    }

    SequentialAnimation {
        id: backgroundTransition

        PauseAnimation {
            id: transitionPauseAnimation
            duration: 0
        }
        ScriptAction {
            script: wallpaper.aboutToTransition()
        }
        FadeAnimator {
            target: wallpaper.background
            duration: 800
            from: 0.0
            to: 1.0
        }
        ScriptAction {
            script: {
                wallpaper._resetPreviousBackground()
                wallpaper.transitionComplete()
                if (_transitionPending) {
                    _updateBackground()
                }
            }
        }
    }
}
