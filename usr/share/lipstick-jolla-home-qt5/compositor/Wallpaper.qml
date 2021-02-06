/*
 * Copyright (c) 2015 - 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.6
import QtQuick.Window 2.1 as QtQuick
import Sailfish.Ambience 1.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as Private
import org.nemomobile.lipstick 0.1
import "../backgrounds"

Item {
    id: wallpaperItem

    property alias ambience: ambience
    property alias homeWallpaperItem: homeLoader.item
    property alias applicationWallpaperItem: applicationLoader.item
    property alias applicationBackgroundOverlayImage: appBgOverlayImage.textureProvider
    property alias transformItem: ambienceInfo
    property alias dimmer: homeBackground
    readonly property bool exposed: homeLoader.item || homeLoader.replacedItem
    readonly property alias animating: homeLoader.animating

    signal transitionComplete()
    signal rotationComplete()

    Component.onCompleted: Ambience.create(Ambience.source)

    HomeBackground {
        id: homeBackground

        width: wallpaperItem.width
        height: wallpaperItem.height

        ApplicationWallpaperLoader {
            id: applicationLoader

            visible: false

            transitionEnabled: true
        }

        HomeWallpaperLoader {
            id: homeLoader

            visible: false
            transitionEnabled: true
            transitionDelay: wallpaperItem.visible ? 200 : 0

            onTransitionComplete: wallpaperItem.transitionComplete()
        }

        BackgroundTexture {
            id: appBgOverlayImage

            visible: false
        }


        AmbienceInfo {
            id: ambience

            url: Ambience.source
        }
    }

    Item {
        id: ambienceInfo

        anchors.centerIn: parent

        width: Screen.height
        height: Screen.height

        rotation: Lipstick.compositor.topmostWindowAngle

        Behavior on rotation {
            SequentialAnimation {
                RotationAnimator {
                    direction: RotationAnimation.Shortest
                    duration: 200
                    easing.type: Easing.InOutQuad
                }
                ScriptAction {
                    script: wallpaperItem.rotationComplete()
                }
            }
        }

        opacity: visible && homeLoader.animating && ambienceLabel.text !== "" ? 1.0 : 0.0
        Behavior on opacity { FadeAnimator { id: infoAnimation; duration: 300 } }

        Label {
            id: ambienceLabel
            anchors {
                left: parent.left
                leftMargin: Theme.horizontalPageMargin
                right: parent.right
                rightMargin: Theme.horizontalPageMargin
                bottom: parent.bottom
                bottomMargin: ambienceInfo.height / 8
            }
            color: ambience.highlightColor
            text: ambience.displayName
            font.pixelSize: Theme.fontSizeHuge
            font.family: Theme.fontFamilyHeading
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 5
            wrapMode: Text.Wrap
        }
    }
}
