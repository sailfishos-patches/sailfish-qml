/****************************************************************************
 **
 ** Copyright (C) 2015-2019 Jolla Ltd.
 ** Copyright (C) 2020 Open Mobile Platform LLC.
 **
 ****************************************************************************/

import QtQuick 2.2
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1
import com.jolla.lipstick 0.1
import "../notifications"

Layer {
    id: root

    property bool hasNotifications: notifications.hasNotifications
    // Lockscreen notifications when normal blanking policy and when notifications are not needed
    readonly property bool lockScreenAnimated: lipstickSettings.blankingPolicy === "default" || !Lipstick.compositor.lockScreenLayer.showNotifications
    property bool previewExpanded

    property bool lockScreenLocked

    property real _launcherPosition: Math.max(Lipstick.compositor.launcherLayer.exposure, Lipstick.compositor.topMenuLayer.exposure)
    Behavior on _launcherPosition {
        NumberAnimation { duration: 400; easing.type: Easing.OutQuad }
    }

    exposed: {
        if (!hasNotifications) {
            return false
        }
        return (Lipstick.compositor.lockScreenLayer.exposed || Lipstick.compositor.homeVisible || lipstickSettings.lowPowerMode)
    }

    opacity: _opacity
    Behavior on opacity {
        enabled: _opacityBehaviorEnabled
        FadeAnimation {
            // Use shorter fade duration when flicking from switcher
            // to events.
            duration: 200
        }
    }

    // Behaviors must be enabled or disabled before dependent values are modified

    property bool _opacityBehaviorEnabled: {
        if (state == "peeking_through_launcher" ||
            state == "switcher-menu" ||
            state == "peeking_at_switcher" ||
            state == "lockscreen_unanimated" ||
            state == "eventsview") {
            return false
        }
        return true
    }

    // Property values must be changed after Behaviors are enabled or disabled
    property string _state

    Component.onCompleted: stateChangedHandler.restart()
    onStateChanged: stateChangedHandler.restart()
    Timer {
        id: stateChangedHandler
        interval: 0
        onTriggered: _state = state
    }

    property real _opacity: {
        if (_state == "lockscreen_animated" ||
            _state == "lockscreen_unanimated") {
            return Lipstick.compositor.lockScreenLayer.notificationOpacity
        }
        if (_state == "peeking_through_launcher" ||
            _state == "switcher-menu" ||
            _state == "peeking_at_switcher") {
            return 1
        }
        return 0
    }

    property real _x: {
        // Reveal indicator width + padding.
        var margin = Theme.paddingMedium + notifications.width

        if (_state == "switcher-menu") {
            return -((1 - root._launcherPosition) * margin)
        }
        if (_state == "peeking_through_launcher" ||
            _state == "peeking_at_switcher" ||
            _state == "lockscreen_animated" ||
            _state == "lockscreen_unanimated") {
            return 0
        }

        return -margin
    }

    states: [
        State {
            name: "peeking_through_launcher"
            when: Lipstick.compositor.switcherLayer.isCurrentItem
                    && Lipstick.compositor.launcherLayer.exposed
                    && Lipstick.compositor.homePeeking
                    && !lipstickSettings.lockscreenVisible
        },
        State {
            name: "switcher-menu"
            when: Lipstick.compositor.switcherLayer.isCurrentItem
                    && (Lipstick.compositor.launcherLayer.exposed || Lipstick.compositor.topMenuLayer.exposed)
                    && !lipstickSettings.lockscreenVisible
        },
        State {
            name: "peeking_at_switcher"
            when: Lipstick.compositor.homeLayer.currentItem == Lipstick.compositor.switcherLayer
                  && ((Lipstick.compositor.peekingLayer.exposed && Lipstick.compositor.peekingAtHome && !lockScreenLocked)
                        || (Lipstick.compositor.launcherPeeking && !Lipstick.compositor.homeLayer.active && !lockScreenLocked))
        },
        State {
            // LockScreenLayer can be locked below the running application. Notification opacity and position
            // can be controlled by LockScreen.
            name: "lockscreen_animated"
            when: lockScreenLocked && lockScreenAnimated
        },
        State {
            name: "lockscreen_unanimated"
            when: lockScreenLocked && !lockScreenAnimated
        },
        State {
            name: "eventsview"
            when: Lipstick.compositor.homeLayer.currentItem === Lipstick.compositor.eventsLayer
        }
    ]

    SequentialAnimation {
        id: orientationChangedAnim
        PropertyAction {
            target: root
            property: "opacity"
            value: 0
        }
        SmoothedAnimation {
            target: root
            property: "opacity"
            from: 0
            to: 1
            duration: 400
            velocity: 1000 / duration
        }
    }

    Item {
        anchors.centerIn: parent
        rotation: Lipstick.compositor.topmostWindowAngle
        width: rotation % 180 == 0
                    ? Lipstick.compositor.width
                    : Lipstick.compositor.height
        height: rotation % 180 == 0
                    ? Lipstick.compositor.height
                    : Lipstick.compositor.width

        onRotationChanged: {
            if (root.state == "lockscreen") {
                orientationChangedAnim.start()
            }
        }

        opacity: Lipstick.compositor.systemInitComplete ? 1.0 : Theme.opacityHigh
        Behavior on opacity { FadeAnimation {} }

        NotificationColumn {
            id: notifications

            x: root._x

            anchors.verticalCenter: parent.verticalCenter
            showCount: Screen.sizeCategory >= Screen.Large || lockScreenLocked

            layer.enabled: lipstickSettings.lowPowerMode
            layer.effect: ShaderEffect {
                property color color: Theme.rgba(notifications.textColor, 1.0)
                fragmentShader: "
                    uniform sampler2D source;
                    uniform highp vec4 color;
                    uniform lowp float qt_Opacity;
                    varying highp vec2 qt_TexCoord0;
                    void main(void)
                    {
                        highp vec4 pixelColor = texture2D(source, qt_TexCoord0);
                        lowp float gray = dot(pixelColor.rgb, vec3(0.299, 0.587, 0.114));
                        gl_FragColor = vec4(color.rgb * gray, pixelColor.a) * qt_Opacity;
                    }
                    "
            }
        }
    }
}
